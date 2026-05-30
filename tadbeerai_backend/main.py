import json
import os
import time
from contextlib import asynccontextmanager

from apscheduler.schedulers.background import BackgroundScheduler
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agents.action_generator import generate_actions
from agents.content_ingestor import ingest_content
from agents.impact_analyzer import analyze_impact
from agents.insight_extractor import extract_insight
from agents.relevance_filter import score_and_filter
from agents.rss_watcher import fetch_all_feeds
from agents.simulation_agent import simulate_action
from core.llm_client import get_ai_provider, normalize_confidence
from core.paths import get_data_dir
from core.schemas import (
    AnalyseRequest,
    SimulateRequest,
    RegisterUserRequest,
    UpdateUserRequest,
    FcmTokenRequest,
)
from core.trace_builder import (
    append_simulation_trace,
    build_analyse_trace,
    build_feed_trace,
)
from core.firestore_client import init_firestore, get_firestore_client
from core.user_registry import get_user_registry
from core.notification_service import get_notification_service

load_dotenv()

DATA_DIR = get_data_dir()
FEED_CACHE = os.path.join(DATA_DIR, "feed_cache.json")
TRACE_LOG = os.path.join(DATA_DIR, "trace_log.json")
POLL_MINUTES = int(os.getenv("POLL_INTERVAL_MINUTES", "15"))

_feed_trace: list[dict] = []
_trace_payload: dict = {"agent_trace": []}

scheduler = BackgroundScheduler()


def refresh_feed() -> list[dict]:
    """Runs Agent 0 + 1 and caches filtered feed."""
    global _feed_trace
    print("[Scheduler] Refreshing RSS feed...")
    os.makedirs(DATA_DIR, exist_ok=True)
    raw = fetch_all_feeds()

    # Load and merge mock news from mock_db/news_feed.json
    try:
        from email.utils import parsedate_to_datetime
        from datetime import datetime
        mock_feed_path = os.path.join(os.path.dirname(__file__), "mock_db", "news_feed.json")
        if os.path.exists(mock_feed_path):
            with open(mock_feed_path, "r", encoding="utf-8") as f:
                mock_data = json.load(f)
                mock_news = mock_data.get("news", [])
                
                formatted_mock_news = []
                for item in mock_news:
                    pub_str = item.get("published", "")
                    try:
                        pub_iso = parsedate_to_datetime(pub_str).isoformat()
                    except Exception:
                        pub_iso = datetime.now().isoformat()
                        
                    formatted_mock_news.append({
                        "id": str(item.get("id")),
                        "title": item.get("title", ""),
                        "url": item.get("link", ""),
                        "source": item.get("source", ""),
                        "preview_text": item.get("summary", "")[:200],
                        "published_at": pub_iso,
                        "image_url": item.get("image_url"),
                        "raw_text": item.get("summary", "") + " " + item.get("title", ""),
                    })
                
                seen_urls = {item["url"] for item in raw}
                merged_count = 0
                for item in formatted_mock_news:
                    if item["url"] not in seen_urls:
                        raw.append(item)
                        seen_urls.add(item["url"])
                        merged_count += 1
                print(f"[Scheduler] Merged {merged_count} articles from news_feed.json")
    except Exception as e:
        print(f"[Scheduler] Failed to load/merge mock news_feed.json: {e}")

    filtered = score_and_filter(raw)
    top_domain = filtered[0]["domain"] if filtered else "none"
    _feed_trace = build_feed_trace(len(raw), len(filtered), top_domain)

    with open(FEED_CACHE, "w") as f:
        json.dump(filtered, f, default=str)

    print(f"[Scheduler] Feed refreshed: {len(filtered)} items")
    return filtered


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize Firestore on startup
    try:
        init_firestore()
        print("[Startup] [OK] Firestore initialized")
    except Exception as e:
        print(f"[Startup] [WARN] Firestore initialization warning: {e}")

    # Reset MockDatabase on startup (Agent Rule 5)
    try:
        from core.mock_db import MockDatabase
        MockDatabase().reset()
        print("[Startup] [OK] MockDatabase reset to default")
    except Exception as e:
        print(f"[Startup] [WARN] MockDatabase reset warning: {e}")
    
    scheduler.add_job(refresh_feed, "interval", minutes=POLL_MINUTES)
    scheduler.start()
    try:
        refresh_feed()
    except Exception as e:
        print(f"[Startup] Feed refresh failed: {e}")
    yield
    scheduler.shutdown(wait=False)


app = FastAPI(title="TadbeerAI API", version="2.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== CORE ENDPOINTS ====================


@app.get("/")
def root():
    return {
        "app": "TadbeerAI",
        "team": "TADBEERAI",
        "hackathon": "AISeekho2026",
        "version": "2.0.0",
        "endpoints": [
            "/feed", "/analyse", "/simulate", "/trace", "/health",
            "/register", "/users", "/notifications",
        ],
    }


@app.get("/health")
def health():
    firestore = get_firestore_client()
    registry = get_user_registry()
    user_count = len(registry.get_all_users())
    return {
        "status": "ok",
        "team": "TADBEERAI",
        "challenge": "1",
        "ai_provider": get_ai_provider(),
        "firestore": "✅ Connected" if firestore.available else "⚠️ Fallback (Mock)",
        "registered_users": user_count,
    }


@app.get("/feed")
def get_feed(refresh: bool = False):
    """GET /feed — ranked Pakistan business news for Flutter FeedScreen."""
    cache_exists = os.path.exists(FEED_CACHE)
    should_refresh = refresh or not cache_exists

    if cache_exists and not should_refresh:
        # Check file age to auto-expire cache after 10 minutes (600 seconds)
        mtime = os.path.getmtime(FEED_CACHE)
        age_seconds = time.time() - mtime
        if age_seconds > 600:
            should_refresh = True
            print(f"[Feed] Cache is {int(age_seconds)}s old (>600s). Triggering auto-refresh.")

    if not should_refresh:
        try:
            with open(FEED_CACHE) as f:
                items = json.load(f)
            if items:
                print(f"[Feed] Returning {len(items)} cached items")
                return items
        except Exception as e:
            print(f"[Feed] Cache read error, will refresh: {e}")

    print("[Feed] Refreshing and scoring feed...")
    return refresh_feed()


def _run_analyse(request: AnalyseRequest) -> dict:
    global _trace_payload, _feed_trace
    timings: dict[str, float] = {}

    t0 = time.time()
    ingested = ingest_content(
        text=request.text,
        source_url=request.source_url,
        language=request.language,
    )
    timings["ingest"] = time.time() - t0

    detect_text = request.text or ingested["normalized_text"]
    temp_articles = score_and_filter([{
        "title": detect_text[:100],
        "raw_text": ingested["normalized_text"],
        "id": "temp",
        "url": request.source_url or "",
        "source": "",
        "published_at": "",
        "preview_text": "",
    }])
    domain = temp_articles[0]["domain"] if temp_articles else "Finance"

    t0 = time.time()
    insight = extract_insight(ingested, domain)
    timings["insight"] = time.time() - t0

    t0 = time.time()
    impacts = analyze_impact(insight, domain, ingested["entities"])
    timings["impact"] = time.time() - t0

    t0 = time.time()
    actions = generate_actions(insight, impacts, domain)
    timings["actions"] = time.time() - t0

    agent_trace = build_analyse_trace(
        ingested, domain, insight, impacts, actions, timings, feed_trace=_feed_trace
    )

    _trace_payload = {
        "insight": insight,
        "impacts": impacts,
        "actions": actions,
        "domain": domain,
        "agent_trace": agent_trace,
    }
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(TRACE_LOG, "w") as f:
        json.dump(_trace_payload, f, default=str)

    return {
        "insight": insight.get("insight_title", ""),
        "insight_detail": insight.get("insight_detail", ""),
        "confidence": normalize_confidence(insight.get("confidence", 0.75)),
        "confidence_reason": insight.get("confidence_reason", ""),
        "tags": insight.get("tags", [domain]),
        "impacts": impacts,
        "actions": actions,
        "agent_trace": agent_trace,
        "domain": domain,
    }


@app.post("/analyse")
@app.post("/analyze")
def analyse(request: AnalyseRequest):
    """POST /analyse — Agents 2→5 pipeline for Flutter InsightScreen."""
    if not request.text and not request.source_url:
        raise HTTPException(status_code=400, detail="No text or source_url provided")
    try:
        return _run_analyse(request)
    except ValueError as e:
        # User-facing errors from URL scraping (bad URL, empty content, etc.)
        print(f"[Analyse] URL error: {e}")
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        print(f"[Analyse] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/simulate")
@app.post("/execute")
def simulate(request: SimulateRequest):
    """POST /simulate — Agent 6 real execution for Flutter BeforeAfterScreen."""
    try:
        with open(TRACE_LOG) as f:
            trace_data = json.load(f)
    except Exception:
        trace_data = {
            "insight": {
                "insight_title": "Business development detected",
                "insight_detail": "",
            },
            "actions": [{
                "rank": 1,
                "title": "Review situation",
                "detail": "Monitor development",
                "business_math": "",
                "churn_risk": "",
                "urgency": "medium",
                "timeline": "This week"
            }],
            "domain": "Finance",
            "agent_trace": _feed_trace,
        }

    all_actions = trace_data.get("actions", [])
    idx = min(max(0, request.action_index), len(all_actions) - 1) if all_actions else 0
    ordered_actions = (
        [all_actions[idx]] + [a for i, a in enumerate(all_actions) if i != idx]
        if all_actions
        else []
    )

    result = simulate_action(
        actions=ordered_actions,
        domain=trace_data.get("domain", "Finance"),
        insight=trace_data.get("insight", {}),
        user_id=request.user_id,
        notify_channels=request.notify_channels,
    )

    agent_trace = append_simulation_trace(
        trace_data.get("agent_trace", _feed_trace),
        result,
    )
    trace_data["agent_trace"] = agent_trace
    trace_data["simulation"] = result
    with open(TRACE_LOG, "w") as f:
        json.dump(trace_data, f, default=str)

    return result


@app.get("/trace")
def get_trace():
    """GET /trace — Flutter expects top-level List[AgentStep]."""
    try:
        with open(TRACE_LOG) as f:
            data = json.load(f)
        return data.get("agent_trace", [])
    except FileNotFoundError:
        return _feed_trace if _feed_trace else []


# ==================== STATE MANAGEMENT ENDPOINTS ====================


@app.get("/state")
def get_state():
    """GET /state — Get the current business state including FBR and SBR tax rates."""
    try:
        firestore = get_firestore_client()
        state = firestore.get_business_state()
        return state
    except Exception as e:
        print(f"[State] Error fetching state: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/state")
def update_state(updates: dict):
    """POST /state — Update the business state directly (e.g. adjust FBR/SBR tax rates)."""
    try:
        firestore = get_firestore_client()
        success, err = firestore.update_business_state(updates)
        if err:
            raise HTTPException(status_code=400, detail=err)
        return {"status": "success", "state": firestore.get_business_state()}
    except Exception as e:
        print(f"[State] Error updating state: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== USER REGISTRATION ENDPOINTS ====================


@app.post("/register")
def register_user(request: RegisterUserRequest):
    """POST /register — Register a user for notification alerts. All fields optional for guest mode."""
    try:
        registry = get_user_registry()
        user = registry.register_user(
            name=request.name or "Guest",
            phone=request.phone or "",
            email=request.email or "",
            notify_sms=request.notify_sms,
            notify_email=request.notify_email,
            notify_push=request.notify_push,
            fcm_token=request.fcm_token or "",
            domains=request.domains,
        )
        is_guest = not request.phone and not request.email
        mode = "guest" if is_guest else "registered"
        print(f"[Register] [OK] User {mode}: {user.get('user_id')} ({request.name or 'Guest'})")
        return {"status": mode, "user": user}
    except Exception as e:
        print(f"[Register] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/users/fcm-token")
def update_fcm_token(request: FcmTokenRequest):
    """POST /users/fcm-token — Update user's FCM push token."""
    try:
        registry = get_user_registry()
        user = registry.update_user(request.user_id, {"fcm_token": request.fcm_token})
        print(f"[FCM Token] [OK] Updated FCM token for user: {request.user_id}")
        return {"status": "updated", "user": user}
    except Exception as e:
        print(f"[FCM Token] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/users")
def list_users():
    """GET /users — List all registered users."""
    try:
        registry = get_user_registry()
        users = registry.get_all_users()
        return {"count": len(users), "users": users}
    except Exception as e:
        print(f"[Users] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/users/{user_id}")
def get_user(user_id: str):
    """GET /users/{user_id} — Get a single user."""
    try:
        registry = get_user_registry()
        user = registry.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail=f"User {user_id} not found")
        return user
    except HTTPException:
        raise
    except Exception as e:
        print(f"[Users] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/users/{user_id}")
def update_user(user_id: str, request: UpdateUserRequest):
    """PUT /users/{user_id} — Update user notification preferences."""
    try:
        registry = get_user_registry()
        updates = request.model_dump(exclude_none=True)
        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")
        user = registry.update_user(user_id, updates)
        print(f"[Users] [OK] Updated user: {user_id}")
        return {"status": "updated", "user": user}
    except HTTPException:
        raise
    except Exception as e:
        print(f"[Users] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/users/{user_id}")
def delete_user(user_id: str):
    """DELETE /users/{user_id} — Unregister a user."""
    try:
        registry = get_user_registry()
        deleted = registry.delete_user(user_id)
        if not deleted:
            raise HTTPException(status_code=404, detail=f"User {user_id} not found")
        print(f"[Users] [OK] Deleted user: {user_id}")
        return {"status": "deleted", "user_id": user_id}
    except HTTPException:
        raise
    except Exception as e:
        print(f"[Users] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== NOTIFICATION HISTORY ====================


@app.get("/notifications")
def get_notifications(limit: int = 50):
    """GET /notifications — Get notification history log."""
    try:
        svc = get_notification_service()
        history = svc.get_notification_history(limit=limit)
        return {"count": len(history), "notifications": history}
    except Exception as e:
        print(f"[Notifications] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", "8000")), reload=True)

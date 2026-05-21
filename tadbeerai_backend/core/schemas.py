from typing import Optional

from pydantic import BaseModel


class AnalyseRequest(BaseModel):
    text: Optional[str] = None
    source_url: Optional[str] = None
    language: str = "en"


class SimulateRequest(BaseModel):
    action_index: int = 0
    insight_id: Optional[str] = None
    scenario: Optional[str] = None
    user_id: Optional[str] = None
    notify_channels: Optional[list[str]] = None


class RegisterUserRequest(BaseModel):
    """Register a user for notification alerts. All fields optional for guest mode."""
    name: Optional[str] = "Guest"
    phone: Optional[str] = ""       # e.g. "+923001234567"
    email: Optional[str] = ""       # e.g. "user@gmail.com"
    notify_sms: bool = True
    notify_email: bool = True
    notify_push: bool = True
    fcm_token: Optional[str] = None
    domains: list[str] = ["all"]


class UpdateUserRequest(BaseModel):
    """Update user notification preferences."""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    notify_sms: Optional[bool] = None
    notify_email: Optional[bool] = None
    notify_push: Optional[bool] = None
    fcm_token: Optional[str] = None
    domains: Optional[list[str]] = None


class FcmTokenRequest(BaseModel):
    """FCM token registration/sync request."""
    user_id: str
    fcm_token: str

// lib/core/constants/constants.dart
// All app-wide constants — change API base URL here when AI Engineer deploys

class TConst {
  // ── API ──────────────────────────────────
  // AI Engineer: update this when backend is deployed
  static const apiBase = 'https://tadbeerai-496809.uc.r.appspot.com';
  // Local dev Android emulator:  'http://10.0.2.2:8000'
  // Local dev physical device:   'http://192.168.x.x:8000'
  static const apiTimeout = 30; // seconds

  // ── RSS FEEDS ────────────────────────────
  static const rssFeeds = [
    'https://www.dawn.com/feeds/home',
    'https://arynews.tv/feed/',
    'https://www.thenews.com.pk/rss/1/1',
    'https://www.geo.tv/rss/1',
    'https://www.brecorder.com/feed',
  ];

  // ── DOMAINS ──────────────────────────────
  static const businessDomains = [
    'Energy',
    'Currency',
    'Logistics',
    'Finance',
    'Policy',
    'Trade',
    'Supply Chain',
  ];

  // ── LANGUAGES ────────────────────────────
  static const languages = {
    'en': 'English',
    'ur': 'اردو',
    'roman_ur': 'Roman Urdu',
  };

  // ── APP STRINGS ──────────────────────────
  static const appName = 'TadbeerAI';
  static const appTagline = 'Content to Action Intelligence';
  static const teamName = 'TADBEERAI';
  static const hackathon = 'AISeekho2026';
  static const challenge = 'Challenge 1: Autonomous Content-to-Action Agent';
}

# HiFi 2.3.2

HiFi v2.3.2 delivers the new Cached songs auto-playlist on Android, a redesigned Home app bar with liquid-glass filter chips, live stream badges, login WebView ANR fixes, and YouTube Dislike support in Now Playing.

### 🚀 Highlights:
- **Cached Auto-Playlist (Android):** Browse all fully cached songs that are not yet downloaded directly from a dedicated 2x2 Library grid card, complete with a quick *Remove from cache* action.
- **Home App Bar Redesign:** Replaced the top bar with a clean row featuring the avatar menu, liquid-glass filter chips, a collapsing Mood chip, and a direct Listen Together button.
- **Live Stream Indicators:** Added a clear `LIVE` badge on song rows, quick picks, and search suggestions, while disabling offline download actions for live streams.
- **Login WebView Stability:** Initialized the login WebView off the main thread to prevent ANRs, deferred cookie clearing until ready, and added a Retry option if the renderer process terminates.
- **Now Playing & Community:** Added YouTube Dislike integration to the Now Playing sheet, improved Radio/Mix playback labels, fixed third-party libraries ProGuard rules, and added the official Discord community link in Credits.

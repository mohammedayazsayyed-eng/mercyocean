<div align="center">

<img src="assets/images/logo.png" alt="MercyOcean Logo" width="120" height="120" />

# MercyOcean

### A comprehensive Islamic companion app built with Flutter

</div>

---

## Overview

MercyOcean is a Flutter-based Islamic mobile app designed to serve as an all-in-one spiritual companion. It integrates live content from a WordPress backend and the UmmahAPI to deliver Quran recitation, daily duas, Dalail al-Khayrat, Salah guides, Hijri calendar, and more — all in a clean, elegant interface with full dark mode support.

---

## Features

### 📖 Quran
- Complete Quran with Arabic text and English translation
- Surah list with search
- In-app audio recitation (Mishary Alafasy)
- Sajdah verse indicators
- Persistent caching for offline-fast access

### 🤲 Duas
- Categorized collection of authentic duas from UmmahAPI
- Arabic text with English transliteration and translation
- Parallel fetch across all categories for fast loading
- Persistent cache — instant load after first fetch

### 📿 Tasbih Counter
- Tap-to-count dhikr counter with haptic feedback
- Set a target with a live progress ring
- Save counts with custom names
- Resume from a saved count at any time
- Rename and delete saved counts
- Persists across app restarts

### 🌙 Dalail al-Khayrat
- Full Dalail al-Khayrat reading divided by day
- Includes Asma an-Nabi and Asma ul-Husna sections
- EN / AR toggle — switch between English transliteration and Arabic text
- Content served live from WordPress

### 🕌 Salah Guide
- Step-by-step guide for all five daily prayers
- Covers Adhan, Fajr, Zuhr, Asr, Maghrib, Isha
- Pre-Fajr (Qiyam al-Layl) included

### 📅 Hijri Calendar
- Live Hijri date from device timezone
- All 12 Islamic months displayed
- Monthly Awrad — spiritual duties and duas for each month
- Content served live from WordPress

### 📚 Library
- Downloadable Islamic books (PDF)
- Audio content streaming

### 🎨 Design
- Gold, parchment, and deep navy design system
- Full dark and light mode
- Custom bottom navigation
- Arabic typography using alKitab font

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x / Dart 3.x |
| State Management | StatefulWidget + ValueNotifier |
| HTTP Client | Dio 5.x (single shared instance per API) |
| Content Backend | WordPress REST API (self-hosted) |
| Islamic Data API | UmmahAPI (Quran + Duas) |
| HTML Rendering | flutter_html |
| Local Storage | SharedPreferences |
| Quran Audio | UmmahAPI audio endpoint |
| PDF Viewer | Syncfusion Flutter PDF Viewer |
| Hijri Date | hijri package |
| Fonts | Poppins, Nunito, alKitab (Arabic) |

---

## Architecture

```
lib/
├── config/
│   └── app_theme.dart          # Colors, gradients, shadows, typography
├── models/
│   ├── quran_model.dart
│   ├── dua_model.dart
│   ├── wordpress_post_model.dart
│   └── wordpress_media_model.dart
├── service/
│   ├── api_service.dart        # All API calls with memory + persistent cache
│   └── api_constant.dart       # Base URLs and API keys
└── pages/
    ├── quran/                  # Surah list + detail + audio
    ├── duas/                   # Duas list + detail sheet
    ├── salat/                  # Per-prayer guides
    ├── dalail/                 # Dalail al-Khayrat sections
    ├── tasbih_page.dart        # Dhikr counter
    ├── monthly_awrad_page.dart # Hijri calendar + monthly content
    └── dalail_khairat_page.dart
```

---

## Caching Strategy

MercyOcean uses a two-layer caching system for fast loads:

```
Request
  ↓
Memory Cache (instant, resets on app kill)
  ↓ miss
SharedPreferences Cache (< 100ms, survives restarts, 24h TTL)
  ↓ miss or expired
API Fetch → stored in both caches
```

Quran and Duas are pre-fetched silently on app launch so they are ready before the user navigates to them.

---

## Getting Started

### Prerequisites
- Flutter 3.x SDK
- Dart 3.x
- Android Studio or VS Code
- A running WordPress instance with WP REST API enabled
- UmmahAPI key from [ummahapi.com](https://ummahapi.com)

### Installation

```bash
git clone https://github.com/yourusername/mercyocean.git
cd mercyocean
flutter pub get
```

### Configuration

Update `lib/service/api_constant.dart` with your credentials:

```dart
class ApiConstant {
  static String baseApiURL = "https://your-wordpress-site.com/wp-json/wp/v2";
  static String ummahApiBaseURL = "https://ummahapi.com/api";
  static String ummahApiKey = "your_api_key_here";
}
```

### Run

```bash
flutter run
```

---

## WordPress Backend Setup

MercyOcean fetches content pages via the WordPress REST API. Each content page (Salah guides, Dalail sections, Monthly Awrad) is a WordPress page with a unique slug.

**Arabic content** uses the CSS class `arabic-content` on right-aligned paragraphs:

```html
<p class="has-text-align-right arabic-content">بِسْمِ اللَّهِ...</p>
```

**English transliteration** uses plain paragraphs above each Arabic block.

The app's EN/AR toggle filters these blocks client-side using regex before passing to `flutter_html`.

---

## Dependencies

```yaml
dependencies:
  dio: ^5.x
  flutter_html: ^3.0.0-beta.2
  shared_preferences: ^2.2.2
  syncfusion_flutter_pdfviewer: ^x.x.x
  hijri: ^x.x.x
  path_provider: ^2.x
```

---

## Roadmap

- [ ] Prayer times with location-based Adhan alerts
- [ ] Qibla direction compass
- [ ] 99 Names of Allah (Asma ul-Husna) with meanings
- [ ] Offline Quran download
- [ ] Bookmark verses and duas
- [ ] Multi-language support (Urdu, Arabic UI)
- [ ] Google Play Store release

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

Built with ❤️ for the Ummah

</div>

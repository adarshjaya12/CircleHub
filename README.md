# CircleHub — Device App

Flutter application for the CircleHub smart display.  
Runs on a Raspberry Pi Zero 2W with a circular 1080×1080 MIPI display via **flutter-pi** (DRM/KMS, no X11).

---

## Hardware

| Component | Detail |
|---|---|
| SBC | Raspberry Pi Zero 2W |
| Display | Circular 1080×1080 MIPI panel |
| OS | balenaOS (Docker-based fleet management) |
| Extras | Mechanical bell alarm via GPIO |

**Safe-zone radius:** All UI is constrained to 85% of the 540 px logical radius to avoid clipping at the circle edge.

---

## Architecture

```
lib/
├── main.dart                  Entry point
├── app.dart                   MaterialApp — starts at SplashScreen
├── core/
│   ├── constants.dart         CircleHub.radius, colours, defaultCity
│   ├── device_service.dart    Device identity, JWT lifecycle, API helpers
│   └── theme.dart             Dark theme
├── hub/
│   └── hub_page.dart          Root PageView (swipe between features)
├── widgets/
│   ├── circular_scaffold.dart Clips content to circle
│   ├── weather_icon.dart      OWM condition-code → icon widget
│   └── page_indicator.dart    (unused — dots were removed)
└── features/
    ├── splash/
    │   ├── splash_screen.dart  5.6 s animated intro (glow arc + wordmark)
    │   └── pairing_screen.dart First-boot screen — shows device ID for pairing
    ├── clock/
    │   ├── clock_page.dart     Swipeable clock faces
    │   ├── clock_painter.dart  Shared analogue painter
    │   └── faces/              10 clock faces (classic, bold, minimal, retro…)
    ├── weather/
    │   ├── weather_service.dart  Calls CircleHub API proxy (no OWM key on device)
    │   ├── weather_models.dart   WeatherData, HourlyPoint, ForecastDay
    │   └── weather_page.dart     3 swipeable weather cards
    ├── calendar/
    │   ├── calendar_page.dart    Vertical-swipe between Day / Week / Month
    │   ├── calendar_provider.dart
    │   └── views/               day_view, week_view, month_view
    ├── news/
    │   ├── news_service.dart
    │   └── news_page.dart
    ├── gallery/
    │   └── gallery_page.dart   Auto-cycling photo slideshow (signed Supabase URLs)
    └── alarm/
        ├── alarm_page.dart
        └── alarm_provider.dart
```

---

## Pages (swipe left/right on the display)

| # | Page | Description |
|---|---|---|
| 1 | Weather | 3 sub-pages: card view, visual/graph, forecast |
| 2 | Clock | 10 swipeable faces |
| 3 | Calendar | Day → Week → Month (swipe up/down) |
| 4 | News | Headline ticker |
| 5 | Gallery | Auto-cycling slideshow, 30 s interval, tap to advance |
| 6 | Alarm | Mechanical bell scheduler |

---

## First-Boot Flow

1. Splash animation plays (5.6 s)
2. If **no JWT stored** → `PairingScreen` shows the device ID (`ch-…`)
3. User enters the ID in the companion app to claim the device
4. Tap anywhere on the pairing screen to proceed to the main display
5. On subsequent boots → splash goes directly to `HubPage`

---

## API Integration

All external data goes through the **CircleHub API** — no keys are stored on the device.

| Data | Endpoint | Auth |
|---|---|---|
| City / location | `GET /api/location` | Device JWT |
| Weather | `GET /api/weather/current\|forecast` | Device JWT |
| Gallery photos | `GET /api/gallery/photos` | Device JWT (returns 1-hr signed Supabase URLs) |
| Device register | `POST /api/devices/register` | None (first boot) |

`DeviceService` (`lib/core/device_service.dart`) manages:
- Generating a stable device ID (`ch-{hex timestamp}`) on first run
- POSTing to `/api/devices/register` to obtain a 10-year JWT
- Caching the JWT in `SharedPreferences`
- Helper methods: `fetchLocation()`, `fetchGalleryPhotos()`

---

## Running Locally (emulator / Wear OS)

```bash
# Copy and fill in secrets
cp local.env.example local.env   # edit CIRCLEHUB_API_BASE etc.

# Run (injects secrets at compile time)
bash run.sh

# With device selector
bash run.sh -d emulator-5554 --no-dds
```

`local.env` is gitignored. Never commit it.

### `local.env` keys

| Key | Description |
|---|---|
| `CIRCLEHUB_API_BASE` | API URL (default `http://10.0.2.2:5150` for Android emulator) |
| `OPENWEATHER_KEY` | OWM key — used only during offline dev if API is unreachable |
| `NEWSAPI_KEY` | NewsAPI key |

---

## Deploying to Pi (balenaOS)

```bash
balena push <fleet-name>
```

Set `CIRCLEHUB_API_BASE` as a balena fleet environment variable pointing to your deployed API.

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `cached_network_image` | Gallery photo caching |
| `shared_preferences` | JWT + device ID persistence |
| `http` | API calls |
| `google_fonts` | Outfit font (splash, pairing screen) |
| `table_calendar` | Calendar feature |

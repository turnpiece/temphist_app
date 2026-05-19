# TempHist

A Flutter app that visualises historical average temperatures using interactive charts. Supports daily, weekly, monthly, and yearly views with location-aware data.

## Features

- **Temperature history charts** — bar chart showing the same date/week/month/year across all recorded years, coloured warm/cool by Z-score (climate-stripes style)
- **Four time-period views** — Day, Week, Month, Year, swipeable
- **Average & trend lines** — historical mean and long-term temperature trend with error margin
- **Stats bubble** — standard deviation and trend rate displayed below the chart
- **Location search** — search any city in the world by name
- **Automatic location detection** — uses GPS when permission is granted; falls back to a picker if not
- **Visited & popular locations** — quick access to places you've been and an API-driven global list
- **Recent selections** — quick access to locations you've recently selected
- **°C / °F toggle** — US locations default to Fahrenheit
- **Social sharing** — shareable snapshot links with Open Graph previews

## Getting Started

### Prerequisites

- Flutter SDK ([installation guide](https://docs.flutter.dev/get-started/install))
- Xcode (for iOS builds)
- A Firebase project

### Installation

```bash
git clone https://github.com/turnpiece/temphist_app.git
cd temphist_app
flutter pub get
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Add your iOS app to the project
3. Download `GoogleService-Info.plist` and place it in `ios/Runner/`
4. Generate the Flutter config:

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

Template files are provided for reference:

- `lib/firebase_options.template.dart`
- `ios/Runner/GoogleService-Info.template.plist`

The actual config files are gitignored.

### Run

```bash
flutter run
```

## Debug Logging

Use `DebugUtils` for logging — calls are no-ops in release builds:

```dart
DebugUtils.logLazy(() => 'message');
```

## Scripts

```bash
./scripts/create_release.sh patch    # Bump version, tag, and push (see Releasing below)
./scripts/simulator_screenshots.sh   # Set simulator status bar to clean screenshot state
./scripts/record_preview.sh          # Record an App Store–ready App Preview from the Simulator
./scripts/regenerate_certificates.sh # Nuke and regenerate iOS certificates via fastlane match
```

## Releasing

### 1. Merge to main

```bash
git checkout main
git merge develop
git push origin main
```

### 2. Create a release

```bash
./scripts/create_release.sh patch    # 1.0.0 → 1.0.1
./scripts/create_release.sh minor    # 1.0.0 → 1.1.0
./scripts/create_release.sh major    # 1.0.0 → 2.0.0
./scripts/create_release.sh custom 1.2.3
```

The script bumps the version in `pubspec.yaml`, increments the build number, creates a git tag, and pushes.

### 3. iOS TestFlight

Push to `main` triggers the GitHub Actions workflow (`.github/workflows/ios.yml`), which builds and uploads to TestFlight via Fastlane.

### Version numbering

Follows [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

## License

MIT

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

To run with a specific API, such as the local one, use:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Debug Logging

Use `DebugUtils` for logging — calls are no-ops in release builds:

```dart
DebugUtils.logLazy(() => 'message');
```

## Scripts

```bash
./scripts/create_release.sh bump patch   # Bump the version on a branch (see Releasing below)
./scripts/create_release.sh tag          # Tag the merged release on main (see Releasing below)
./scripts/simulator_screenshots.sh   # Set simulator status bar to clean screenshot state
./scripts/record_preview.sh          # Record an App Store–ready App Preview from the Simulator
./scripts/regenerate_certificates.sh # Nuke and regenerate iOS certificates via fastlane match
```

## Releasing

A release is two steps, so the version bump can go through a pull request.

### 1. Bump the version on a branch

```bash
git switch -c release/1.4.0
./scripts/create_release.sh bump patch    # 1.0.0 → 1.0.1
./scripts/create_release.sh bump minor    # 1.0.0 → 1.1.0
./scripts/create_release.sh bump major    # 1.0.0 → 2.0.0
./scripts/create_release.sh bump custom 1.2.3
```

`bump` refuses to run on `main` or with uncommitted changes. It runs the tests and analyzer, sets the new version and a timestamp build number in `pubspec.yaml`, and commits. It does not push or tag.

### 2. Merge to main

Push the branch, open a pull request into `main` and merge it.

### 3. Tag the release

```bash
git switch main && git pull
./scripts/create_release.sh tag
```

`tag` must run on `main`, in sync with `origin/main`. It reads the version from `pubspec.yaml`, asks for confirmation, then creates an annotated `v<version>` tag on the merged commit and pushes the tag. It refuses if the tag already exists, and warns if `develop` has commits that are not on `main`.

### 4. iOS TestFlight

Every push to `main` (including merging a pull request) triggers the GitHub Actions workflow (`.github/workflows/ios.yml`), which builds and uploads to TestFlight via Fastlane. Fastlane sets the iOS build number from a UTC timestamp at build time. The tag does not trigger the workflow.

### Version numbering

Follows [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

## License

MIT

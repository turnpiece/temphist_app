# TempHist

A Flutter app that visualises historical average temperatures using interactive charts. Supports daily, weekly, monthly, and yearly views with location-aware data.

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

## Build Configuration

The app uses a layered config system in `lib/config/`:

| File | Purpose |
| ---- | ------- |
| `build_config.dart` | Detects debug vs release build |
| `debug_config.dart` | Debug-specific settings |
| `production_config.dart` | Production settings |
| `app_config.dart` | Unified interface used throughout the app |

Use `AppConfig` in code rather than checking `kDebugMode` directly:

```dart
if (AppConfig.isDebugMode) { ... }
if (AppConfig.shouldShowDebugFeatures) { ... }
```

Use `DebugUtils` for logging (no-ops in production):

```dart
DebugUtils.logLazy(() => 'message');
```

## Scripts

```bash
./scripts/switch_to_debug.sh       # Enable debug mode
./scripts/switch_to_production.sh  # Enable production mode
./scripts/check_mode.sh            # Show current mode
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

# TempHist Flutter App

TempHist is a simple Flutter application that visualizes historical average temperatures by year using a horizontal bar chart. It is built using the [graphic](https://pub.dev/packages/graphic) package.

## Features

- Displays average temperature data per year as a horizontal bar chart
- Years are listed on the vertical axis (CategoryAxis)
- Bar length corresponds to temperature value
- Shows average temperature summary text
- Fully responsive and mobile-friendly

## Getting Started

### Prerequisites

- Flutter SDK installed ([installation guide](https://docs.flutter.dev/get-started/install))
- An IDE such as VS Code or Android Studio

### Installation

1. Clone the repository:

```bash
git clone https://github.com/turnpiece/TempHistApp.git
cd TempHistApp
```

2. Get the dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

> You can also open it in your IDE and run from there.

## Dependencies

- [graphic](https://pub.dev/packages/graphic)

## Screenshots

_Add screenshots of the chart here once available._

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

For more info or to contribute, please open an issue or submit a pull request at [github.com/turnpiece/TempHistApp](https://github.com/turnpiece/TempHistApp).

## Firebase Configuration Setup

This project uses Firebase for backend services. To set up the Firebase configuration:

1. Create a new Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Add your app to the Firebase project for each platform you want to support (iOS, Android, Web)
3. Download the configuration files:

   - For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For Web: The configuration will be included in the Flutter Firebase options

4. Generate the Flutter Firebase configuration:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```
   This will create the `lib/firebase_options.dart` file.

Note: The actual configuration files (`GoogleService-Info.plist` and `firebase_options.dart`) are gitignored for security reasons. Template files are provided as examples:

- `lib/firebase_options.template.dart`
- `ios/Runner/GoogleService-Info.template.plist`

Replace the placeholder values in these templates with your actual Firebase configuration values.

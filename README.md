# DrillCalc Field

Mobile-first Flutter MVP for drilling well-control calculations converted from the source spreadsheets in the parent folder.

## Current MVP

- Kill mud weight, formation pressure, ICP, FCP, and pressure schedule.
- MAASP and kick tolerance envelope.
- Influx height, gradient, density, and basic kick classification.
- Volumetric-method pressure window and bleed-volume guidance.
- Shared Dart calculation engine with unit tests.

## Run

```sh
flutter test
flutter analyze
flutter run
```

For web preview:

```sh
flutter build web
python3 -m http.server 8080 --directory build/web
```

## Native Build Prerequisites

Android builds require a configured Java Runtime plus Android command-line tools.

iOS builds require a full Xcode installation and CocoaPods.

## Cloud Builds

GitHub Actions builds the app without local Android Studio or Xcode installs:

- Android debug APK artifact: `drillcalc-android-debug-apk`
- iOS simulator app artifact: `drillcalc-ios-simulator-app`

Run the workflow from the Actions tab or push to `main`.

## Safety

This is an engineering draft. Verify every formula and workflow against approved company procedures before field use.

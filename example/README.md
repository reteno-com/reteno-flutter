# reteno_plugin_example

Demonstrates how to use the reteno_plugin plugin.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS TestFlight (Fastlane)

1. Install Fastlane (example for macOS):
   ```bash
   brew install fastlane
   ```
2. Go to `ios` directory.
3. Copy env template:
   ```bash
   cp fastlane/.env.testflight.example fastlane/.env.testflight
   ```
4. Fill `fastlane/.env.testflight` with real credentials/secrets.
5. Run lane:
   ```bash
   fastlane ios testflight --env testflight
   ```

The lane will:
- sync signing via `match` (`appstore`),
- build `Runner.ipa`,
- upload it to TestFlight.

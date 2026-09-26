# Mentra X Joby

## Requirements

- A Mac
- Xcode 15 or later
- XcodeGen (`brew install xcodegen`)
- An iPhone
- Mentra Live glasses running software 3.1.1
- An Apple Developer account

This app is iPhone only. Future voice input will use the glasses microphone over the Bluetooth link (`useGlassesMic: true`). This version does not record audio.

Glasses below software 3.1.1 are a known risk. The SDK pinned here is 3.1.1 and only works with glasses software 3.1.1. Updating the glasses once with Mentra's Starter Kit app is buggy, so confirm the glasses actually reached 3.1.1 before relying on this app. If they are still below 3.1.1, the connection and the spoken welcome may fail.

## Build

```bash
brew install xcodegen
cd ios
xcodegen
open MentraJoby.xcodeproj
```

## Run on a device

Copy `ios/Config/Signing.local.xcconfig.example` to `ios/Config/Signing.local.xcconfig`. Set `DEVELOPMENT_TEAM` to your Apple Team ID. To use a bundle id other than `com.andrewcortado.mentrajoby`, set `PRODUCT_BUNDLE_IDENTIFIER` in that same file.

Open the project, select your iPhone as the run destination, and press Run. Signing is automatic. Certificates and profiles stay in your keychain and Apple account. `Signing.local.xcconfig` is gitignored. Do not commit a Team ID, certificate, or provisioning profile.

## Pair the glasses

- Update the glasses to 3.1.1 once with Mentra's Starter Kit app. That update is buggy. Check the version on the glasses afterward. Glasses that are still below 3.1.1 are a known risk with this app.
- In the app, tap Scan and pick your Mentra Live.
- In iOS Settings → Bluetooth, connect Mentra Live so the welcome plays from the glasses. iOS does not let the app choose the audio output. If Mentra Live is not the Bluetooth output when the glasses are ready, the app shows "select Mentra Live in Settings → Bluetooth" and waits to speak until that route is selected.

## Produce a TestFlight build

- Bump `CURRENT_PROJECT_VERSION` in `ios/project.yml`, then run `xcodegen` again from `ios/`.
- In Xcode: Product → Archive → Distribute App → App Store Connect → Upload.
- Answer export compliance.
- Add testers in TestFlight.

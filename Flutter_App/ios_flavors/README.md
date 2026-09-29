# iOS flavor templates

Create shared Xcode schemes named `development`, `staging`, and `production`. Each scheme should map Debug/Profile/Release configurations to the matching flavor and use the supplied xcconfig values. Bundle identifiers:

- development: `com.chatcart.app.dev`
- staging: `com.chatcart.app.stg`
- production: `com.chatcart.app`

Run with `flutter run --flavor development`, `flutter run --flavor staging`, or `flutter run --flavor production`. See `Documentation/FLUTTER_FLAVORS.md` in the release root for the full setup.

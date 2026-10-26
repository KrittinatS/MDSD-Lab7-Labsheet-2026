# campus_marketplace_w7

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running with Gemini

Provide a Gemini API key at run time; do not add it to source code or commit it:

```powershell
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

The key is embedded in client builds, so restrict it in Google AI Studio and
avoid using an unrestricted key in a distributed app.

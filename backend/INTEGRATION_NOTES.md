# Flutter integration — additive files only

These two files are **new**. Nothing in your existing UI is modified.

## 1. Copy into your project

    MedTraceAI/lib/services/api_service.dart
    MedTraceAI/lib/models/med_document.dart

## 2. Add dependencies (pubspec.yaml)

Your project currently has no networking or file-picking packages.

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^8.2.1
  http: ^1.2.2          # <-- add
  file_picker: ^8.1.6   # <-- add
```

Then:

```bat
flutter pub get
```

## 3. Run with the backend URL

```bat
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

| Target | URL |
|--------|-----|
| Flutter web / Windows | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Physical device | `http://<your-PC-IP>:8000` |

For Flutter web, the port Chrome picks must be in the backend's `CORS_ORIGINS`.
Pin it so it does not change every run:

```bat
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:8000
```

`http://localhost:8080` is already in `.env.example`.

## 4. Smoke test before touching any UI

Drop this anywhere temporarily and call it from `initState`:

```dart
final api = ApiService();
debugPrint('backend healthy: ${await api.isHealthy()}');
debugPrint('documents: ${(await api.listDocuments()).length}');
```

Expect `backend healthy: true`. If it prints `false`, the UI wiring will not
work either — fix the connection first.

## 5. Why `toCardMap()` exists

`app_screen.dart` renders `_documents` as `List<Map<String, dynamic>>` with keys
`name, type, color, size, time, status, metrics`. `MedDocument.toCardMap()`
returns that exact shape, so the card widget needs no changes — only the source
of the list changes from hardcoded to API.

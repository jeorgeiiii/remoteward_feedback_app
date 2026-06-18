# Remote Ward — Feedback Collector

A Flutter application for a device owner to authenticate with Google, collect
structured user feedback (user details, bug description, and media), persist it
locally in SQLite, and securely export everything to **CSV or PDF** in the
device's **Downloads** folder behind a biometric / device-credential gate.

Built with **BLoC** state management, **get_it** dependency injection, a
dedicated **sqflite** database service layer, and Android **MediaStore** scoped
storage.

---

## Features

| Requirement | Implemented with |
|---|---|
| Google Sign-In via Firebase | `firebase_auth` + `google_sign_in` 7.x |
| BLoC architecture | `flutter_bloc` — three feature BLoCs |
| Local SQL persistence | `sqflite` behind a dedicated `DatabaseService` |
| Dependency injection | `get_it` service locator |
| Scoped storage (Downloads) | Android MediaStore via `media_store_plus` |
| Biometric-gated export | `local_auth` (fingerprint / PIN / pattern / password) |
| CSV export | `csv` package, required column format |
| PDF export | `pdf` + `printing`, **with images embedded** |
| Media capture | `image_picker` (images + video) |

---

## App flow

```
Google Login ──► User Details ──► Bug Description ──► Media ──► Thank You
                      ▲                                              │
                      └────────────── auto-return ───────────────────┘

User Details ──(toolbar icon)──► Export & Account
                                   └─ device auth → CSV / PDF → Downloads
```

Five required screens plus an owner-only Export dashboard reachable from the
User Details toolbar. After each submission the Thank You screen automatically
returns to User Details for the next entry.

---

## Architecture (BLoC)

The app uses a layered architecture. The UI never touches the database or any
service directly — actions flow **down** through the layers as events, and data
flows **back up** as immutable state.

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION                                                 │
│  Screens (login, user details, bug, media, thank you, export)│
│  Widgets (buttons, fields, progress, animations)             │
└───────────────┬──────────────────────────────▲──────────────┘
        events  │ (e.g. FeedbackSubmitted)      │ state (e.g. success)
┌───────────────▼──────────────────────────────┴──────────────┐
│  BLoC                                                         │
│  AuthBloc   ·   FeedbackBloc   ·   ExportBloc                 │
└───────────────┬──────────────────────────────▲──────────────┘
          calls │                               │ results
┌───────────────▼──────────────────────────────┴──────────────┐
│  DATA — Repositories (coordinators)                          │
│  AuthRepository   ·   FeedbackRepository                     │
└───────────────┬──────────────────────────────▲──────────────┘
          calls │                               │ results
┌───────────────▼──────────────────────────────┴──────────────┐
│  DATA — Services & datasource (workers)                      │
│  DatabaseService (sqflite)  ·  MediaStorageService           │
│  CsvExportService  ·  PdfExportService                       │
│  BiometricService  ·  DeviceInfoService  ·  (Firebase)       │
└──────────────────────────────────────────────────────────────┘
```

All dependencies are registered once at startup in `injection_container.dart`
and resolved through `getIt<T>()`, so no class constructs its own
collaborators.

### The three BLoCs

**AuthBloc** — owns authentication and drives top-level routing.
- Events: `AuthStarted`, `AuthGoogleSignInRequested`, `AuthSignOutRequested`
- State: `AuthState { status: unknown | authenticated | unauthenticated, user }`
- It subscribes to Firebase's auth stream; the root widget switches on `status`,
  so navigation to/from login is a pure function of auth state.

**FeedbackBloc** — assembles one feedback record across the three input screens.
- Events: `FeedbackStarted`, `UserDetailsSubmitted`, `BugDetailsSubmitted`,
  `MediaAdded`, `MediaRemoved`, `FeedbackSubmitted`, `FeedbackReset`
- State: `FeedbackState { draft: FeedbackEntry, status: idle | submitting | success | failure }`
- The draft lives in the BLoC, so it survives back-navigation and resets cleanly
  for the next entry. `FeedbackSubmitted` persists it via the repository.

**ExportBloc** — runs the secure export sequence.
- Events: `ExportRequested(format: csv | pdf)`, `ExportCountRefreshed`
- State: `ExportState { status: idle | authenticating | exporting | success | failure | authFailed | lockNotSet, entryCount, savedPath, pdfBytes }`
- Sequence: count check → device-credential gate → build CSV/PDF → write to
  Downloads. The UI mirrors each status.

### Data flow examples

Submitting feedback:
```
Media screen → FeedbackSubmitted → FeedbackBloc → FeedbackRepository
  → MediaStorageService (copy image to app storage)
  → DeviceInfoService (device model + OS)
  → DatabaseService.insertFeedback()  → SQLite row
```

Exporting:
```
Export screen → ExportRequested(pdf) → ExportBloc
  → BiometricService.authenticate()   (fingerprint / PIN)
  → FeedbackRepository.exportToPdf()
      → DatabaseService.getAllFeedback()
      → PdfExportService.buildPdf()    (embeds images)
      → MediaStorageService.saveBytes()  → Downloads/FeedbackCollector/*.pdf
```

---

## Project structure

```
lib/
├── main.dart                 # bootstrap: Firebase + DI, then runApp
├── app.dart                  # providers + auth-driven root gate
├── injection_container.dart  # get_it registrations
├── core/
│   ├── constants/            # db name, route names, CSV headers
│   ├── theme/                # colours + Material 3 theme
│   └── utils/                # shared page transition
├── data/
│   ├── models/               # FeedbackEntry, AppUser (+ (de)serialization)
│   ├── datasources/          # DatabaseService  (sqflite — the DB layer)
│   ├── repositories/         # AuthRepository, FeedbackRepository
│   └── services/             # biometric, csv, pdf, media-store, device-info
└── presentation/
    ├── bloc/                 # auth / feedback / export BLoCs
    ├── screens/              # the 5 screens + export dashboard
    └── widgets/              # reusable animated UI pieces
test/
└── feedback_bloc_test.dart   # sample BLoC unit tests
```

---

## Tech stack

`flutter_bloc` · `get_it` · `equatable` · `firebase_core` · `firebase_auth` ·
`google_sign_in` (7.x) · `local_auth` · `sqflite` · `image_picker` ·
`media_store_plus` · `csv` · `pdf` · `printing` · `device_info_plus` ·
`permission_handler`

Minimum: Flutter 3.29 / Dart 3.7 (required by `google_sign_in` 7.x).
Minimum Android: API 24 (Android 7.0).

---

## Setup

> Firebase config files are **not** committed (they hold project keys). Add your
> own before running.

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Firebase
1. Create a Firebase project and enable **Authentication → Google**.
2. Configure with the CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
3. In `lib/main.dart`, use the generated options:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
4. In `lib/data/repositories/auth_repository.dart`, set `serverClientId` in
   `initialize()` to your project's **Web** OAuth client ID.
5. Add your debug + release **SHA-1 / SHA-256** fingerprints in the Firebase
   console, or Google Sign-In will fail at runtime.

### 3. Biometric auth
`MainActivity` extends `FlutterFragmentActivity` (required by `local_auth`):
```kotlin
// android/app/src/main/kotlin/com/example/feedback_app/MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity : FlutterFragmentActivity()
```

### 4. Run
```bash
flutter run
flutter test          # runs the sample BLoC tests
```

---

## Export output

Files are written to **`Downloads/FeedbackCollector/`**.

CSV columns (assignment format):

| Device Owner | User Details | Bug/Issue | User Device | Description and Media Links |
|---|---|---|---|---|

The PDF export renders the same fields per entry and **embeds attached images**
directly in the document, then opens an on-screen preview.

---

## Notes & known areas to verify on-device

- **Biometric/PIN gate** — uses `biometricOnly: false`, so it accepts a
  fingerprint *or* the device PIN/pattern/password. The device must have a
  screen lock enrolled; otherwise the app shows a "set up a screen lock" prompt.
- **`media_store_plus`** — the `saveFile` API differs slightly across versions;
  this is the most likely spot to need a minor adjustment. The logic is isolated
  in `MediaStorageService`.
- **Google Sign-In** requires correct SHA fingerprints + `serverClientId`; most
  sign-in failures trace back to those.
- **Media permissions** (`READ_MEDIA_IMAGES/VIDEO`) apply on Android 13+;
  `image_picker` requests them.

See `DESIGN_DOC.md` for the reasoning behind these design choices, challenges
faced, and possible improvements.

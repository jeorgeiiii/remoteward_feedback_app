# Feedback Collector

A Flutter app for a device owner to authenticate with Google, collect structured
user feedback (details, bug description, media), persist it locally in SQLite,
and securely export everything to a CSV in the device's **Downloads** folder
behind a biometric gate.

Built with **BLoC** state management, **get_it** dependency injection, a
dedicated **sqflite** database service layer, and Android **MediaStore**
scoped storage.

---

## App flow

```
Google Login ──► User Details ──► Bug Description ──► Media ──► Thank You
                      ▲                                              │
                      └──────────── auto-redirect ───────────────────┘

User Details ──(toolbar)──► Export & Account  (biometric-gated CSV export)
```

The five required screens plus an owner-only Export dashboard reachable from the
User Details toolbar.

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
│   └── services/             # biometric, csv, media-store, device-info
└── presentation/
    ├── bloc/                 # auth / feedback / export BLoCs
    ├── screens/              # the 5 screens + export dashboard
    └── widgets/              # reusable animated UI pieces
test/
└── feedback_bloc_test.dart   # sample BLoC unit tests
```

---

## Setup

> The repo ships the Dart source. Generate the platform folders and add your own
> Firebase config before running.

### 1. Generate platform scaffolding
```bash
flutter create .
flutter pub get
```
Then copy the permission block from the provided
`android/app/src/main/AndroidManifest.xml` into the generated manifest.

### 2. Firebase
1. Create a Firebase project and enable **Authentication → Google**.
2. Install the CLI and configure:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and adds `google-services.json`.
3. In `lib/main.dart`, switch to:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
4. In `lib/data/repositories/auth_repository.dart`, set `serverClientId` in
   `initialize()` to your project's **Web** OAuth client ID (from the Firebase
   console / `google-services.json`). On Android this is required for the
   returned `idToken` to be accepted by Firebase.
5. Add your debug + release **SHA-1/SHA-256** fingerprints in the Firebase
   console, or Google Sign-In will fail at runtime.

### 3. Biometric auth (`local_auth`)
`MainActivity` must extend `FlutterFragmentActivity` (not `FlutterActivity`):
```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity : FlutterFragmentActivity()
```

### 4. Run
```bash
flutter run
flutter test      # runs the sample BLoC tests
```

Minimum: Flutter 3.29 / Dart 3.7 (required by `google_sign_in` 7.x).

---

## CSV output

Saved to `Downloads/FeedbackCollector/feedback_export_<timestamp>.csv` with the
required columns:

| Device Owner | User Details | Bug/Issue | User Device | Description and Media Links |
|---|---|---|---|---|

---

## Known areas to verify on-device

- **`media_store_plus`** — the `saveFile` API differs slightly across versions;
  this is the most likely spot to need a minor adjustment for your pinned
  version. The logic is isolated in `MediaStorageService` so it's a one-file fix.
- **Google Sign-In** requires correct SHA fingerprints + `serverClientId`; most
  "sign-in returns null/throws" issues trace back to those.
- Granular media permissions (`READ_MEDIA_IMAGES/VIDEO`) apply on Android 13+;
  `image_picker` requests them, but verify on your target API level.

See `DESIGN_DOC.md` for the reasoning behind these choices.

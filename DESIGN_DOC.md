# Design Document — Feedback Collector

This accompanies the source code submission. It explains the design choices,
the challenges involved, and what I would improve with more time.

## 1. Design choices

### Architecture: layered BLoC + repositories + DI
The app is split into three layers — `presentation` (widgets + BLoCs),
`data` (models, the sqflite datasource, repositories, services), and a small
`core` (theme, constants, transitions). Widgets never touch services directly;
they dispatch events to BLoCs, BLoCs call repositories, and repositories
orchestrate the low-level services. This keeps business logic out of the UI and
makes each piece independently testable.

`get_it` wires everything in `injection_container.dart`. Services and the
`AuthRepository`/`FeedbackRepository` are registered as lazy singletons because
they hold no per-screen state, while `FeedbackBloc` and `ExportBloc` are
factories so each feature gets a clean instance. `AuthBloc` is a singleton
because it drives top-level routing and must outlive individual screens.

### State management: three focused BLoCs
- **AuthBloc** subscribes to Firebase's `authStateChanges` stream and exposes a
  single `AuthStatus` (`unknown` / `authenticated` / `unauthenticated`) that the
  root widget switches on. Routing is therefore a pure function of auth state —
  there is no imperative navigation after login.
- **FeedbackBloc** holds one `FeedbackEntry` *draft* in its state and enriches it
  step by step across the three collection screens (`UserDetailsSubmitted` →
  `BugDetailsSubmitted` → `MediaAdded`), then persists it on `FeedbackSubmitted`.
  Keeping the draft in the BLoC (rather than passing arguments between screens)
  means the multi-step form survives back-navigation and is trivial to reset.
- **ExportBloc** encapsulates the secure-export sequence: count check → biometric
  gate → CSV build → scoped-storage write, surfacing each stage as a status the
  UI reflects.

### Persistence: sqflite behind a dedicated service layer
`DatabaseService` is the only class that imports sqflite. It owns the connection,
schema, and CRUD. Media paths are stored as a single pipe-delimited column and
re-hydrated into a `List<String>` in the model, which avoids a second table for
what is essentially a small attachment list. The model carries its own
`toMap`/`fromMap`, so the datasource stays thin.

### Scoped storage: Android MediaStore
Media and the exported CSV are written to the public **Downloads/FeedbackCollector**
folder via `media_store_plus`, which uses the MediaStore API. This is the
Android 10+ compliant path and avoids requesting broad legacy storage
permissions. The write logic is isolated in `MediaStorageService` so the storage
backend can be swapped without touching the rest of the app.

### Security: biometric gate before export
Export is gated by `local_auth` with `biometricOnly: false`, so it accepts a
fingerprint/face *or* falls back to the device PIN/password — matching the
assignment's "fingerprint/password" wording and working on devices without
biometric hardware.

### UI: restrained, animated, consistent
A single indigo-based palette and one Material 3 theme keep the look
intentional. Motion is built in at the framework level rather than bolted on:
a shared `FadeSlidePageRoute` gives every transition the same feel, a
`StaggeredColumn` fades screen content in on mount, the CTA button has a
press-scale + inline spinner, and the Thank You screen uses an elastic check
animation before auto-returning to the start of the loop.

### A deliberate correction over the common tutorial pattern
Most current guides (including the one I started from) use
`GoogleSignIn().signIn()` with `google_sign_in ^6.x`. That API was **removed in
v7**, which replaced it with a singleton plus a separate `initialize()` and
`authenticate()` flow, and split authentication from scope authorization. The
`AuthRepository` here targets the 7.x API, which is the main reason the
authentication code is structured the way it is.

## 2. Challenges faced

- **Google Sign-In v7 migration.** The breaking change above meant the
  copy-paste auth code from most tutorials would not compile. Resolving it
  required understanding the new identity-vs-authorization split and that
  Android needs a `serverClientId` (the Web OAuth client ID) for the returned
  `idToken` to be accepted by Firebase.
- **Sharing one feedback draft across four screens.** Passing data via route
  arguments gets fragile with a back button. Holding the draft in `FeedbackBloc`
  and providing that BLoC above the navigator solved it cleanly and made the
  "Thank You → reset → User Details" loop a single event.
- **Scoped storage on Android 10+.** Direct file writes to Downloads are
  restricted on modern Android. MediaStore is the correct route but its plugin
  APIs vary between versions, so I isolated it behind a service to contain that
  churn.
- **local_auth platform requirement.** It needs `FlutterFragmentActivity`
  instead of the default `FlutterActivity`, which is easy to miss and produces a
  confusing runtime crash if forgotten — documented in the README.

## 3. Potential improvements with more time

- **Editing / history view.** Currently the owner collects and exports; a list
  screen to review, search, edit, or delete individual entries would round out
  the CRUD already supported by the datasource.
- **Cloud sync / backup.** An optional Firestore (or owner-triggered cloud
  upload) backup so data isn't confined to one device, with offline-first
  reconciliation.
- **Richer media.** Video thumbnails (currently a placeholder icon), audio
  capture, and an in-app media preview before submission.
- **Robustness.** Retry/queue for failed saves, schema migrations as the model
  grows, and structured logging instead of swallowed exceptions.
- **Testing depth.** The repo includes sample `FeedbackBloc` tests; with more
  time I'd add widget tests for each screen and fakes for the repositories to
  cover the export and auth flows end to end.
- **Accessibility & i18n.** Semantic labels, dynamic type, and externalised
  strings for localisation.

## 4. Requirement coverage map

| Requirement | Where |
|---|---|
| Google Sign-In via Firebase | `data/repositories/auth_repository.dart`, `bloc/auth` |
| BLoC architecture | `presentation/bloc/*` (auth, feedback, export) |
| sqflite + dedicated DB layer | `data/datasources/database_service.dart` |
| Dependency injection (get_it) | `injection_container.dart` |
| Scoped storage (MediaStore) | `data/services/media_storage_service.dart` |
| 5 screens + specified flow | `presentation/screens/*`, `app.dart` |
| Auto-redirect after Thank You | `thank_you_screen.dart` |
| Biometric-gated CSV export | `bloc/export`, `data/services/biometric_service.dart`, `csv_export_service.dart` |
| CSV column format | `csv_export_service.dart`, `core/constants/app_constants.dart` |

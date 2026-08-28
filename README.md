# Field Service

Offline-first field service management app for technicians working in low-connectivity areas.

## Why these choices

- **Riverpod** over Bloc/GetX — compile-safe providers, no `BuildContext` needed in business logic, and dependency overrides make repositories trivial to mock in tests.
- **Clean Architecture** (data / domain / presentation per feature) — the offline-sync logic touches network, cache, and UI all at once, so keeping those layers separate is what makes it testable at all.
- **Hive** for local storage instead of a relational DB — the data here (jobs, pending sync operations) doesn't need complex joins, and Hive's setup overhead is much lower than Drift/sqflite for a 48-hour build.
- **Dio** with a custom `AuthInterceptor` — handles token attach + single-flight refresh-and-retry on 401, so screens never have to think about auth expiry.

## Setup


flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run

## Project structure


lib/
├── core/           # shared: network, storage, theme, router, utils
└── features/
    ├── auth/
    ├── dashboard/
    ├── jobs/
    ├── job_details/
    ├── sync/
    └── notifications/


Each feature follows `data/ -> domain/ -> presentation/`.

## Status

Feature-complete for the assessment scope:

- Secure login with mock auth and persisted session (token storage + auto-login on relaunch)
- Dashboard with job stats computed from the local cache, stat cards deep-link into a pre-filtered jobs list
- Paginated jobs list with pull-to-refresh, debounced search (with proper reset on clear), and multi-filter (status/priority/date) that combines correctly and preserves pagination
- Job details with map (OpenStreetMap), timeline (status-change history), attachments (view/open), and validated status transitions
- Offline write queue with FIFO sync-on-reconnect, including offline-captured photo attachments
- Image capture, compression, upload with progress and retry
- Deadline reminder notifications, plus new-job and sync-completion notifications
- Persistent light/dark theme
- Offline connectivity banner
- Unit tests for repositories, usecases, and the sync queue

## Known limitations

- No real backend was provided for this assessment, so `AuthRemoteDatasource` and `JobRemoteDatasource` simulate API responses locally, maintaining state in-memory for the app session so updates persist across fetches. Swapping in real endpoints only requires changing these two classes.
- Background sync runs on app foreground/resume + connectivity change, not a true OS-level background task — `workmanager` was evaluated but caused repeated Gradle/Kotlin build failures in this environment, so it was left out rather than risk a broken build this close to the deadline. WorkManager/BGTaskScheduler would be the production next step.
- Conflict resolution uses last-write-wins with a retry-then-dead-letter queue; a production version would want per-field merge or a manual resolution UI.

## Testing


flutter test

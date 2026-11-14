# HotelFlow

**A local-first hotel reservation and room-availability desktop application** built with **Flutter, Dart and SQLite**.

> **Status:** early development / functional prototype (documentation snapshot: **11 November 2026**). This is **not production-ready**. The hotel-facing UI is primarily in Polish. The app is branded HotelFlow; the Flutter package name is currently `hotel_app`.

HotelFlow is being developed around the workflow of a small hotel with **24 fixed rooms**. It aims to make everyday reception tasks straightforward: inspect room details, check whether rooms are free for specific dates, browse current and upcoming reservations, view bookings by day, and eventually complete reservations spanning multiple rooms.

## Current functionality — verified in the repository

| Area | Current implementation | Status |
| --- | --- | --- |
| Desktop app shell | Flutter Material app with a persistent sidebar, five main pages, a settings overlay, and a five-second startup splash | Implemented |
| Rooms | Database repository, list, room-detail dialog, seed of 24 rooms | Implemented; needs validation tests |
| SQLite | Local `sqlite3` database, schema initialization, foreign-key pragma, basic indexes | Implemented; requires hardening |
| Test data | Seeded rooms; explicit `seedFakeReservations()` helper is available but not called at startup | Development-only data |
| Room search | Check-in/check-out inputs, guest count, validation dialog, and `NOT EXISTS` SQL query | Implemented; availability results and multi-room selection are wired |
| Date input | Reusable editable text field plus calendar picker, formatting and validity callback | Implemented; edge cases remain |
| Reservations | Query current/upcoming reservations, 20-per-page `LIMIT/OFFSET` list, FTS5 search, result count, detail dialog and deletion | Implemented; transactional overlap re-check remains |
| Pricing | Capacity-based nightly defaults, editable Settings rates, per-booking room overrides, historical totals | Implemented; seasonal pricing and discounts not included |
| Calendar | Date selection, arrival/current/departure badges, detail preview, and deletion | Implemented; broader history workflow remains separate |
| Bed configurations | `BedConfigurations` enum and per-room selection | Implemented and persisted in `reservation_rooms` |
| Multi-room booking | Selecting multiple rooms and completing one combined booking with per-room configuration | Implemented; schema and pricing details still need further hardening |
| Reservation history | Settings section with past-reservation query, FTS5 search, result count and detail preview | Implemented; cleanup is explicit, not scheduled automatically |
| Guests | Guest search, details, reservations, edit and deletion with confirmation | Implemented |
| Search indexes | SQLite FTS5 indexes for guests and reservations | Implemented and rebuilt after relevant mutations |

**Important distinction:** a feature can be present in source code without having complete end-to-end tests or a finished reception workflow. Check the open issues before using HotelFlow with real guest data.

## Hotel rules currently used

- **24 rooms:** numbers `1` through `24`.
- **22 standard rooms:** default `capacity = 2`, `extra_bed = true`.
- **Two quadruple rooms:** rooms **12 and 24**, `capacity = 4`, `extra_bed = false`.
- The seed uses the **base capacity** (2 or 4). Extra-bed selection is available for rooms that support it during booking.
- Bookings use a **half-open interval** `[check-in, check-out)`: a new booking may start on another booking's check-out date.
- Room availability must be checked for the **entire requested stay**, not just on check-in day.
- Default nightly rates are 300 PLN for capacity-2 rooms, 500 PLN for capacity-4 rooms, and 60 PLN for an extra bed; rates are editable in Settings.
- Reservation totals are stored as integer grosze snapshots and are not changed by later pricing edits.
- Multiple-room selection and per-room bed layouts are supported by the current reservation schema.

## Tech stack

- **Flutter / Dart:** desktop user interface and application code.
- **SQLite via `sqlite3`** (`^3.8.0`): embedded local storage; synchronous queries.
- **`path_provider`** (`^2.1.6`): application documents directory.
- **`path`** (`^1.9.1`): file path construction.
- **VS Code** and the Flutter/Dart extensions for development.

See [`pubspec.yaml`](pubspec.yaml) for exact dependencies; do not treat the placeholder app version `1.0.0+1` as a released product version.

## Run locally (Windows)

**Prerequisites:** Flutter SDK with desktop support, Dart (included with Flutter), VS Code or another editor, and the Visual Studio C++ desktop build tools used by Flutter Windows builds.

```bash
# Clone the repository
git clone https://github.com/Kokosanka264/HotelFlow.git
cd HotelFlow

flutter doctor
flutter pub get
flutter run -d windows
```

The application shows a Flutter startup splash for at least five seconds, initializes the database, creates tables and FTS5 search indexes, and seeds the fixed rooms. The current startup path does not invoke reservation test seeding. **Do not launch the existing build against a real hotel database without reviewing room seeding and migration behavior.**

For static checks:

```bash
flutter analyze
flutter test
```

These are recommended verification commands; **no successful CI/test result is claimed** by this README. Check current test coverage rather than assuming it exists.

## Data location and safety

The current implementation opens `hotel.db` inside the directory returned by `getApplicationDocumentsDirectory()`; on the developer's Windows setup this may resolve to a Documents/OneDrive location. The database file itself should **not be committed to Git**. Keep backups, close the app before manual database edits, and plan to move the live database to a suitable local application-data location before production.

No remote database, authentication system, cloud syncing or automatic email-sending service is implemented. The initial intended deployment is **one Windows computer**, not concurrent editing from several devices.

## Project structure

```text
lib/
  main.dart                         # initialize database, launch Flutter
  Panels/
    main_frame.dart                 # sidebar + active content area
    main_panel.dart                 # page selection
    sidebar_panel.dart
    home_page_panel.dart            # search form
    avaliable_rooms_homepage.dart   # availability list widget
    rooms_panel.dart
    reservation_panel.dart          # reservation pagination controls
    list_view_panel_reservations.dart
    reservation_history_panel.dart  # past reservation search
    calendar_panel.dart
    in_this_day_reservations.dart
    add_reservation_panel.dart      # reservation form and success dialog
    settings_panel.dart             # settings overlay navigation
    price_changing_panel.dart       # editable pricing settings
    hotel_flow_splash_screen.dart   # Flutter startup screen
  database/
    database_helper.dart            # SQLite connection, schema, seed data
    room_repository.dart
    reservation_repository.dart
    guest_repository.dart
    pricing_repository.dart
  models/
    room.dart
    reservation.dart
    bed_configuration.dart
    pricing_settings.dart
    hotel.dart                       # placeholder
  widgets/
    date_input_field.dart
    room_button.dart
    sidebar_button.dart
  features/
    colors_in_app.dart
docs/
  architecture.md
  database.md
  decisions.md
  tasks.md
  issuses_to_solve.md
  ai_development.md
```

Names in this tree deliberately match the present source files, including `avaliable` (a future rename to `available` would improve consistency).

## How the app works today

1. `main()` starts Flutter immediately; `HotelFlow` displays the splash while database initialization, table creation, search-index rebuilding, room seeding, and a five-second minimum delay complete.
2. `MainFrame` owns main navigation and opens Settings as a near-full-screen overlay with a close button; `MainPanel` maps the other sidebar selections to Home, Rooms, Reservations, Calendar, and Guests.
3. The Home form validates dates and guest count, queries available rooms, supports selecting multiple rooms, validates bed configurations/capacity, and opens the reservation form.
4. The reservation form loads pricing defaults, allows per-room nightly overrides, calculates the stay total, reuses matching guests when confirmed, creates new guests otherwise, saves a historical total in grosze, and shows a success dialog after commit.
5. The Reservations page uses `ReservationRepository.getReservationsPage(page, pageSize, query)` and `ListView.builder`; FTS5 search and a result count appear under the search bar. Clicking a row opens a detail dialog with deletion.
6. The Calendar page loads today's reservations on open, filters by selected date, marks arrivals/current/departures, and supports detail/deletion dialogs.
7. Guests can be searched with FTS5, opened to view their reservations, edited, and deleted when they have no reservations.
8. Settings contains editable pricing and a searchable reservation-history panel. `removeReservationsOlderThanTwoMonths()` is available for explicit cleanup and is not run automatically.

## Development timeline

| Date | Milestone | Source of status |
| --- | --- | --- |
| **4 Nov 2026** | Initial Flutter repository, basic pages, sidebar navigation, layout and colors | GitHub commits `ad3093a`, `017da5d`, `5c3464c`, `1d4f4f1`, `68285df` |
| **5–6 Nov 2026** | SQLite models/repositories, fixed rooms, day calendar, reservation pagination, search workflow, reusable date field developed iteratively | Development conversation and current code; individual changes not separately dated in commit history |
| **7 Nov 2026** | Availability date fixes and home-page integration pushed to `main` | GitHub commits `e70817f`, `846796e` |

The current `main` branch contains the code described above, but some changes were added in batches; **do not interpret this timeline as an exact per-feature Git commit audit**.

## Next milestones

1. Add transactional overlap re-checking during reservation save.
2. Add focused repository/widget tests for date and capacity validation.
3. Add explicit scheduling or user-facing controls for two-month reservation cleanup after confirming retention requirements.
4. Add reservation editing and improve refresh behavior across all panels.
5. Improve local data storage, backups, deployment packaging, UI polish, and automated checks.

## Documentation

- [Architecture and data flow](docs/architecture.md)
- [Database schema and booking constraints](docs/database.md)
- [Engineering decisions and trade-offs](docs/decisions.md)
- [Current issues to solve](docs/issuses_to_solve.md)

## Responsible development

HotelFlow is a learning-driven, client-informed project. AI tools may help with explanations, design reviews and implementation suggestions, but behavior needs to be understood and independently checked before production use. Avoid committing real guest personal information, sample database files or credentials to this public repository.

## Development Approach

HotelFlow is developed using a human-in-the-loop,
AI-assisted software engineering workflow.

AI coding agents support code analysis, debugging,
and selected implementation tasks.

Architectural decisions, code review, and final
approval remain under developer control.

For more details, see
[AI-Assisted Development](docs/ai_development.md).

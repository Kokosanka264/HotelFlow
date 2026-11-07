# HotelFlow

**A local-first hotel reservation and room-availability desktop application** built with **Flutter, Dart and SQLite**.

> **Status:** early development / functional prototype (documentation snapshot: **7 November 2026**, `main` commit `846796ed`). This is **not production-ready**. The hotel-facing UI is primarily in Polish. The name shown in the app is HotelFlow; the Flutter package name is currently `hotel_app`.

HotelFlow is being developed around the workflow of a small hotel with **24 fixed rooms**. It aims to make everyday reception tasks straightforward: inspect room details, check whether rooms are free for specific dates, browse current and upcoming reservations, view bookings by day, and eventually complete reservations spanning multiple rooms.

## Current functionality — verified in the repository

| Area | Current implementation | Status |
| --- | --- | --- |
| Desktop app shell | Flutter Material app with a persistent sidebar and four pages | Implemented |
| Rooms | Database repository, list, room-detail dialog, seed of 24 rooms | Implemented; needs validation tests |
| SQLite | Local `sqlite3` database, schema initialization, foreign-key pragma, basic indexes | Implemented; requires hardening |
| Test data | Up to 21 distinct, capacity-aware sample bookings, with collision check | Development-only; currently enabled at startup |
| Room search | Check-in/check-out inputs, guest count, validation dialog, `NOT EXISTS` SQL query | Prototype; results and search button are not fully connected |
| Date input | Reusable editable text field plus calendar picker, formatting and validity callback | Implemented; edge cases remain |
| Reservations | Query current/upcoming reservations, 20-per-page `LIMIT/OFFSET` list, detail dialog | Prototype; last-page control and search missing |
| Calendar | Select day and read reservations for that day | Prototype; initial load and layout need refinement |
| Bed configurations | `BedConfigurations` enum | Defined, not persisted or wired to bookings |
| Multi-room booking | Selecting multiple rooms and completing one combined booking | Planned |
| Hidden reservation history | Historical bookings in a separate, low-visibility area | Planned; **not** part of main Reservations tab |

**Important distinction:** a feature can be present in source code without having complete end-to-end tests or a finished reception workflow. Check the open issues before using HotelFlow with real guest data.

## Hotel rules currently used

- **24 rooms:** numbers `1` through `24`.
- **22 standard rooms:** default `capacity = 2`, `extra_bed = true`.
- **Two quadruple rooms:** rooms **12 and 24**, `capacity = 4`, `extra_bed = false`.
- The seed uses the **base capacity** (2 or 4). A third person in a standard room requires an explicit extra-bed decision in the future booking workflow; this is **not yet implemented**.
- Bookings use a **half-open interval** `[check-in, check-out)`: a new booking may start on another booking's check-out date.
- Room availability must be checked for the **entire requested stay**, not just on check-in day.
- Multiple-room selection and per-room bed layouts are business requirements, not yet supported by the current reservation schema.

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

The application currently initializes the database on startup and automatically invokes both `seedRooms()` **and `seedReservations()`**. **Do not launch the existing build against a real hotel database:** test data is still automatically inserted. Remove or guard the development seeding before deployment.

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
    calendar_panel.dart
    in_this_day_reservations.dart
    add_reservation_panel.dart      # placeholder
  database/
    database_helper.dart            # SQLite connection, schema, seed data
    room_repository.dart
    reservation_repository.dart
  models/
    room.dart
    reservation.dart
    bed_configuration.dart
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
  github-issues.md
```

Names in this tree deliberately match the present source files, including `avaliable` (a future rename to `available` would improve consistency).

## How the app works today

1. `main()` initializes SQLite, creates tables and indexes, adds fixed rooms, inserts tagged development reservations, then starts Flutter.
2. `MainFrame` holds the selected sidebar page; `MainPanel` maps it to Home, Rooms, Reservations or Calendar.
3. The Home form collects dates and guests; `RoomRepository.getAvaliableRooms()` uses SQL to exclude rooms with overlapping reservations. **The displayed availability widget currently performs its own query, and its selection callback is empty.**
4. The Reservations page uses `ReservationRepository.getReservationsPage(page, pageSize)` and `ListView.builder`; clicking a row opens a details dialog.
5. The Calendar page requests reservations active on the selected date via `getReservationsForDate()`.

## Development timeline

| Date | Milestone | Source of status |
| --- | --- | --- |
| **4 Nov 2026** | Initial Flutter repository, basic pages, sidebar navigation, layout and colors | GitHub commits `ad3093a`, `017da5d`, `5c3464c`, `1d4f4f1`, `68285df` |
| **5–6 Nov 2026** | SQLite models/repositories, fixed rooms, day calendar, reservation pagination, search workflow, reusable date field developed iteratively | Development conversation and current code; individual changes not separately dated in commit history |
| **7 Nov 2026** | Availability date fixes and home-page integration pushed to `main` | GitHub commits `e70817f`, `846796e` |

The current `main` branch contains the code described above, but some changes were added in batches; **do not interpret this timeline as an exact per-feature Git commit audit**.

## Next milestones

1. Repair the Home search flow so results change **only** after a successful Search action; display empty/loading states and select multiple rooms.
2. Strengthen date and guest validation, conflict checks, checkout boundary behavior and tests.
3. Add reservation pagination count and search (guest name, surname, room number).
4. Design group bookings with per-room guests and bed configurations, then migrate the schema.
5. Create reservation management (create/edit/cancel) with transactional re-checking of availability.
6. Put short-lived historical reservations in a **separate, unobtrusive location** (possibly Settings); define a retention policy based on **check-out**, subject to legal/operational requirements.
7. Improve local data storage, backups, deployment packaging, UI polish, and automated checks.

## Documentation

- [Architecture and data flow](docs/architecture.md)
- [Database schema and booking constraints](docs/database.md)
- [Engineering decisions and trade-offs](docs/decisions.md)
- [Suggested GitHub issues and comment templates](docs/github-issues.md)

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
[AI-Assisted Development][docs/ai-development.md].

# HotelFlow — Engineering Decision Log

**Snapshot:** 7 November 2026 · `main` `846796ed`. A lightweight decision log, not a claim of formal ADR approval. Each entry states the choice, rationale, trade-off, implementation status and revisiting trigger.

## Development chronology

| Period | Progress |
| --- | --- |
| **4 Nov 2026** | Flutter project and GitHub repository established; modular panels, main-frame/sidebar navigation and branding. Confirmed by dated GitHub commits. |
| **5–6 Nov 2026** | Iterative work on Room/Reservation models, SQLite data access, hotel-room inventory, reservation calendar, pagination, reusable date input, test records and SQL availability. The conversation and current repository substantiate the features; exact per-file commit dates are not recorded. |
| **7 Nov 2026** | Current `main` contains the implementation, including commits for date selection corrections and home-page changes (`e70817f`, `846796e`). Documentation updated to match current source. |

## DEC-001 — Flutter and Dart for a desktop-first reception tool

- **Choice:** Flutter Material UI with Dart; Windows is the primary desktop target.
- **Why:** Reusable widgets, a familiar component model, one application codebase, fast prototyping and visual customization.
- **Trade-off:** Native desktop toolchain required; cross-platform scaffold files do not mean every platform has been tested.
- **Status:** Implemented; Windows production packaging pending.

## DEC-002 — Local-first SQLite for a single computer

- **Choice:** Embedded SQLite file via `sqlite3` and `path_provider`, no remote database or mandatory server.
- **Why:** Fits the first client's one-PC workflow, simple offline access and predictable deployment.
- **Trade-off:** No multi-device synchronization; backups, safe filesystem location and connection lifecycle become app responsibilities. `sqlite3` calls are synchronous.
- **Status:** Implemented; storage location, backup, migration hardening outstanding.
- **Revisit when:** Multiple employees/devices need simultaneous writes.

## DEC-003 — Separate UI, models and repositories

- **Choice:** Use `lib/Panels`, `lib/widgets`, `lib/models` and `lib/database`; SQL lives in repositories/helper.
- **Why:** Easier to understand, change and test than a monolithic widget.
- **Trade-off:** Some UI still creates repositories directly and duplicates fetches; no dedicated booking service yet.
- **Status:** Implemented as a pragmatic starting structure.
- **Revisit when:** Multi-room booking needs transactional business logic.

## DEC-004 — Persistent sidebar rather than separate routes for main sections

- **Choice:** `MainFrame` stores `selectedIndex`, `SidebarPanel` sends callbacks, `MainPanel` switches between Home, Rooms, Reservations and Calendar.
- **Why:** Reception staff can switch quickly between high-frequency operations; navigation logic stays centralized.
- **Trade-off:** Stateful screens can be reconstructed when changing pages, requiring explicit refresh/retention policy.
- **Status:** Implemented.

## DEC-005 — Fixed 24-room inventory

- **Choice:** Seed rooms 1–24; rooms 12/24 are 4-person rooms; other 22 have base capacity 2 and extra-bed availability flag.
- **Why:** Models the actual small hotel rather than a generic unlimited inventory system.
- **Trade-off:** Hard-coded configuration; `INSERT OR IGNORE` will not update changed room properties automatically.
- **Status:** Implemented as data seeding; not a configurable admin workflow.

## DEC-006 — Separate check-in and check-out as calendar dates

- **Choice:** Store ISO `YYYY-MM-DD` strings; occupancy uses `[check-in, check-out)` where check-out is exclusive.
- **Why:** Hotel bookings are day-based, and back-to-back stays can share a turnover date.
- **Trade-off:** Must normalize `DateTime` timestamps and use a consistent hotel-local definition of today; not a room-hour scheduling system.
- **Status:** Mostly implemented; validations/timezone consistency require improvement.

## DEC-007 — Reusable date entry widget

- **Choice:** A `DateInputField` combines manual `TextField`, `showDatePicker`, a controller, input-format validation and callbacks.
- **Why:** One component handles both check-in and check-out; less duplication and clear parent-child data flow.
- **Trade-off:** Validity flags and date constraints need robust synchronization when the parent changes.
- **Status:** Implemented; further testing needed.

## DEC-008 — SQL performs availability filtering

- **Choice:** `NOT EXISTS` query excludes rooms with overlapping reservations for the entire requested interval.
- **Why:** Only matching room records cross the database/UI boundary; avoids loading all bookings into Dart.
- **Trade-off:** Query correctness depends on consistent date format and a fresh check at save time.
- **Status:** Implemented in `RoomRepository.getAvaliableRooms`; UI search flow not fully wired.

## DEC-009 — Paginate reservations in sets of 20

- **Choice:** Database-side `LIMIT/OFFSET` plus Flutter `ListView.builder`, controlled by previous/next arrows above the list.
- **Why:** Quick navigation and predictable amount of loaded data, even as bookings accumulate.
- **Trade-off:** Needs a total-count query, correct last-page disabling and a search filter; `OFFSET` can be costly at extremely large offsets.
- **Status:** Partial implementation: pagination/list works, right-arrow boundary incomplete.

## DEC-010 — Keep historical bookings separate from daily reservations

- **Choice:** Main Reservations view shows active/upcoming bookings; historic bookings should be available in a less prominent, separate area, possibly Settings.
- **Why:** Client wants the primary screen uncluttered.
- **Trade-off:** Archival, data retention, accounting obligations and deletion all require agreement.
- **Status:** UI/product decision, **not implemented**. Tentative ~7-day post-check-out retention requires confirmation.

## DEC-011 — Model bed layouts explicitly

- **Choice:** Define `BedConfigurations` enum (`single`, `double`, `doubleCombined`, `extraBed`, `four`, `fourCombined`).
- **Why:** A per-room choice is more expressive and safer than free-form text.
- **Trade-off:** Need to define valid options by room type and persist them for each booked room; enum labels may evolve.
- **Status:** Enum exists; no application/persistence integration.

## DEC-012 — Design for multiple rooms in one customer booking

- **Choice:** Future workflow: enter dates/guests → search available rooms → select multiple rooms → validate total capacity and per-room guest allocation → enter contact details and bed setups → save atomically.
- **Why:** A customer may need several rooms under one reservation.
- **Trade-off:** Current `reservations.room_id` links one row to one room. Requires deliberate schema redesign, likely `bookings` + `booking_rooms`, and transactions.
- **Status:** Requirements/architecture proposal only; no working multi-room booking.

## DEC-013 — Seed development data to test pagination and conflicts

- **Choice:** Add `seedRooms()` and 21 tagged reservations with deterministic identifiers, capacity rules and a conflict check.
- **Why:** Enables realistic UI tests, especially the second page with one item.
- **Trade-off:** Seeded reservations are intentionally fake, but **are currently added at every app startup**; marker idempotency makes dated seeds stale over time. Some may be skipped if existing data overlaps.
- **Status:** Implemented for development; must be disabled before production.

## DEC-014 — Keep sensitive guest data out of GitHub

- **Choice:** Do not commit the live `hotel.db`, credentials, or guest records; use artificial sample identities.
- **Why:** The repository is public, while booking records can contain personal contact details.
- **Trade-off:** A checked-out repository has to initialize its own local data.
- **Status:** Intended policy; verify `.gitignore`, repository history and any accidental uploads.

## DEC-015 — Use a transparent, iterative AI-assisted workflow

- **Choice:** Build features incrementally, understand code and SQL, inspect diffs and test after AI suggestions; use focused Git commits and issues.
- **Why:** Supports independent engineering judgement and traceable development.
- **Trade-off:** AI suggestions are hypotheses, not evidence of working functionality.
- **Status:** Ongoing development practice.

## DEC-016 — Defer production infrastructure until the single-PC workflow is correct

- **Choice:** Prioritize correct availability, safe booking transactions, room configuration, clear GUI and database recovery ahead of cloud features.
- **Why:** These directly affect reception safety and client usability.
- **Trade-off:** No external API, remote alerts or real-time shared access in this version.
- **Status:** Active scope boundary.

## DEC-017 — Changing room reserving stracture

- **Choice:** Instead of assigning one reservation to only one room, we can assign one reservation to multiple rooms.
- **Why:** This makes making reservations more easy and practical.
- **Trade-off:** Restructre most of the apps functuality.
- **Status:** Finished development

## DEC-018 — Adding client database 

- **Choice:** Making user be able to see guests detailes and theirs reservations.
- **Why:** This gives user more control over application and enables him/her to search directly for particular guest.
- **Trade-off:** Restructre some of the apps functuality.
- **Status:** Ongoing development practise.

## Decisions still open

1. **Booking schema:** one booking + join table or grouped single-room reservations; migration approach.
2. **Capacity:** whether standard rooms allow 3 people only when extra bed is explicitly chosen; bed combinations and minors rules.
3. **Data policy:** historical retention duration, lawful recordkeeping, and whether to anonymize instead of delete.
4. **Persistence:** move to local app-data directory; backups, migration versioning, recovery UI.
5. **Search:** how to synchronize committed criteria, available results and multi-room selections.
6. **Release:** Windows installer, app updates, error logging, data backup and handover to reception staff.

## Updating this log

For each material change, record **date, decision, context, options considered, trade-offs and implementation status**. Update an existing decision if its status changes; add a new one if a deliberate architecture choice replaces it. Keep proposed functionality visibly separate from shipped behavior.

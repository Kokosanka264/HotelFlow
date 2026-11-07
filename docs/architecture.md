# HotelFlow — Architecture

**Snapshot:** 2026-11-07 · `main` at `846796ed` · **development prototype**.

This document describes **what the source code implements today**, where it differs from the intended design, and the next architectural steps. Directory names and method names preserve their current spelling.

## 1. Architectural goals and constraints

HotelFlow targets a small hotel's reception desk. The present scope is a **single Windows desktop process** working with one embedded SQLite file. The app is designed for 24 known rooms and date-based bookings. Polish labels and a simple sidebar reduce the number of actions reception staff need to perform. The UI should remain responsive, data should remain consistent, and the code should permit later changes without stuffing SQL into widget trees.

Out of scope for the current build: server/API, synchronization among multiple computers, accounts and roles, email automation, confirmed production data migration, multi-room reservation persistence, and a polished historical-record screen.

## 2. Layer diagram

```mermaid
flowchart TD
  Entry[main.dart / HotelFlow] --> Frame[MainFrame: selectedIndex]
  Frame --> Sidebar[SidebarPanel + SidebarButton]
  Frame --> Main[MainPanel: page switch]
  Main --> Home[HomePagePanel]
  Main --> Rooms[RoomsPanel]
  Main --> Reservations[ReservationPanel]
  Main --> Calendar[CalendarPanel]
  Home --> Dates[DateInputField]
  Home --> Available[AvaliableRoomsView]
  Rooms --> RoomRepo[RoomRepository]
  Available --> RoomRepo
  Home --> RoomRepo
  Reservations --> ReservationList[ListViewPanelReservations]
  ReservationList --> ReservationRepo[ReservationRepository]
  Calendar --> ReservationRepo
  ReservationRepo --> Helper[DatabaseHelper / sqlite3]
  RoomRepo --> Helper
  Helper --> DB[(hotel.db)]
```

This is a **pragmatic layered UI/repository/database structure**, not a full clean-architecture implementation. Some widgets still instantiate repositories directly and run synchronous database operations during UI lifecycle methods.

## 3. Startup and navigation

`main.dart`:

1. Calls `WidgetsFlutterBinding.ensureInitialized()`.
2. Awaits `DatabaseHelper.initialize()`.
3. Calls `createTables()`.
4. Calls `seedRooms()` and `seedReservations()` (**development seeding is currently always on**).
5. Calls `runApp(const HotelFlow())`.

`MainFrame` is a `StatefulWidget` owning `selectedIndex`; `SidebarPanel` receives `selectedIndex` and `onPageSelected`. `MainPanel` maps indexes `0..3` to Home, Rooms, Reservations, Calendar. `SidebarButton` is a reusable presentation widget. The flow does not use a named-route navigator for those four areas.

## 4. UI components and responsibilities

| File / component | Responsibility now | Limitations / follow-up |
| --- | --- | --- |
| `home_page_panel.dart` | Owns selected check-in/out dates, guest count, form validity flags; triggers availability query | Local `avaliableRooms` is set but **not passed into** the results widget; search results can show before Search and stale/invalid dates can affect results |
| `date_input_field.dart` | Reusable text input with `YYYY-MM-DD` parser, date picker, `firstDate`, `onDateChanged`, `onValidityChanged` | Ensure manual date also respects `firstDate`; account for invalid edited text and parent-driven updates |
| `avaliable_rooms_homepage.dart` | Holds an availability list and reloads when input dates change | No room selection state; `onRoomPressed` currently receives an empty handler in Home; no explicit Search trigger |
| `rooms_panel.dart` / `room_button.dart` | Lists rooms and opens room details | `loadRooms()` is called during `build` and during item creation; cache once instead of repeated DB queries |
| `reservation_panel.dart` | Maintains `page=0`, `pageSize=20`, left/right buttons, detail dialog | Forward button never disables at last page; no total count, search field, or refresh flow |
| `list_view_panel_reservations.dart` | Fetches page in `initState()`, refreshes in `didUpdateWidget()`, builds lazy list | Synchronous query and no explicit reload when records change without `page` change |
| `calendar_panel.dart` | Date picker, selected date, `ReservationRepository.getReservationsForDate()` | No `initState()` load; nesting `setState` in `onDateChanged` and `loadReservations` is unnecessary; validate `Column` layout |
| `in_this_day_reservations.dart` | Lists reservations for a chosen day | Own nested `Scaffold`/`AppBar`; simpler embedded list would reduce layout complexity |
| `bed_configuration.dart` | Defines six enum cases | Not connected to room/booking models or persisted |
| `add_reservation_panel.dart`, `hotel.dart` | Empty placeholders | Planned design only |

### Current booking-search flow

```mermaid
sequenceDiagram
  actor Receptionist
  participant Home as HomePagePanel
  participant Picker as DateInputField
  participant Results as AvaliableRoomsView
  participant Repo as RoomRepository
  participant SQLite as hotel.db
  Receptionist->>Picker: Type or pick check-in/out
  Picker-->>Home: onDateChanged(date)
  Home-->>Results: Updated dates via rebuild
  Results->>Repo: getAvaliableRooms(dates)
  Repo->>SQLite: SELECT rooms WHERE NOT EXISTS(overlap)
  SQLite-->>Results: Available rooms
  Receptionist->>Home: Click Search
  Home->>Repo: getAvaliableRooms(dates)
  Repo-->>Home: List<Room> stored locally
  Note over Home,Results: Home's list is not used by Results
```

**Recommended improvement:** keep dates and guest count as form/draft state; on Search, validate and set a committed search criteria object; obtain one result list; pass it to a stateless results widget. Then implement multi-selection (`Set<int>` room IDs), sum permitted capacity, and pass a booking draft to the next step. Ensure a new Search invalidates previous selections.

### Current paginated reservations flow

`ReservationPanel` owns `page` and sends it to `ListViewPanelReservations(page, pageSize, onReservationPressed)`. The child loads `List<Reservation>` via `getReservationsPage()` in `initState()` and when `page/pageSize` change in `didUpdateWidget()`. `ListView.builder` lazily constructs visible tiles, while SQLite `LIMIT/OFFSET` restricts fetched records. Both optimizations serve different purposes.

**Next:** `countCurrentReservations()`, prevent increment beyond the last page, reset `page` when filters change, and search with database-side filtering before `LIMIT/OFFSET`.

### Current calendar flow

`CalendarPanel` holds `selectedDate` and `reservations`; selecting a date invokes `loadReservations(date)` which calls `getReservationsForDate(date)`. `DayReservations` displays the records. Because there is no initial load, opening the calendar before selecting a date can show an empty list even when today's bookings exist.

## 5. Data and domain layer

Models:

- `Room`: `id`, `roomNumber`, `capacity`, `extraBed` and `toString()`.
- `Reservation`: `id`, `roomId`, `guestName`, `guestSurname`, nullable contact fields, `guestCount`, `checkInDate`, `checkOutDate` and display formatting.
- `BedConfigurations`: `single`, `double`, `doubleCombined`, `extraBed`, `four`, `fourCombined` (not yet used in the persistence workflow).

Repositories:

- `RoomRepository`: `addRoom`, `getAllRooms`, `getAvaliableRooms`.
- `ReservationRepository`: `addReservation`, `getReservationsForDate`, `getReservationsPage`.
- `DatabaseHelper`: opens DB, enables foreign keys, creates tables and indexes, seeds room/test booking data.

No separate service layer, state-management library, or repository interfaces exist yet. Introduce these only when the complexity of a multi-step booking flow justifies them.

## 6. Target multi-room booking architecture (not implemented)

```mermaid
flowchart LR
  Search[Search criteria] --> Availability[Find free rooms]
  Availability --> Selection[Select multiple room IDs]
  Selection --> Capacity[Validate people and configurations]
  Capacity --> Draft[Booking draft]
  Draft --> Details[Guest/contact details]
  Details --> Check[Transactional re-check]
  Check --> Save[Persist booking + allocated rooms]
```

The current `reservations.room_id` enforces **one room per reservation row**. A future booking with several rooms needs a deliberate data-model change. A suggested target is `bookings` (shared guest and dates) + `booking_rooms` (one row per room, allocated guests, bed configuration), with uniqueness and overlap checks performed transactionally. This is a proposal, **not current schema**. See [`database.md`](database.md).

## 7. Reliability and performance priorities

1. **Availability correctness:** treat dates as `[checkIn, checkOut)`, disallow same-day/negative stays, and re-check availability when saving inside a transaction.
2. **Storage:** synchronous `sqlite3` queries can block the UI isolate; small data is unlikely to be an issue but heavy operations should move off the UI isolate if profiling warrants it.
3. **Query efficiency:** use `NOT EXISTS` for free-room checks and index `(room_id, check_in_date, check_out_date)`; remove duplicate indexes.
4. **Pagination:** `LIMIT/OFFSET` plus `ListView.builder` and result count; the initial hotel is small but bookings accumulate.
5. **Data protection:** keep real guest data out of Git, turn off sample booking seeding, choose a suitable local DB location, add backup/restore and retention safeguards.
6. **Separation of concerns:** keep SQL in repositories, remove unused imports/empty callbacks, prefer immutable widget input and plain `Room`/`Reservation` models.
7. **Testing:** add overlapping interval, adjacent stays, same-day date, guest capacity, seed idempotency, last-page and invalid-input tests.

## 8. Implementation history and status

- **4 Nov:** initial project, page shell, sidebar navigation, visual theming (GitHub commit history).
- **5–6 Nov:** SQLite schema, repositories, fixed room inventory, calendar, paging and early reusable widgets developed through iterative implementation and discussions.
- **7 Nov:** latest `main` includes full files for those features and two dated commits addressing availability dates and Home screen (`e70817f`, `846796e`). Other files were committed in aggregate rather than feature-by-feature.

This is an architectural snapshot, not a statement that every UI flow is complete or tested.

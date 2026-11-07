# HotelFlow — Development Task Tracker

**Project:** HotelFlow — Desktop Hotel Management System  
**Tech Stack:** Flutter, Dart, SQLite

## Status Legend

- ✅ Done — Implemented and verified
- 🔄 In Progress — Currently being developed
- ⏳ Not Started — Planned for future implementation
- 🚧 Blocked — Cannot proceed until another task is completed

---

## 1. Application Architecture

| Task | Status |
|---|---|
| Set up Flutter desktop environment | ✅ Done |
| Initialize GitHub repository | ✅ Done |
| Create modular project structure | ✅ Done |
| Implement sidebar navigation | ✅ Done |
| Connect main application panels | ✅ Done |
| Establish consistent UI styling | 🔄 In Progress |

## 2. Database

| Task | Status |
|---|---|
| Initialize SQLite database | ✅ Done |
| Create rooms and reservations tables | ✅ Done |
| Implement RoomRepository | 🔄 In Progress |
| Implement ReservationRepository | 🔄 In Progress |
| Seed 24 hotel rooms | ✅ Done |
| Generate test reservations | ✅ Done |
| Implement database migrations | ⏳ Not Started |
| Implement database backup and restore | ⏳ Not Started |

## 3. Home Page — Room Availability

| Task | Status |
|---|---|
| Implement check-in and check-out fields | ✅ Done |
| Implement calendar date picker | ✅ Done |
| Implement manual date validation | 🔄 In Progress |
| Implement room availability SQL query | ✅ Done |
| Connect Search button to displayed results | 🔄 In Progress |
| Implement multi-room selection | 🔄 In Progress | 
| Validate total selected room capacity | ⏳ Not Started |
| Count avaliable guests in rooms based on choosen rooms | ⏳ Not Started |
| Impement add reservation button | ⏳ Not Started |

## 4. Reservations

| Task | Status |
|---|---|
| Create ReservationPanel | ✅ Done |
| Implement paginated reservation list | ✅ Done |
| Add previous and next buttons | ✅ Done |
| Disable navigation beyond last page | ⏳ Not Started |
| Implement reservation search | ⏳ Not Started |
| Implement reservation creation form | ⏳ Not Started |
| Implement multi-room booking | ⏳ Not Started |
| Prevent overlapping bookings during saving | ⏳ Not Started |
| Implement reservation editing and cancellation | ⏳ Not Started |

## 5. Calendar

| Task | Status |
|---|---|
| Create CalendarPanel | ✅ Done |
| Display reservations for selected date | 🔄 In Progress |
| Load today's reservations automatically | ⏳ Not Started |
| Improve calendar and list layout | 🔄 In Progress |

## 6. Room Configuration

| Task | Status |
|---|---|
| Define bed configuration enum | ✅ Done |
| Implement room-specific bed choices | ⏳ Not Started |
| Assign guest counts per room | ⏳ Not Started |
| Save bed configuration in database | ⏳ Not Started |

## 7. Testing and Release

| Task | Status |
|---|---|
| Introduce systematic `flutter analyze` checks | 🔄 In Progress |
| Add automated unit and widget tests | ⏳ Not Started |
| Remove test reservation seeding from release builds | ⏳ Not Started |
| Implement separate reservation history | ⏳ Not Started |
| Prepare Windows desktop release | ⏳ Not Started |
| Prepare user documentation for hotel staff | ⏳ Not Started |

---

## Current Development Focus

- Correct room availability search and result refresh.
- Implement multiple room selection.
- Validate guest capacity before reservation creation.
- Design database support for multi-room bookings.

## Development Notes

Task statuses should be updated after meaningful progress.

A feature should be marked as **Done** only after its implementation has been verified.

For more detailed technical information, refer to:

- [Architecture](docs/architecture.md)
- [Database](docs/database.md)
- [Engineering Decisions](docs/decisions.md)
- [AI-Assisted Development](docs/ai_development.md)
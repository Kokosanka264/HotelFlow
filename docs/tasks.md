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
| Implement client database | ⏳ Not Started |

## 3. Home Page — Room Availability

| Task | Status |
|---|---|
| Implement check-in and check-out fields | ✅ Done |
| Implement calendar date picker | ✅ Done |
| Implement manual date validation | ✅ Done |
| Implement room availability SQL query | ✅ Done |
| Connect Search button to displayed results | ✅ Done |
| Implement multi-room selection | ✅ Done | 
| Validate total selected room capacity | ✅ Done |
| Count avaliable guests in rooms based on choosen rooms | ✅ Done |
| Impement add reservation button | ✅ Done |
| Require clicking search befor refreshing the avaliable rooms | ✅ Done |
| Remove all avaliable rooms while user changes input data | ✅ Done |
| Implement the option when there are no avaliable rooms | ⏳ Not Started |

## 4. Reservations

| Task | Status |
|---|---|
| Create ReservationPanel | ✅ Done |
| Implement paginated reservation list | ✅ Done |
| Add previous and next buttons | ✅ Done |
| Disable navigation beyond last page | ✅ Done |
| Implement reservation search | ⏳ Not Started |
| Implement reservation creation form | ✅ Done |
| Connect Home Page to Add Reservation| ✅ Done |
| Implement multi-room booking | ✅ Done |
| Prevent overlapping bookings during saving | ⏳ Not Started |
| Implement reservation editing and cancellation | ⏳ Not Started |
| Implement checking current bed configuration is enough for specific number of people (extra bed case) | ⏳ Not Started |

## 5. Calendar

| Task | Status |
|---|---|
| Create CalendarPanel | ✅ Done |
| Display reservations for selected date | ✅ Done |
| Load today's reservations automatically | ✅ Done |
| Improve calendar and list layout | 🔄 In Progress |
| Make reservations clickable, so user can see an overview of reservation | ⏳ Not Started |

## 6. Room Configuration

| Task | Status |
|---|---|
| Define bed configuration enum | ✅ Done |
| Implement room-specific bed choices | ✅ Done |
| Assign guest counts per room | ✅ Done |
| Save bed configuration in database | ✅ Done |

## 7. Clients

| Task | Status |
|---|---|
| Implement 'Add Client' | ⏳ Not Started |
| Implement 'Remove Client' | ⏳ Not Started |
| Make a ListView of all clients in database | ⏳ Not Started |

## 8. Pricing

| Task | Status |
|---|---|
| Implement pricing option | ⏳ Not Started |
| Implement changing and updating prices | ⏳ Not Started |
| Disable changing prices for existing reservatoins | ⏳ Not Started |


## 9. Testing and Release

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
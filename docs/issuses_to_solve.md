# HotelFlow — Issues to Solve

This document tracks known gaps that remain in the current implementation.

| ID | Issue | Status |
|---|---|---|
| 1 | Re-check room overlap while saving a reservation | Open |
| 2 | Normalize dates and define “today” consistently in the hotel timezone | Open |
| 3 | Add automated tests for FTS search, date boundaries, cleanup and transactions | Open |
| 4 | Decide when the two-month reservation cleanup should run | Open |
| 5 | Add reservation editing | Open |
| 6 | Add backup/restore and a versioned migration system | Open |
| 7 | Improve filtered pagination totals and refresh behavior | Open |

## 1. Re-check room overlap during save

The Home page checks availability before the booking form opens. The repository
transaction currently inserts the reservation and room assignments without repeating
the overlap query. A second user or process could therefore create a conflicting
reservation between the search and save steps.

Expected solution: re-check every selected room inside the write transaction and abort
with a clear error if any interval overlaps.

## 2. Date and timezone consistency

Dates are stored as `YYYY-MM-DD`, while several queries use SQLite `DATE('now')`.
SQLite's current date is UTC, which can differ from the hotel's local calendar date
near midnight.

Expected solution: pass an explicit local cutoff date from Dart or configure one
consistent hotel timezone policy.

## 3. Automated verification

Static analysis passes for targeted files, but the project still needs focused tests
for:

- FTS5 guest and reservation searches, including empty and no-match queries.
- Adjacent, overlapping, equal and reversed booking dates.
- New-guest reservation transactions and rollback behavior.
- Two-calendar-month cleanup and index rebuilding.
- Pagination and result-count behavior.

## 4. Retention scheduling

`ReservationRepository.removeReservationsOlderThanTwoMonths()` deletes records whose
checkout is earlier than `DATE('now', '-2 months')` and returns the deleted count. It is
currently an explicit method only. Legal, accounting and operational retention rules
must be confirmed before invoking it automatically.

## 5. Reservation editing

Reservations can be created, viewed and deleted. Editing guest details is supported
through the guest management panel, but there is no reservation edit workflow for
dates, rooms, bed configurations or prices.

## 6. Backup and migrations

The database has additive startup handling for `total_grosze` and FTS index versioning,
but no general migration table, backup UI or restore flow.

## 7. Filtered pagination

The reservation list applies FTS filtering before `LIMIT/OFFSET` and displays the
number of loaded rows. A separate global count for all matches and more robust refresh
behavior would improve navigation as the database grows.

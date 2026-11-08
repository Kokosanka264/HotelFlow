HotelFlow — Issues to Solve
This document tracks UI and state-management issues identified during development.
Issue Overview
ID	Issue	Status
1	Reset HomePagePanel after creating a reservation	Open
2	Show available rooms only after a valid search	Implemented — needs verification
3	Display today's reservations when opening the calendar	Open
4	Refresh ReservationPanel after deleting a reservation	Open


1. Reset HomePagePanel After Creating a Reservation
Problem: After a reservation is successfully created, HomePagePanel still displays the previous reservation details or selected rooms.

Expected behavior: Once the reservation is saved successfully, the home page should return to its initial state. Previous selections and search results should be cleared.

Status: Implemented - need verfication

Verification: Create a reservation and confirm that the home page no longer shows the previous selection.
2. Display Available Rooms Only After Search
Problem: Available rooms may appear before the user presses the Search button.

Expected behavior: The available-rooms area should remain empty until the user performs a valid search. Changing a relevant input should invalidate previously displayed results until Search is pressed again.

Implemented solution: Introduced a boolean variable, isSearchPressed:
- Set it to false when a relevant selection or input changes.
- Set it to true when the user presses Search and the search inputs are valid.
- Display available rooms only when isSearchPressed is true.
Status: Resolved

Verification: Before searching, no rooms should appear. After a valid search, results should appear. Changing dates or guest count should hide the previous results until another search.
3. Automatically Display Today's Reservations in Calendar
Problem: When the user opens the calendar panel, today's reservations are not displayed automatically.

Expected behavior: Opening CalendarPanel should automatically select today's date and load its reservations, without requiring the user to click the date.

Status: Open

Verification: Open the calendar panel and confirm that today's reservations load immediately. Selecting another date should update the displayed reservations.
4. Refresh ReservationPanel After Deleting a Reservation
Problem: After a reservation is deleted, the deleted reservation remains visible in ReservationPanel until the view is manually refreshed or reopened.

Expected behavior: After successful deletion, the displayed reservation list should reload automatically so the deleted entry disappears immediately.

Status: Resolved

Verification: Delete a reservation and confirm that it disappears from the list without navigating away or clicking the panel again. Canceling deletion should leave the list unchanged.
Status Legend
- Open — Not yet resolved.
- In Progress — Currently being worked on.
- Implemented — needs verification — A solution has been added but still needs testing.
- Resolved — Verified to work as expected.
class Room{
  final int id;
  final String roomNumber;
  final int capacity;
  final bool extraBed;
  
  Room({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.extraBed,
  });

  @override 
   String toString() {
    return 'Room $roomNumber';
  }
}
import 'package:hotel_app/models/bed_configuration.dart';

class Room {
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

  int getCapacity() {
    return capacity;
  }

  bool hasExtra() {
    return extraBed;
  }
  int getId(){
    return id;
  }
  List<BedConfigurations> getPossibleBedConfigurations() {
    if (capacity == 4) {
      return [
        BedConfigurations.fourSingle,
        BedConfigurations.doubleAndTwoSingle,
      ];
    }
    return [
      BedConfigurations.single,
      BedConfigurations.twin,
      BedConfigurations.doubleBed,
      BedConfigurations.extraBed,
    ];
  }
}

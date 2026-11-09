class Guest {
  const Guest({
    required this.id,
    required this.name,
    required this.surname,
    this.email,
    this.phoneNumber,
  });

  final int id;
  final String name;
  final String surname;
  final String? email;
  final String? phoneNumber;
}

class Student {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? notes;

  Student({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.notes,
  });

  // Convert a Student into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'notes': notes,
    };
  }

  // Create a Student from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      notes: map['notes'],
    );
  }

  // Create a copy of the Student with optional new values
  Student copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
    );
  }
}

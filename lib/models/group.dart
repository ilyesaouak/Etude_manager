class Group {
  final int? id;
  final String name;
  final String schedule; // e.g., "Monday,Wednesday 17:00"
  final String? description;
  final int sessionsPerPayment; // 4 or 8 sessions per payment

  Group({
    this.id,
    required this.name,
    required this.schedule,
    this.description,
    this.sessionsPerPayment = 4, // Default to 4 sessions
  });

  // Convert a Group into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schedule': schedule,
      'description': description,
      'sessionsPerPayment': sessionsPerPayment,
    };
  }

  // Create a Group from a Map
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      schedule: map['schedule'],
      description: map['description'],
      sessionsPerPayment:
          map['sessionsPerPayment'] ?? 4, // Default to 4 for existing data
    );
  }

  // Create a copy of the Group with optional new values
  Group copyWith({
    int? id,
    String? name,
    String? schedule,
    String? description,
    int? sessionsPerPayment,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      schedule: schedule ?? this.schedule,
      description: description ?? this.description,
      sessionsPerPayment: sessionsPerPayment ?? this.sessionsPerPayment,
    );
  }
}

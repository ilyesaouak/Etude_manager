class Session {
  final int? id;
  final int groupId;
  final DateTime date;
  final String? notes;

  Session({
    this.id,
    required this.groupId,
    required this.date,
    this.notes,
  });

  // Convert a Session into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create a Session from a Map
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      groupId: map['groupId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
    );
  }

  // Create a copy of the Session with optional new values
  Session copyWith({
    int? id,
    int? groupId,
    DateTime? date,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

class Payment {
  final int? id;
  final int studentId;
  final DateTime date;
  final String? notes;

  Payment({
    this.id,
    required this.studentId,
    required this.date,
    this.notes,
  });

  // Convert a Payment into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create a Payment from a Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['studentId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
    );
  }

  // Create a copy of the Payment with optional new values
  Payment copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

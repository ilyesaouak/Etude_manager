class Attendance {
  final int? id;
  final int sessionId;
  final int studentId;
  final bool isPresent;

  Attendance({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.isPresent,
  });

  // Convert an Attendance into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'isPresent': isPresent ? 1 : 0,
    };
  }

  // Create an Attendance from a Map
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      sessionId: map['sessionId'],
      studentId: map['studentId'],
      isPresent: map['isPresent'] == 1,
    );
  }

  // Create a copy of the Attendance with optional new values
  Attendance copyWith({
    int? id,
    int? sessionId,
    int? studentId,
    bool? isPresent,
  }) {
    return Attendance(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}

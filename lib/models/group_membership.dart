class GroupMembership {
  final int? id;
  final int studentId;
  final int groupId;

  GroupMembership({
    this.id,
    required this.studentId,
    required this.groupId,
  });

  // Convert a GroupMembership into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'groupId': groupId,
    };
  }

  // Create a GroupMembership from a Map
  factory GroupMembership.fromMap(Map<String, dynamic> map) {
    return GroupMembership(
      id: map['id'],
      studentId: map['studentId'],
      groupId: map['groupId'],
    );
  }

  // Create a copy of the GroupMembership with optional new values
  GroupMembership copyWith({
    int? id,
    int? studentId,
    int? groupId,
  }) {
    return GroupMembership(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
    );
  }
}

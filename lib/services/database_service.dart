import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'etude_manager.db');
    return await openDatabase(
      path,
      version: 2, // Increment version for migration
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create Student table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Create Group table
    await db.execute('''
      CREATE TABLE groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        schedule TEXT NOT NULL,
        description TEXT,
        sessionsPerPayment INTEGER NOT NULL DEFAULT 4
      )
    ''');

    // Create Session table
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // Create Attendance table
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        studentId INTEGER NOT NULL,
        isPresent INTEGER NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Create Payment table
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Create GroupMembership table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE group_memberships(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        groupId INTEGER NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE,
        UNIQUE(studentId, groupId)
      )
    ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sessionsPerPayment column to groups table
      await db.execute('''
        ALTER TABLE groups ADD COLUMN sessionsPerPayment INTEGER NOT NULL DEFAULT 4
      ''');
    }
  }

  // Student CRUD operations
  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Group CRUD operations
  Future<int> insertGroup(Group group) async {
    final db = await database;
    return await db.insert('groups', group.toMap());
  }

  Future<List<Group>> getGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('groups');
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  Future<Group?> getGroup(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Group.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGroup(Group group) async {
    final db = await database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Session CRUD operations
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sessions');
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<List<Session>> getSessionsByGroup(int groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Attendance CRUD operations
  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceBySession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getAttendanceByStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<int> updateAttendance(Attendance attendance) async {
    final db = await database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payment CRUD operations
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsByStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<Payment?> getPayment(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // GroupMembership CRUD operations
  Future<int> addStudentToGroup(int studentId, int groupId) async {
    final db = await database;
    return await db.insert('group_memberships', {
      'studentId': studentId,
      'groupId': groupId,
    });
  }

  Future<int> removeStudentFromGroup(int studentId, int groupId) async {
    final db = await database;
    return await db.delete(
      'group_memberships',
      where: 'studentId = ? AND groupId = ?',
      whereArgs: [studentId, groupId],
    );
  }

  Future<List<Student>> getStudentsInGroup(int groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN group_memberships gm ON s.id = gm.studentId
      WHERE gm.groupId = ?
    ''', [groupId]);
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<List<Group>> getGroupsForStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT g.* FROM groups g
      INNER JOIN group_memberships gm ON g.id = gm.groupId
      WHERE gm.studentId = ?
    ''', [studentId]);
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  // Utility methods
  Future<int> getAttendanceCountForStudent(int studentId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM attendance
      WHERE studentId = ? AND isPresent = 1
    ''', [studentId]);
    return result.first['count'] as int;
  }

  Future<int> getPaymentCountForStudent(int studentId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM payments
      WHERE studentId = ?
    ''', [studentId]);
    return result.first['count'] as int;
  }

  Future<bool> shouldStudentPay(int studentId) async {
    final attendanceCount = await getAttendanceCountForStudent(studentId);
    final paymentCount = await getPaymentCountForStudent(studentId);

    // Get the student's groups to determine sessions per payment
    final groups = await getGroupsForStudent(studentId);
    if (groups.isEmpty) return false;

    // For now, use the first group's sessionsPerPayment
    // In the future, you might want to handle multiple groups differently
    final sessionsPerPayment = groups.first.sessionsPerPayment;

    // Check if student should pay based on their group's session count
    return attendanceCount >= (paymentCount + 1) * sessionsPerPayment;
  }
}

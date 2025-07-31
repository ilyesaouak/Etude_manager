import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

class StudentProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _students = await _databaseService.getStudents();
    } catch (e) {
      debugPrint('Error loading students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStudent(Student student) async {
    try {
      final id = await _databaseService.insertStudent(student);
      if (id > 0) {
        await loadStudents(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error adding student: $e');
    }
    return false;
  }

  Future<bool> updateStudent(Student student) async {
    try {
      final result = await _databaseService.updateStudent(student);
      if (result > 0) {
        await loadStudents(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error updating student: $e');
    }
    return false;
  }

  Future<bool> deleteStudent(int id) async {
    try {
      final result = await _databaseService.deleteStudent(id);
      if (result > 0) {
        await loadStudents(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting student: $e');
    }
    return false;
  }

  Future<Student?> getStudent(int id) async {
    try {
      return await _databaseService.getStudent(id);
    } catch (e) {
      debugPrint('Error getting student: $e');
      return null;
    }
  }

  Future<int> getAttendanceCount(int studentId) async {
    try {
      return await _databaseService.getAttendanceCountForStudent(studentId);
    } catch (e) {
      debugPrint('Error getting attendance count: $e');
      return 0;
    }
  }

  Future<bool> shouldStudentPay(int studentId) async {
    try {
      return await _databaseService.shouldStudentPay(studentId);
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return false;
    }
  }

  Future<List<Group>> getStudentGroups(int studentId) async {
    try {
      return await _databaseService.getGroupsForStudent(studentId);
    } catch (e) {
      debugPrint('Error getting student groups: $e');
      return [];
    }
  }
}

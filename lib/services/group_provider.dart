import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

class GroupProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _databaseService.getGroups();
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGroup(Group group) async {
    try {
      final id = await _databaseService.insertGroup(group);
      if (id > 0) {
        await loadGroups(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error adding group: $e');
    }
    return false;
  }

  Future<bool> updateGroup(Group group) async {
    try {
      final result = await _databaseService.updateGroup(group);
      if (result > 0) {
        await loadGroups(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
    }
    return false;
  }

  Future<bool> deleteGroup(int id) async {
    try {
      final result = await _databaseService.deleteGroup(id);
      if (result > 0) {
        await loadGroups(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
    return false;
  }

  Future<Group?> getGroup(int id) async {
    try {
      return await _databaseService.getGroup(id);
    } catch (e) {
      debugPrint('Error getting group: $e');
      return null;
    }
  }

  Future<List<Student>> getGroupStudents(int groupId) async {
    try {
      return await _databaseService.getStudentsInGroup(groupId);
    } catch (e) {
      debugPrint('Error getting group students: $e');
      return [];
    }
  }

  Future<bool> addStudentToGroup(int studentId, int groupId) async {
    try {
      final result = await _databaseService.addStudentToGroup(studentId, groupId);
      return result > 0;
    } catch (e) {
      debugPrint('Error adding student to group: $e');
      return false;
    }
  }

  Future<bool> removeStudentFromGroup(int studentId, int groupId) async {
    try {
      final result = await _databaseService.removeStudentFromGroup(studentId, groupId);
      return result > 0;
    } catch (e) {
      debugPrint('Error removing student from group: $e');
      return false;
    }
  }

  Future<List<Session>> getGroupSessions(int groupId) async {
    try {
      return await _databaseService.getSessionsByGroup(groupId);
    } catch (e) {
      debugPrint('Error getting group sessions: $e');
      return [];
    }
  }
}

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'notification_service.dart';

class SessionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Session> _sessions = [];
  bool _isLoading = false;

  List<Session> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _databaseService.getSessions();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSession(Session session) async {
    try {
      final id = await _databaseService.insertSession(session);
      if (id > 0) {
        await loadSessions(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error adding session: $e');
    }
    return false;
  }

  Future<bool> updateSession(Session session) async {
    try {
      final result = await _databaseService.updateSession(session);
      if (result > 0) {
        await loadSessions(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error updating session: $e');
    }
    return false;
  }

  Future<bool> deleteSession(int id) async {
    try {
      final result = await _databaseService.deleteSession(id);
      if (result > 0) {
        await loadSessions(); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
    return false;
  }

  Future<Session?> getSession(int id) async {
    try {
      return await _databaseService.getSession(id);
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }

  Future<List<Session>> getSessionsByGroup(int groupId) async {
    try {
      return await _databaseService.getSessionsByGroup(groupId);
    } catch (e) {
      debugPrint('Error getting sessions by group: $e');
      return [];
    }
  }

  Future<List<Attendance>> getSessionAttendance(int sessionId) async {
    try {
      return await _databaseService.getAttendanceBySession(sessionId);
    } catch (e) {
      debugPrint('Error getting session attendance: $e');
      return [];
    }
  }

  Future<bool> markAttendance(
      int sessionId, int studentId, bool isPresent) async {
    try {
      final attendance = Attendance(
        sessionId: sessionId,
        studentId: studentId,
        isPresent: isPresent,
      );
      final result = await _databaseService.insertAttendance(attendance);

      // Check if student should pay after marking attendance
      if (result > 0 && isPresent) {
        await _checkAndNotifyPaymentDue(studentId, sessionId);
      }

      return result > 0;
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      return false;
    }
  }

  Future<bool> updateAttendance(Attendance attendance) async {
    try {
      final result = await _databaseService.updateAttendance(attendance);

      // Check if student should pay after updating attendance
      if (result > 0 && attendance.isPresent) {
        await _checkAndNotifyPaymentDue(
            attendance.studentId, attendance.sessionId);
      }

      return result > 0;
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      return false;
    }
  }

  Future<void> _checkAndNotifyPaymentDue(int studentId, int sessionId) async {
    try {
      // Check if student should pay based on their group's session count
      final shouldPay = await _databaseService.shouldStudentPay(studentId);

      if (shouldPay) {
        // Get student details
        final student = await _databaseService.getStudent(studentId);
        if (student != null) {
          // Get session details to determine group
          final session = await _databaseService.getSession(sessionId);
          if (session != null) {
            final group = await _databaseService.getGroup(session.groupId);
            if (group != null) {
              // Send immediate notification with group info
              await _sendPaymentDueNotification(student, group);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking payment due: $e');
    }
  }

  Future<void> _sendPaymentDueNotification(Student student, Group group) async {
    try {
      // Import notification service dynamically to avoid circular dependency
      final notificationService = NotificationService();

      await notificationService.sendPaymentDueNotification(student, group);
    } catch (e) {
      debugPrint('Error sending payment due notification: $e');
    }
  }
}

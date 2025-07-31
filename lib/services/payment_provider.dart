import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';

class PaymentProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> loadPaymentsByStudent(int studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _databaseService.getPaymentsByStudent(studentId);
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment(Payment payment) async {
    try {
      final id = await _databaseService.insertPayment(payment);
      if (id > 0) {
        await loadPaymentsByStudent(payment.studentId); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error adding payment: $e');
    }
    return false;
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      final result = await _databaseService.updatePayment(payment);
      if (result > 0) {
        await loadPaymentsByStudent(payment.studentId); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error updating payment: $e');
    }
    return false;
  }

  Future<bool> deletePayment(int id, int studentId) async {
    try {
      final result = await _databaseService.deletePayment(id);
      if (result > 0) {
        await loadPaymentsByStudent(studentId); // Reload the list
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting payment: $e');
    }
    return false;
  }

  Future<Payment?> getPayment(int id) async {
    try {
      return await _databaseService.getPayment(id);
    } catch (e) {
      debugPrint('Error getting payment: $e');
      return null;
    }
  }

  Future<bool> shouldStudentPay(int studentId) async {
    try {
      return await _databaseService.shouldStudentPay(studentId);
    } catch (e) {
      debugPrint('Error checking if student should pay: $e');
      return false;
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

  Future<int> getPaymentCount(int studentId) async {
    try {
      return await _databaseService.getPaymentCountForStudent(studentId);
    } catch (e) {
      debugPrint('Error getting payment count: $e');
      return 0;
    }
  }
}

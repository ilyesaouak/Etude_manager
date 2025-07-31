import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'student_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Student> _allStudents = [];
  List<Student> _pendingPaymentStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);

    try {
      await studentProvider.loadStudents();
      final students = studentProvider.students;

      final pendingPaymentStudents = <Student>[];

      for (final student in students) {
        final shouldPay = await studentProvider.shouldStudentPay(student.id!);
        if (shouldPay) {
          pendingPaymentStudents.add(student);
        }
      }

      setState(() {
        _allStudents = students;
        _pendingPaymentStudents = pendingPaymentStudents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Paiements en attente'),
            Tab(text: 'Tous les étudiants'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingPaymentsTab(),
                _buildAllStudentsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingPaymentsTab() {
    if (_pendingPaymentStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun paiement en attente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tous les étudiants sont à jour avec leurs paiements',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPaymentStudents.length,
      itemBuilder: (context, index) {
        final student = _pendingPaymentStudents[index];
        return _buildStudentPaymentCard(student, true);
      },
    );
  }

  Widget _buildAllStudentsTab() {
    if (_allStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun étudiant pour le moment',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allStudents.length,
      itemBuilder: (context, index) {
        final student = _allStudents[index];
        final isPendingPayment =
            _pendingPaymentStudents.any((s) => s.id == student.id);
        return _buildStudentPaymentCard(student, isPendingPayment);
      },
    );
  }

  Widget _buildStudentPaymentCard(Student student, bool isPendingPayment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPendingPayment ? Colors.orange : Theme.of(context).primaryColor,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(student.phoneNumber),
        trailing: isPendingPayment
            ? const Chip(
                label: Text('Paiement dû'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        onTap: () => _navigateToStudentPayment(student),
      ),
    );
  }

  void _navigateToStudentPayment(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPaymentScreen(student: student),
      ),
    ).then((_) => _loadStudents()); // Reload data when returning
  }
}

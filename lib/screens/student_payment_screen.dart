import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/models.dart';

class StudentPaymentScreen extends StatefulWidget {
  final Student student;

  const StudentPaymentScreen({super.key, required this.student});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  List<Payment> _payments = [];
  int _attendanceCount = 0;
  bool _shouldPay = false;
  bool _isLoading = true;
  int _sessionsPerPayment =
      4; // Default, will be updated based on student's group

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);

    try {
      await paymentProvider.loadPaymentsByStudent(widget.student.id!);
      final attendanceCount =
          await paymentProvider.getAttendanceCount(widget.student.id!);
      final shouldPay =
          await paymentProvider.shouldStudentPay(widget.student.id!);

      // Get student's groups to determine sessions per payment
      final studentGroups =
          await studentProvider.getStudentGroups(widget.student.id!);
      int sessionsPerPayment = 4; // Default
      if (studentGroups.isNotEmpty) {
        sessionsPerPayment = studentGroups.first.sessionsPerPayment;
      }

      setState(() {
        _payments = paymentProvider.payments;
        _attendanceCount = attendanceCount;
        _shouldPay = shouldPay;
        _sessionsPerPayment = sessionsPerPayment;
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
        title: Text('${widget.student.name} - Paiements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfoCard(),
                  const SizedBox(height: 16),
                  _buildPaymentStatusCard(),
                  const SizedBox(height: 16),
                  _buildPaymentHistoryCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.student.name.isNotEmpty
                    ? widget.student.name[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.student.phoneNumber,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    final paymentCount = _payments.length;
    final expectedPayments = (_attendanceCount / _sessionsPerPayment).ceil();

    return Card(
      color: _shouldPay
          ? Colors.orange.withOpacity(0.1)
          : Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _shouldPay ? Icons.warning : Icons.check_circle,
                  color: _shouldPay ? Colors.orange : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statut du paiement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Séances suivies',
                    _attendanceCount.toString(),
                    Icons.event_available,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Paiements effectués',
                    paymentCount.toString(),
                    Icons.payment,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_shouldPay) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement dû : L\'étudiant a assisté à $_attendanceCount séances ($_sessionsPerPayment séances par paiement).',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Paiement à jour',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique des paiements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _showAddPaymentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter paiement'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
              const Text(
                'Aucun paiement enregistré pour le moment',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...(_payments.map((payment) => _buildPaymentItem(payment))),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payment, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(payment.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeletePaymentDialog(payment),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMMM d, yyyy').format(selectedDate)),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addPayment(selectedDate, notesController.text.trim());
              },
              child: const Text('Ajouter paiement'),
            ),
          ],
        ),
      ),
    );
  }

  void _addPayment(DateTime date, String notes) async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    final payment = Payment(
      studentId: widget.student.id!,
      date: date,
      notes: notes.isNotEmpty ? notes : null,
    );

    final success = await paymentProvider.addPayment(payment);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Paiement ajouté avec succès'
                : 'Échec de l\'ajout du paiement',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadPaymentData(); // Reload data
      }
    }
  }

  void _showDeletePaymentDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le paiement'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le paiement du ${DateFormat('d MMMM yyyy', 'fr_FR').format(payment.date)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePayment(payment);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deletePayment(Payment payment) async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final success =
        await paymentProvider.deletePayment(payment.id!, widget.student.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Paiement supprimé avec succès'
                : 'Échec de la suppression du paiement',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadPaymentData(); // Reload data
      }
    }
  }
}

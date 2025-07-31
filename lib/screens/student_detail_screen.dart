import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'add_edit_student_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<Group> _studentGroups = [];
  int _attendanceCount = 0;
  bool _shouldPay = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);

    try {
      final groups = await studentProvider.getStudentGroups(widget.student.id!);
      final attendanceCount =
          await studentProvider.getAttendanceCount(widget.student.id!);
      final shouldPay =
          await studentProvider.shouldStudentPay(widget.student.id!);

      setState(() {
        _studentGroups = groups;
        _attendanceCount = attendanceCount;
        _shouldPay = shouldPay;
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
        title: Text(widget.student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
        ],
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
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildGroupsCard(),
                  if (_shouldPay) ...[
                    const SizedBox(height: 16),
                    _buildPaymentReminderCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            widget.student.phoneNumber,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.student.notes != null &&
                widget.student.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.student.notes!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Séances suivies',
                    _attendanceCount.toString(),
                    Icons.event_available,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Groupes',
                    _studentGroups.length.toString(),
                    Icons.group,
                    Colors.blue,
                  ),
                ),
              ],
            ),
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

  Widget _buildGroupsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groupes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_studentGroups.isEmpty)
              const Text(
                'Pas encore assigné à des groupes',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...(_studentGroups.map((group) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(group.name),
                        ),
                        Text(
                          group.schedule,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ))),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentReminderCard() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.payment, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paiement dû',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Text(
                    'Cet étudiant a terminé 4 séances ou plus et doit payer.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStudentScreen(student: widget.student),
      ),
    ).then((_) => _loadStudentData()); // Reload data when returning
  }
}

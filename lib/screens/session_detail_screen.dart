import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/models.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;
  final int initialTab;

  const SessionDetailScreen({
    super.key,
    required this.session,
    this.initialTab = 0,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Group? _group;
  List<Student> _groupStudents = [];
  List<Attendance> _sessionAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadSessionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);

    try {
      final group = await groupProvider.getGroup(widget.session.groupId);
      final groupStudents =
          await groupProvider.getGroupStudents(widget.session.groupId);
      final sessionAttendance =
          await sessionProvider.getSessionAttendance(widget.session.id!);

      setState(() {
        _group = group;
        _groupStudents = groupStudents;
        _sessionAttendance = sessionAttendance;
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
        title: Text(_group?.name ?? 'Détails de la séance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Détails', icon: Icon(Icons.info)),
            Tab(text: 'Présences', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildAttendanceTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfoCard(),
          const SizedBox(height: 16),
          _buildGroupInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la séance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMMM d, yyyy').format(widget.session.date),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Heure',
              DateFormat('h:mm a').format(widget.session.date),
            ),
            if (widget.session.notes != null &&
                widget.session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note,
                'Notes',
                widget.session.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    if (_group == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du groupe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.group,
              'Nom du groupe',
              _group!.name,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.schedule,
              'Horaire',
              _group!.schedule,
            ),
            if (_group!.description != null &&
                _group!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.description,
                'Description',
                _group!.description!,
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.people,
              'Étudiants',
              '${_groupStudents.length} étudiant${_groupStudents.length > 1 ? 's' : ''}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (_groupStudents.isEmpty) {
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
              'Aucun étudiant dans ce groupe',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Marquer les présences pour ${_groupStudents.length} étudiant${_groupStudents.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _saveAttendance,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _groupStudents.length,
            itemBuilder: (context, index) {
              final student = _groupStudents[index];
              final attendance = _sessionAttendance.firstWhere(
                (a) => a.studentId == student.id,
                orElse: () => Attendance(
                  sessionId: widget.session.id!,
                  studentId: student.id!,
                  isPresent: false,
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text(student.phoneNumber),
                  trailing: Switch(
                    value: attendance.isPresent,
                    onChanged: (value) {
                      setState(() {
                        final existingIndex = _sessionAttendance.indexWhere(
                          (a) => a.studentId == student.id,
                        );

                        final newAttendance =
                            attendance.copyWith(isPresent: value);

                        if (existingIndex >= 0) {
                          _sessionAttendance[existingIndex] = newAttendance;
                        } else {
                          _sessionAttendance.add(newAttendance);
                        }
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveAttendance() async {
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);

    try {
      // Save attendance for each student
      for (final attendance in _sessionAttendance) {
        if (attendance.id == null) {
          // New attendance record
          await sessionProvider.markAttendance(
            attendance.sessionId,
            attendance.studentId,
            attendance.isPresent,
          );
        } else {
          // Update existing attendance record
          await sessionProvider.updateAttendance(attendance);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présences enregistrées avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload attendance data
        _loadSessionData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de l\'enregistrement des présences'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

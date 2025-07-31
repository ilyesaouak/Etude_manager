import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'add_edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<Student> _groupStudents = [];
  List<Student> _allStudents = [];
  List<Session> _groupSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);

    try {
      final groupStudents =
          await groupProvider.getGroupStudents(widget.group.id!);
      await studentProvider.loadStudents();
      final allStudents = studentProvider.students;
      final groupSessions =
          await groupProvider.getGroupSessions(widget.group.id!);

      setState(() {
        _groupStudents = groupStudents;
        _allStudents = allStudents;
        _groupSessions = groupSessions;
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
        title: Text(widget.group.name),
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
                  _buildGroupInfoCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildStudentsCard(),
                  const SizedBox(height: 16),
                  _buildRecentSessionsCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildGroupInfoCard() {
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
                    widget.group.name.isNotEmpty
                        ? widget.group.name[0].toUpperCase()
                        : 'G',
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
                        widget.group.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            widget.group.schedule,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.group.description != null &&
                widget.group.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.group.description!,
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
                    'Étudiants',
                    _groupStudents.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Séances',
                    _groupSessions.length.toString(),
                    Icons.event,
                    Colors.green,
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

  Widget _buildStudentsCard() {
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
                  'Étudiants',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter Étudiant'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_groupStudents.isEmpty)
              const Text(
                'Aucun étudiant dans ce groupe pour le moment',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...(_groupStudents.map((student) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(student.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeStudentFromGroup(student),
                        ),
                      ],
                    ),
                  ))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Séances récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_groupSessions.isEmpty)
              const Text(
                'Aucune séance pour le moment',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...(_groupSessions.take(5).map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.event, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${session.date.day}/${session.date.month}/${session.date.year}',
                          ),
                        ),
                        if (session.notes != null && session.notes!.isNotEmpty)
                          Text(
                            session.notes!,
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

  void _showAddStudentDialog() {
    final availableStudents = _allStudents
        .where((student) => !_groupStudents.any((gs) => gs.id == student.id))
        .toList();

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les étudiants sont déjà dans ce groupe'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un étudiant au groupe'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableStudents.length,
            itemBuilder: (context, index) {
              final student = availableStudents[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(student.name),
                subtitle: Text(student.phoneNumber),
                onTap: () {
                  Navigator.pop(context);
                  _addStudentToGroup(student);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _addStudentToGroup(Student student) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success =
        await groupProvider.addStudentToGroup(student.id!, widget.group.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Étudiant ajouté au groupe avec succès'
                : 'Échec de l\'ajout de l\'étudiant au groupe',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadGroupData(); // Reload data
      }
    }
  }

  void _removeStudentFromGroup(Student student) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.removeStudentFromGroup(
        student.id!, widget.group.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Étudiant retiré du groupe avec succès'
                : 'Échec du retrait de l\'étudiant du groupe',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadGroupData(); // Reload data
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGroupScreen(group: widget.group),
      ),
    ).then((_) => _loadGroupData()); // Reload data when returning
  }
}

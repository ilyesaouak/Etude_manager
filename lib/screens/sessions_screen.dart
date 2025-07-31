import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'add_session_screen.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroupFilter;
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).loadSessions();
      _loadGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.loadGroups();
    setState(() {
      _groups = groupProvider.groups;
    });
  }

  List<Session> _filterSessions(List<Session> sessions) {
    List<Session> filtered = sessions;

    // Filter by search query (group name)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((session) {
        final group = _groups.firstWhere(
          (g) => g.id == session.groupId,
          orElse: () => Group(name: '', schedule: '', description: ''),
        );
        return group.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by selected group
    if (_selectedGroupFilter != null) {
      final selectedGroup = _groups.firstWhere(
        (g) => g.name == _selectedGroupFilter,
        orElse: () => Group(name: '', schedule: '', description: ''),
      );
      if (selectedGroup.id != null) {
        filtered = filtered
            .where((session) => session.groupId == selectedGroup.id)
            .toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSession(),
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          if (sessionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredSessions = _filterSessions(sessionProvider.sessions);

          return Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom de groupe...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Group Filter Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGroupFilter,
                      decoration: InputDecoration(
                        labelText: 'Filtrer par groupe',
                        prefixIcon: const Icon(Icons.filter_list),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous les groupes'),
                        ),
                        ..._groups.map((group) => DropdownMenuItem<String>(
                              value: group.name,
                              child: Text(group.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGroupFilter = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: filteredSessions.isEmpty &&
                        (_searchQuery.isNotEmpty ||
                            _selectedGroupFilter != null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucun résultat',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aucune séance trouvée avec les filtres appliqués',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : sessionProvider.sessions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.event_outlined,
                                      size: 48,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Aucune séance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commencez par créer votre première séance',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildSessionsList(filteredSessions),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddSession,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSessionsList(List<Session> sessions) {
    // Group sessions by date
    final Map<String, List<Session>> sessionsByDate = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final session in sessions) {
      final dateKey = dateFormat.format(session.date);
      if (!sessionsByDate.containsKey(dateKey)) {
        sessionsByDate[dateKey] = [];
      }
      sessionsByDate[dateKey]!.add(session);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = sessionsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final sessions = sessionsByDate[dateKey]!;
        final date = dateFormat.parse(dateKey);
        final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...sessions.map((session) => _buildSessionCard(session)),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(Session session) {
    return FutureBuilder<Group?>(
      future: Provider.of<GroupProvider>(context, listen: false)
          .getGroup(session.groupId),
      builder: (context, snapshot) {
        final groupName = snapshot.data?.name ?? 'Unknown Group';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.event, color: Colors.white),
            ),
            title: Text(
              groupName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(session.date),
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
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, session),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Voir détails'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'attendance',
                  child: Row(
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 8),
                      Text('Marquer présences'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _navigateToSessionDetail(session),
          ),
        );
      },
    );
  }

  void _navigateToAddSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSessionScreen(),
      ),
    );
  }

  void _navigateToSessionDetail(Session session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    );
  }

  void _handleMenuAction(String action, Session session) {
    switch (action) {
      case 'view':
        _navigateToSessionDetail(session);
        break;
      case 'attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailScreen(
              session: session,
              initialTab: 1, // Attendance tab
            ),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(session);
        break;
    }
  }

  void _showDeleteConfirmation(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer cette séance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteSession(Session session) async {
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.deleteSession(session.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Séance supprimée avec succès'
                : 'Échec de la suppression de la séance',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

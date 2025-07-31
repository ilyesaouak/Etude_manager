import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'add_edit_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupProvider>(context, listen: false).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Groupes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupProvider.groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun groupe pour le moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur le bouton + pour créer votre premier groupe',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupProvider.groups.length,
            itemBuilder: (context, index) {
              final group = groupProvider.groups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(group.schedule),
                        ],
                      ),
                      if (group.description != null &&
                          group.description!.isNotEmpty)
                        Text(
                          group.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, group),
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
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToGroupDetail(group),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGroup,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditGroupScreen(),
      ),
    );
  }

  void _navigateToGroupDetail(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(group: group),
      ),
    );
  }

  void _handleMenuAction(String action, Group group) {
    switch (action) {
      case 'view':
        _navigateToGroupDetail(group);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditGroupScreen(group: group),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(group);
        break;
    }
  }

  void _showDeleteConfirmation(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${group.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup(group);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(Group group) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.deleteGroup(group.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Groupe supprimé avec succès'
                : 'Échec de la suppression du groupe',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

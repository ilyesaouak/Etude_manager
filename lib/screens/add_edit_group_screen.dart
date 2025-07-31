import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';

class AddEditGroupScreen extends StatefulWidget {
  final Group? group;

  const AddEditGroupScreen({super.key, this.group});

  @override
  State<AddEditGroupScreen> createState() => _AddEditGroupScreenState();
}

class _AddEditGroupScreenState extends State<AddEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;
  int _sessionsPerPayment = 4; // Default to 4 sessions

  @override
  void initState() {
    super.initState();
    _isEditing = widget.group != null;
    if (_isEditing) {
      _nameController.text = widget.group!.name;
      _scheduleController.text = widget.group!.schedule;
      _descriptionController.text = widget.group!.description ?? '';
      _sessionsPerPayment = widget.group!.sessionsPerPayment;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le groupe' : 'Ajouter un groupe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom de groupe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Horaire (ex: Lundi,Mercredi 17:00)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  hintText: 'Jour(s) et heure du cours',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un horaire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Sessions per payment selection
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.payment, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Nombre de séances par paiement',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Choisissez combien de séances l\'étudiant doit suivre avant de payer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('4 séances'),
                            subtitle: const Text('Paiement plus fréquent'),
                            value: 4,
                            groupValue: _sessionsPerPayment,
                            onChanged: (value) {
                              setState(() {
                                _sessionsPerPayment = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('8 séances'),
                            subtitle: const Text('Paiement moins fréquent'),
                            value: 8,
                            groupValue: _sessionsPerPayment,
                            onChanged: (value) {
                              setState(() {
                                _sessionsPerPayment = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditing ? 'Modifier le groupe' : 'Ajouter le groupe',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      final group = Group(
        id: _isEditing ? widget.group!.id : null,
        name: _nameController.text.trim(),
        schedule: _scheduleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        sessionsPerPayment: _sessionsPerPayment,
      );

      bool success;
      if (_isEditing) {
        success = await groupProvider.updateGroup(group);
      } else {
        success = await groupProvider.addGroup(group);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '${_isEditing ? 'Groupe modifié' : 'Groupe ajouté'} avec succès'
                  : 'Échec de ${_isEditing ? 'la modification' : 'l\'ajout'} du groupe',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }
}

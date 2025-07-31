import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/models.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Group? _selectedGroup;
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    try {
      final groups = await groupProvider.loadGroups();
      setState(() {
        _groups = groupProvider.groups;
        _isLoading = false;
        if (_groups.isNotEmpty) {
          _selectedGroup = _groups.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une séance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildNoGroupsMessage()
              : _buildForm(),
    );
  }

  Widget _buildNoGroupsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun groupe disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous devez créer un groupe avant d\'ajouter une séance',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGroupDropdown(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSession,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Créer la séance',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return DropdownButtonFormField<Group>(
      decoration: const InputDecoration(
        labelText: 'Groupe',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group),
      ),
      value: _selectedGroup,
      items: _groups.map((group) {
        return DropdownMenuItem<Group>(
          value: group,
          child: Text(group.name),
        );
      }).toList(),
      onChanged: (Group? value) {
        setState(() {
          _selectedGroup = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Veuillez sélectionner un groupe';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Heure',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          _selectedTime.format(context),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _saveSession() async {
    if (_formKey.currentState!.validate() && _selectedGroup != null) {
      final sessionProvider =
          Provider.of<SessionProvider>(context, listen: false);

      // Combine date and time
      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final session = Session(
        groupId: _selectedGroup!.id!,
        date: sessionDateTime,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final success = await sessionProvider.addSession(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Séance créée avec succès'
                  : 'Échec de la création de la séance',
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

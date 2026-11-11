import 'package:flutter/material.dart';
import '../services/appointments_service.dart';

class AppointmentForm extends StatefulWidget {
  final Map<String, dynamic>? appointment;
  final bool? isBottomSheet;

  const AppointmentForm({super.key, this.appointment, this.isBottomSheet});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _doctorIdController = TextEditingController();
  final _appointmentDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _statusController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.appointment != null;
    if (_isEditing) {
      _populateForm();
    } else {
      // Date par défaut : aujourd'hui
      final now = DateTime.now();
      _appointmentDateController.text =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _startTimeController.text = '09:00';
      _endTimeController.text = '10:00';
    }
  }

  void _populateForm() {
    final appointment = widget.appointment!;
    _doctorIdController.text = appointment['doctorId']?.toString() ?? '';

    // Formater la date
    final appointmentDate = appointment['appointmentDate'];
    if (appointmentDate is String) {
      _appointmentDateController.text = appointmentDate.split('T')[0];
    } else if (appointmentDate is DateTime) {
      _appointmentDateController.text =
          '${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}';
    }

    // Formater les heures
    final startTime = appointment['startTime'];
    if (startTime is String) {
      _startTimeController.text = startTime.contains('T')
          ? startTime.split('T')[1].substring(0, 5)
          : startTime.length >= 5
          ? startTime.substring(0, 5)
          : startTime;
    } else if (startTime is DateTime) {
      _startTimeController.text =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    }

    final endTime = appointment['endTime'];
    if (endTime is String) {
      _endTimeController.text = endTime.contains('T')
          ? endTime.split('T')[1].substring(0, 5)
          : endTime.length >= 5
          ? endTime.substring(0, 5)
          : endTime;
    } else if (endTime is DateTime) {
      _endTimeController.text =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    }

    _reasonController.text = appointment['reason'] ?? '';
    _statusController.text = appointment['status'] ?? 'pending';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDateController.text.isNotEmpty
          ? DateTime.parse(_appointmentDateController.text)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _appointmentDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() {
        final timeStr =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStartTime) {
          _startTimeController.text = timeStr;
        } else {
          _endTimeController.text = timeStr;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        // Mise à jour
        await AppointmentsService.updateAppointment(
          id: widget.appointment!['id'],
          appointmentDate: _appointmentDateController.text,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          reason: _reasonController.text.isEmpty
              ? null
              : _reasonController.text,
          status: _statusController.text,
        );
      } else {
        // Création
        await AppointmentsService.createAppointment(
          doctorId: int.parse(_doctorIdController.text),
          appointmentDate: _appointmentDateController.text,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          reason: _reasonController.text.isEmpty
              ? null
              : _reasonController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBottomSheet = widget.isBottomSheet ?? false;

    if (isBottomSheet) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormContent(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: Text(
          _isEditing ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          // ID du médecin (seulement pour la création)
          if (!_isEditing) ...[
            TextFormField(
              controller: _doctorIdController,
              decoration: const InputDecoration(
                labelText: 'ID du médecin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'ID du médecin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Date du rendez-vous
          TextFormField(
            controller: _appointmentDateController,
            decoration: InputDecoration(
              labelText: 'Date du rendez-vous',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: _selectDate,
              ),
            ),
            readOnly: true,
            onTap: _selectDate,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une date';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Heure de début
          TextFormField(
            controller: _startTimeController,
            decoration: InputDecoration(
              labelText: 'Heure de début',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: () => _selectTime(true),
              ),
            ),
            readOnly: true,
            onTap: () => _selectTime(true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une heure';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Heure de fin
          TextFormField(
            controller: _endTimeController,
            decoration: InputDecoration(
              labelText: 'Heure de fin',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: () => _selectTime(false),
              ),
            ),
            readOnly: true,
            onTap: () => _selectTime(false),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une heure';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Raison
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Raison du rendez-vous',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Statut (seulement pour l'édition)
          if (_isEditing) ...[
            DropdownButtonFormField<String>(
              initialValue: _statusController.text,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: [
                DropdownMenuItem(value: 'pending', child: Text('En attente')),
                DropdownMenuItem(value: 'confirmed', child: Text('Confirmé')),
                DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                DropdownMenuItem(value: 'no_show', child: Text('Absent')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _statusController.text = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
          ],

          // Bouton de soumission
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D3188),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Modifier' : 'Créer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    _appointmentDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _reasonController.dispose();
    _statusController.dispose();
    super.dispose();
  }
}

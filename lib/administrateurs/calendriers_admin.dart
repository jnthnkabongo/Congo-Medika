import 'package:flutter/material.dart';
import 'package:frontend/services/appointments_service.dart';
import 'package:frontend/pages/appointment_form.dart';

class CalendriersAdmin extends StatefulWidget {
  const CalendriersAdmin({super.key});

  @override
  State<CalendriersAdmin> createState() => _CalendriersAdminState();
}

class _CalendriersAdminState extends State<CalendriersAdmin> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await AppointmentsService.getAllAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_searchQuery.isEmpty) return _appointments;
    final query = _searchQuery.toLowerCase();
    return _appointments.where((appointment) {
      final patientName = AppointmentsService.getPatientName(
        appointment,
      ).toLowerCase();
      final doctorName = AppointmentsService.getDoctorName(
        appointment,
      ).toLowerCase();
      final reason = (appointment['reason'] ?? '').toString().toLowerCase();
      return patientName.contains(query) ||
          doctorName.contains(query) ||
          reason.contains(query);
    }).toList();
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final patientName = AppointmentsService.getPatientName(appointment);
        final doctorName = AppointmentsService.getDoctorName(appointment);
        final statusColor = AppointmentsService.getStatusColor(
          appointment['status'],
        );

        return Padding(
          padding: const EdgeInsets.all(24),
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
              const Text(
                'Détails du rendez-vous',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D3188),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.person, 'Patient', patientName),
              _buildDetailRow(Icons.medical_services, 'Médecin', doctorName),
              _buildDetailRow(
                Icons.calendar_today,
                'Date',
                AppointmentsService.formatDate(appointment['appointmentDate']),
              ),
              _buildDetailRow(
                Icons.access_time,
                'Heure',
                '${appointment['startTime'] ?? '--:--'} - ${appointment['endTime'] ?? '--:--'}',
              ),
              _buildDetailRow(
                Icons.description,
                'Motif',
                appointment['reason']?.toString() ?? 'Non spécifié',
              ),
              _buildDetailRow(
                Icons.info_outline,
                'Statut',
                AppointmentsService.formatAppointmentStatus(
                  appointment['status'],
                ),
                valueColor: statusColor,
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAppointment(Map<String, dynamic> appointment) async {
    try {
      await AppointmentsService.updateAppointment(
        id: appointment['id'].toString(),
        status: 'confirmed',
      );
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous confirmé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editAppointment(Map<String, dynamic> appointment) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          AppointmentForm(appointment: appointment, isBottomSheet: true),
    );
    if (result == true) {
      _loadAppointments();
    }
  }

  Future<void> _deleteAppointment(Map<String, dynamic> appointment) async {
    final patientName = AppointmentsService.getPatientName(appointment);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: Text(
          'Voulez-vous vraiment supprimer le rendez-vous de $patientName ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AppointmentsService.deleteAppointment(appointment['id'].toString());
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8D3188), size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: const Text(
          'Rendez-vous',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF8D3188).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF8D3188)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un rendez-vous...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rendez-vous (${_filteredAppointments.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF8D3188)),
                  onPressed: _loadAppointments,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF8D3188)),
                ),
              )
            else if (_filteredAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun rendez-vous trouvé',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredAppointments.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAppointmentCard(appointment),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onCardAction(String action, Map<String, dynamic> appointment) {
    switch (action) {
      case 'view':
        _showAppointmentDetails(appointment);
        break;
      case 'edit':
        _editAppointment(appointment);
        break;
      case 'confirm':
        _confirmAppointment(appointment);
        break;
      case 'delete':
        _deleteAppointment(appointment);
        break;
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patientName = AppointmentsService.getPatientName(appointment);
    final doctorName = AppointmentsService.getDoctorName(appointment);
    final reason = appointment['reason']?.toString() ?? 'Consultation';
    final startTime = appointment['startTime'] ?? '--:--';
    final endTime = appointment['endTime'] ?? '--:--';
    final date = AppointmentsService.formatDate(appointment['appointmentDate']);
    final statusColor = AppointmentsService.getStatusColor(
      appointment['status'],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF8D3188).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF8D3188),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$reason • $doctorName',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '$date • $startTime - $endTime',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppointmentsService.formatAppointmentStatus(
                appointment['status'],
              ),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            onSelected: (value) => _onCardAction(value, appointment),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Voir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'confirm',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Confirmer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

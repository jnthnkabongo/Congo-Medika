import 'package:flutter/material.dart';
import '../services/appointments_service.dart';
import '../services/auth_service.dart';
import 'appointment_form.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class Calendriers extends StatefulWidget {
  const Calendriers({super.key});

  @override
  State<Calendriers> createState() => _CalendrierState();
}

class _CalendrierState extends State<Calendriers> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  String? _currentUserRole;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthService.getDonneesUser('user');
      setState(() {
        _currentUserRole = user?['role'];
        _userData = user;
      });

      final appointments = await AppointmentsService.getUserAppointments();
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredAppointments() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _appointments;
    }

    return _appointments.where((appointment) {
      final doctorName = AppointmentsService.getDoctorName(appointment);
      final patientName = AppointmentsService.getPatientName(appointment);
      final reason = appointment['reason'] ?? '';
      final query = _searchQuery!.toLowerCase();

      return doctorName.toLowerCase().contains(query) ||
          patientName.toLowerCase().contains(query) ||
          reason.toLowerCase().contains(query);
    }).toList();
  }

  void _createRendezVous() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const AppointmentForm(isBottomSheet: true),
          ),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _loadAppointments();
      }
    });
  }

  void _editAppointment(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AppointmentForm(
              appointment: appointment,
              isBottomSheet: true,
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _loadAppointments();
      }
    });
  }

  void _deleteAppointment(Map<String, dynamic> appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce rendez-vous ?',
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

    if (confirm == true) {
      try {
        await AppointmentsService.deleteAppointment(appointment['id']);
        if (mounted) {
          _loadAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  'Détails du rendez-vous',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  'Médecin',
                  AppointmentsService.getDoctorName(appointment),
                ),
                _buildDetailRow(
                  'Patient',
                  AppointmentsService.getPatientName(appointment),
                ),
                _buildDetailRow(
                  'Date',
                  AppointmentsService.formatDate(
                    appointment['appointmentDate'],
                  ),
                ),
                _buildDetailRow(
                  'Heure début',
                  _formatTimeFromAppointment(appointment['startTime']),
                ),
                _buildDetailRow(
                  'Heure fin',
                  _formatTimeFromAppointment(appointment['endTime']),
                ),
                _buildDetailRow(
                  'Raison',
                  appointment['reason'] ?? 'Non spécifiée',
                ),
                _buildDetailRow(
                  'Statut',
                  AppointmentsService.formatAppointmentStatus(
                    appointment['status'],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _editAppointment(appointment);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAppointment(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatTimeFromAppointment(dynamic timeData) {
    if (timeData is DateTime) {
      return AppointmentsService.formatTime(timeData);
    } else if (timeData is String) {
      // Vérifier si c'est au format HH:MM ou HH:MM:SS
      final timeRegex = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
      if (timeRegex.hasMatch(timeData)) {
        // Extraire juste HH:MM
        return timeData.length >= 5 ? timeData.substring(0, 5) : timeData;
      }

      // Essayer de parser comme date complète
      try {
        final dateTime = DateTime.parse(timeData);
        return AppointmentsService.formatTime(dateTime);
      } catch (e) {
        return 'Heure invalide';
      }
    } else if (timeData is Map<String, dynamic>) {
      final dateValue = timeData['date'];
      if (dateValue is String) {
        try {
          final dateTime = DateTime.parse(dateValue);
          return AppointmentsService.formatTime(dateTime);
        } catch (e) {
          return 'Heure invalide';
        }
      }
    }
    return 'Heure inconnue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: AppTheme.adaptiveToolbarHeight(context),
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Rendez-vous',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/parametres');
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  image:
                      _userData != null &&
                          _userData!['avatar'] != null &&
                          _userData!['avatar'].toString().isNotEmpty
                      ? DecorationImage(
                          image:
                              _userData!['avatar'].toString().startsWith(
                                'data:',
                              )
                              ? MemoryImage(
                                  base64Decode(
                                    _userData!['avatar'].toString().split(
                                      ',',
                                    )[1],
                                  ),
                                )
                              : NetworkImage(_userData!['avatar'].toString()),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (_userData == null ||
                        _userData!['avatar'] == null ||
                        _userData!['avatar'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF8D3188))
                    : null,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAppointments,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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
                        Icon(Icons.search, color: const Color(0xFF8D3188)),
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

                  Text(
                    'Mes rendez-vous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_getFilteredAppointments().isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun rendez-vous programmé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._getFilteredAppointments().map((appointment) {
                      final doctorName = AppointmentsService.getDoctorName(
                        appointment,
                      );
                      final patientName = AppointmentsService.getPatientName(
                        appointment,
                      );
                      final displayName = _currentUserRole == 'patient'
                          ? doctorName
                          : patientName;
                      final reasonData = appointment['reason'];
                      final reason = reasonData is String
                          ? (reasonData.isNotEmpty
                                ? reasonData
                                : 'Consultation')
                          : 'Consultation';
                      final appointmentDate = appointment['appointmentDate'];
                      final startTimeData = appointment['startTime'];
                      final endTimeData = appointment['endTime'];

                      DateTime startTime;
                      DateTime endTime;

                      // Helper pour parser le temps
                      DateTime parseTime(dynamic timeData) {
                        if (timeData is DateTime) {
                          return timeData;
                        } else if (timeData is String) {
                          // Vérifier si c'est au format HH:MM
                          final timeRegex = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
                          if (timeRegex.hasMatch(timeData)) {
                            // Créer une date avec l'heure
                            final parts = timeData.split(':');
                            final hour = int.parse(parts[0]);
                            final minute = int.parse(parts[1]);
                            final now = DateTime.now();
                            return DateTime(
                              now.year,
                              now.month,
                              now.day,
                              hour,
                              minute,
                            );
                          }
                          // Essayer de parser comme date complète
                          try {
                            return DateTime.parse(timeData);
                          } catch (e) {
                            return DateTime.now();
                          }
                        } else if (timeData is Map<String, dynamic>) {
                          final date = timeData['date'];
                          if (date is String) {
                            try {
                              return DateTime.parse(date);
                            } catch (e) {
                              return DateTime.now();
                            }
                          }
                        }
                        return DateTime.now();
                      }

                      startTime = parseTime(startTimeData);
                      endTime = parseTime(endTimeData);
                      final status = appointment['status'];
                      final statusColor = AppointmentsService.getStatusColor(
                        status,
                      );
                      final formattedDate = AppointmentsService.formatDate(
                        appointmentDate,
                      );
                      final formattedTime =
                          '${AppointmentsService.formatTime(startTime)} - ${AppointmentsService.formatTime(endTime)}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(appointment['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer le rendez-vous'),
                                content: const Text(
                                  'Êtes-vous sûr de vouloir supprimer ce rendez-vous ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Supprimer',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return confirm == true;
                          },
                          onDismissed: (direction) async {
                            try {
                              await AppointmentsService.deleteAppointment(
                                appointment['id'],
                              );
                              if (mounted) {
                                _loadAppointments();
                              }
                            } catch (e) {
                              if (mounted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: GestureDetector(
                            onTap: () => _viewAppointmentDetails(appointment),
                            child: _buildAppointmentCard(
                              displayName,
                              reason,
                              formattedDate,
                              formattedTime,
                              'Cabinet Médical',
                              statusColor,
                              status,
                              appointment,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _createRendezVous,
      backgroundColor: const Color(0xFF8D3188),
      child: const Icon(Icons.calendar_month, color: Colors.white),
    );
  }

  Widget _buildAppointmentCard(
    String doctorName,
    String appointmentType,
    String date,
    String time,
    String location,
    Color color,
    dynamic status,
    Map<String, dynamic> appointment,
  ) {
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointmentType,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        time,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppointmentsService.formatAppointmentStatus(status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editAppointment(appointment);
                  break;
                case 'delete':
                  _deleteAppointment(appointment);
                  break;
                case 'view':
                  _viewAppointmentDetails(appointment);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16),
                    SizedBox(width: 8),
                    Text('Voir détails'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
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

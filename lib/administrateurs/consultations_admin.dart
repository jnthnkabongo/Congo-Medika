import 'package:flutter/material.dart';
import 'package:frontend/services/teleconsultations_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/pages/chats.dart';

class ConsultationsAdmin extends StatefulWidget {
  const ConsultationsAdmin({super.key});

  @override
  State<ConsultationsAdmin> createState() => _ConsultationsAdminState();
}

class _ConsultationsAdminState extends State<ConsultationsAdmin> {
  String _selectedFilter = 'Tous';
  List<Map<String, dynamic>> _teleconsultations = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'Tous',
    'waiting',
    'active',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeleconsultations();
  }

  Future<void> _loadTeleconsultations() async {
    try {
      final teleconsultations =
          await TeleconsultationsService.getDoctorTeleconsultations();
      setState(() {
        _teleconsultations = teleconsultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTeleconsultations {
    if (_selectedFilter == 'Tous') {
      return _teleconsultations;
    }
    return _teleconsultations
        .where((tc) => tc['status'] == _selectedFilter)
        .toList();
  }

  void _openChat(Map<String, dynamic> consultation) async {
    final user = await AuthService.getDonneesUser(AuthService.userKey);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chats(
            roomId: consultation['roomId'],
            teleconsultationId: consultation['id'],
            doctorName: '${user['firstName']} ${user['lastName']}',
          ),
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non renseignée';
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Non renseignée';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'waiting':
        return 'En attente';
      case 'active':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case 'waiting':
        return Icons.pending;
      case 'active':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: const Text(
          'Gestion des consultations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTeleconsultations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune consultation',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTeleconsultations,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: const Color(0xFF8D3188),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ..._filteredTeleconsultations.map((tc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildConsultationCardFromData(tc),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConsultationCardFromData(Map<String, dynamic> teleconsultation) {
    final patient = teleconsultation['patient'];
    final appointment = teleconsultation['appointment'];
    final status = teleconsultation['status'];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIconData(status);
    final statusText = _getStatusIcon(status);

    return InkWell(
      onTap: () {
        _openChat(teleconsultation);
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D3188).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
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
                        '${patient['firstName']} ${patient['lastName']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient['email'],
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(appointment['appointmentDate']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.medical_services, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  appointment['reason'] ?? 'Non renseigné',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

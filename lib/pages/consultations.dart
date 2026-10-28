import 'package:flutter/material.dart';
import 'package:frontend/pages/chats.dart';
import 'package:frontend/services/teleconsultations_service.dart';

class Consultations extends StatefulWidget {
  const Consultations({super.key});

  @override
  State<Consultations> createState() => _ConsultationsState();
}

class _ConsultationsState extends State<Consultations> {
  String? _selectedSpecialty;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _reasonController = TextEditingController();

  final List<String> _specialties = [
    'Médecine générale',
    'Cardiologie',
    'Pédiatrie',
    'Gynécologie',
    'Dermatologie',
    'Neurologie',
    'ORL',
    'Ophtalmologie',
  ];

  final Map<String, List<String>> _doctorsBySpecialty = {
    'Médecine générale': ['Dr. Jean-Pierre Kabongo', 'Dr. Pierre Mwamba'],
    'Cardiologie': ['Dr. Marie-Claire Mbombo'],
    'Pédiatrie': ['Dr. François Mutombo'],
    'Gynécologie': ['Dr. Anne-Marie Lumbu'],
    'Dermatologie': ['Dr. Pauline Nseke'],
    'Neurologie': ['Dr. Claude Mukendi'],
    'ORL': ['Dr. Emmanuel Mutsh'],
    'Ophtalmologie': ['Dr. Suzanne Mbuyi'],
  };

  void _createConsultation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nouvelle consultation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Spécialité',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedSpecialty,
                      items: _specialties.map((specialty) {
                        return DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedSpecialty = value;
                          _selectedDoctor = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Médecin',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDoctor,
                      items: _selectedSpecialty != null
                          ? _doctorsBySpecialty[_selectedSpecialty!]?.map((
                              doctor,
                            ) {
                              return DropdownMenuItem(
                                value: doctor,
                                child: Text(doctor),
                              );
                            }).toList()
                          : null,
                      onChanged: (value) {
                        setModalState(() {
                          _selectedDoctor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null) {
                          setModalState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Sélectionner une date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  _selectedStartTime = pickedTime;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Heure début',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedStartTime != null
                                    ? _selectedStartTime!.format(context)
                                    : 'Sélectionner',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  _selectedEndTime = pickedTime;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Heure fin',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedEndTime != null
                                    ? _selectedEndTime!.format(context)
                                    : 'Sélectionner',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motif de consultation',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF95057B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Créer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF95057B),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Consultations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Color(0xFF95057B)),
            ),
          ],
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
                color: const Color(0xFF95057B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF95057B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher une consultation...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildConsultationCard(
              'Dr. Jean-Pierre Kabongo',
              'Médecin Généraliste',
              'Aujourd\'hui, 10:30',
              'Confirmé',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),

            _buildConsultationCard(
              'Dr. Marie-Claire Mbombo',
              'Cardiologue',
              'Demain, 14:00',
              'En attente',
              Icons.pending,
              Colors.orange,
            ),
            const SizedBox(height: 12),

            _buildConsultationCard(
              'Dr. François Mutombo',
              'Pédiatre',
              '22 Jan 2026, 09:00',
              'Confirmé',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),

            _buildConsultationCard(
              'Dr. Anne-Marie Lumbu',
              'Dermatologue',
              '25 Jan 2026, 11:30',
              'Programmé',
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 12),

            _buildConsultationCard(
              'Dr. Pierre Mwamba',
              'Médecin Généraliste',
              '28 Jan 2026, 16:00',
              'Annulé',
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _createConsultation();
      },
      backgroundColor: const Color(0xFF95057B),
      child: const Icon(Icons.medical_services_sharp, color: Colors.white),
    );
  }

  Widget _buildConsultationCard(
    String doctorName,
    String specialty,
    String dateTime,
    String status,
    IconData statusIcon,
    Color statusColor,
  ) {
    return InkWell(
      onTap: () async {
        try {
          // Créer une téléconsultation via l'API backend
          // Pour la démo, on utilise des IDs fictifs. Dans une vraie app, ils viendraient de l'API
          final teleconsultation = await TeleconsultationsService.createTeleconsultation(
            appointmentId: 1, // ID fictif pour la démo
            patientId: 1, // ID fictif pour la démo
            doctorId: 1, // ID fictif pour la démo
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chats(
                  roomId: teleconsultation['roomId'],
                  teleconsultationId: teleconsultation['id'],
                  doctorName: doctorName,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF95057B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital,
                color: Color(0xFF95057B),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTime,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

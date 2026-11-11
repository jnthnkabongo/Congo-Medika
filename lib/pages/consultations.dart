import 'package:flutter/material.dart';
import 'package:frontend/pages/chats.dart';
import 'package:frontend/services/teleconsultations_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/doctors_service.dart';
import 'package:frontend/services/appointments_service.dart';
import 'dart:convert';

class Consultations extends StatefulWidget {
  const Consultations({super.key});

  @override
  State<Consultations> createState() => _ConsultationsState();
}

class _ConsultationsState extends State<Consultations> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<Map<String, dynamic>> _teleconsultations = [];
  bool _isLoadingDoctors = true;
  Map<String, dynamic>? _userData;

  // Variables pour le modal de rendez-vous
  Map<String, dynamic>? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isCreatingAppointment = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDoctors();
    _loadTeleconsultations();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getDonneesUser(AuthService.userKey);
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _getInitials(String? firstName, String? lastName) {
    final firstInitial = (firstName?.isNotEmpty == true)
        ? firstName![0].toUpperCase()
        : '';
    final lastInitial = (lastName?.isNotEmpty == true)
        ? lastName![0].toUpperCase()
        : '';
    return '$firstInitial$lastInitial';
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await DoctorsService.getDoctors();
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDoctors = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadTeleconsultations() async {
    try {
      final teleconsultations =
          await TeleconsultationsService.getPatientTeleconsultations();
      setState(() {
        _teleconsultations = teleconsultations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des consultations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _doctors;
      } else {
        _filteredDoctors = _doctors.where((doctor) {
          final fullName = '${doctor['firstName']} ${doctor['lastName']}'
              .toLowerCase();
          final email = doctor['email'].toLowerCase();
          final specialty = (doctor['specialty'] ?? '').toLowerCase();
          return fullName.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase()) ||
              specialty.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _openChatForDoctor(Map<String, dynamic> doctor) {
    // Chercher une téléconsultation existante avec ce médecin
    final existingTeleconsultation = _teleconsultations
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (tc) => tc != null && tc['doctorId'] == doctor['id'],
          orElse: () => null,
        );

    if (existingTeleconsultation != null &&
        existingTeleconsultation.isNotEmpty) {
      // Ouvrir le chat existant
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chats(
            roomId: existingTeleconsultation['roomId'],
            teleconsultationId: existingTeleconsultation['id'],
            doctorName: 'Dr. ${doctor['firstName']} ${doctor['lastName']}',
            doctorId: doctor['id'] is String
                ? int.parse(doctor['id'])
                : doctor['id'],
            patientId: existingTeleconsultation['patientId'] is String
                ? int.parse(existingTeleconsultation['patientId'])
                : existingTeleconsultation['patientId'],
          ),
        ),
      );
    } else {
      // Pas de téléconsultation en cours, informer l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucune consultation en cours avec Dr. ${doctor['firstName']} ${doctor['lastName']}. Utilisez le bouton + pour programmer un rendez-vous.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAppointmentForm() {
    // Réinitialiser les variables du modal
    setState(() {
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _isCreatingAppointment = false;
      _reasonController.clear();
    });

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
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prendre rendez-vous',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Contenu
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dropdown pour sélectionner le médecin
                          DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: const InputDecoration(
                              labelText: 'Médecin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color(0xFF8D3188),
                              ),
                            ),
                            initialValue: _selectedDoctor,
                            hint: const Text('Sélectionner un médecin'),
                            items: _doctors.map((doctor) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: doctor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${doctor['firstName']} ${doctor['lastName']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (doctor['specialty'] != null)
                                      Text(
                                        doctor['specialty'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                _selectedDoctor = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Date picker
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

                          // Time pickers
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

                          // Reason
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
                              onPressed: _isCreatingAppointment
                                  ? null
                                  : () async {
                                      if (_selectedDoctor == null ||
                                          _selectedDate == null ||
                                          _selectedStartTime == null ||
                                          _selectedEndTime == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Veuillez remplir tous les champs',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Validation des horaires
                                      final startMinutes =
                                          _selectedStartTime!.hour * 60 +
                                          _selectedStartTime!.minute;
                                      final endMinutes =
                                          _selectedEndTime!.hour * 60 +
                                          _selectedEndTime!.minute;
                                      if (endMinutes <= startMinutes) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'L\'heure de fin doit être après l\'heure de début',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setModalState(() {
                                        _isCreatingAppointment = true;
                                      });

                                      try {
                                        final user =
                                            await AuthService.getDonneesUser(
                                              AuthService.userKey,
                                            );
                                        final patientId =
                                            user?['id'] ?? user?['sub'];

                                        if (patientId == null) {
                                          throw Exception(
                                            'Utilisateur non connecté',
                                          );
                                        }

                                        // Créer l'appointment
                                        final appointment =
                                            await AppointmentsService.createAppointment(
                                              doctorId: int.parse(
                                                _selectedDoctor!['id']
                                                    .toString(),
                                              ),
                                              appointmentDate:
                                                  '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                                              startTime:
                                                  '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}:00',
                                              endTime:
                                                  '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}:00',
                                              reason:
                                                  _reasonController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : _reasonController.text
                                                        .trim(),
                                            );

                                        // Créer la téléconsultation
                                        final teleconsultation =
                                            await TeleconsultationsService.createTeleconsultation(
                                              appointmentId: int.parse(
                                                appointment['id'],
                                              ),
                                              patientId: int.parse(
                                                patientId.toString(),
                                              ),
                                              doctorId: int.parse(
                                                _selectedDoctor!['id']
                                                    .toString(),
                                              ),
                                            );

                                        if (mounted) {
                                          Navigator.pop(context);
                                          if (mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Chats(
                                                  roomId:
                                                      teleconsultation['roomId'],
                                                  teleconsultationId:
                                                      teleconsultation['id'],
                                                  doctorName:
                                                      'Dr. ${_selectedDoctor!['firstName']} ${_selectedDoctor!['lastName']}',
                                                  doctorId:
                                                      _selectedDoctor!['id']
                                                          is String
                                                      ? int.parse(
                                                          _selectedDoctor!['id'],
                                                        )
                                                      : _selectedDoctor!['id'],
                                                  patientId: patientId is String
                                                      ? int.parse(patientId)
                                                      : patientId,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setModalState(() {
                                          _isCreatingAppointment = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8D3188),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCreatingAppointment
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Créer et démarrer la consultation',
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
                  ),
                ],
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nos médecins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                // Naviguer vers la page profil ou paramètres
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
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8D3188)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: _filterDoctors,
            ),
          ),
          // Liste des médecins
          Expanded(
            child: _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun médecin trouvé',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDoctors,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _filteredDoctors[index];
                        return _buildDoctorCard(doctor);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAppointmentForm,
        backgroundColor: const Color(0xFF8D3188),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openChatForDoctor(doctor),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF8D3188),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                _getInitials(doctor['firstName'], doctor['lastName']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            'Dr. ${doctor['firstName']} ${doctor['lastName']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doctor['specialty'] != null)
                Text(
                  doctor['specialty'],
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              const SizedBox(height: 4),
              Text(
                doctor['email'],
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: const Icon(Icons.chat, color: Color(0xFF8D3188)),
        ),
      ),
    );
  }
}

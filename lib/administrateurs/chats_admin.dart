import 'package:flutter/material.dart';
import 'package:frontend/services/patients_service.dart';
import 'package:frontend/services/teleconsultations_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/pages/chats.dart';
import '../theme/app_theme.dart';

class ChatsAdmin extends StatefulWidget {
  const ChatsAdmin({super.key});

  @override
  State<ChatsAdmin> createState() => _ChatsAdminState();
}

class _ChatsAdminState extends State<ChatsAdmin> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoadingPatients = true;
  bool _isCreatingTeleconsultation = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await PatientsService.getPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoadingPatients = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPatients = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final fullName = '${patient['firstName']} ${patient['lastName']}'
              .toLowerCase();
          final email = patient['email'].toLowerCase();
          return fullName.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _startConversation(Map<String, dynamic> patient) async {
    setState(() {
      _isCreatingTeleconsultation = true;
    });

    try {
      // Récupérer l'ID du médecin connecté
      final user = await AuthService.getDonneesUser(AuthService.userKey);
      final doctorId = user?['id'] ?? user?['sub'];

      if (doctorId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer une téléconsultation
      final teleconsultation =
          await TeleconsultationsService.createTeleconsultation(
            appointmentId: 1, // ID fictif pour la démo
            patientId: int.parse(patient['id'].toString()),
            doctorId: int.parse(doctorId.toString()),
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chats(
              roomId: teleconsultation['roomId'],
              teleconsultationId: teleconsultation['id'],
              doctorName: '${user['firstName']} ${user['lastName']}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isCreatingTeleconsultation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: AppTheme.adaptiveToolbarHeight(context),
        backgroundColor: const Color(0xFF8D3188),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Sélectionner un patient',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                hintText: 'Rechercher un patient...',
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
              onChanged: _filterPatients,
            ),
          ),
          // Liste des patients
          Expanded(
            child: _isLoadingPatients
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun patient trouvé',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      return _buildPatientCard(patient);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              '${patient['firstName'][0]}${patient['lastName'][0]}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '${patient['firstName']} ${patient['lastName']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient['email'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              patient['phone'] ?? 'Non renseigné',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _isCreatingTeleconsultation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.chat, color: Color(0xFF8D3188)),
                onPressed: () => _startConversation(patient),
              ),
      ),
    );
  }
}

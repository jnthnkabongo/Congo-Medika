import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/appointments_service.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  List<Map<String, dynamic>> _todaysAppointments = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si le token existe
      final token = await AuthService.getToken();

      if (token == null) {
        // Pas de token, rediriger vers login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Récupérer les données utilisateur
      final userData = await AuthService.getDonneesUser(AuthService.userKey);

      if (userData == null) {
        // Données utilisateur non trouvées
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Données utilisateur non trouvées. Veuillez vous reconnecter.';
        });

        // Rediriger vers login après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
        return;
      }

      // Charger les rendez-vous du jour
      await _loadTodaysAppointments();

      setState(() {
        _isLoading = false;
        _userData = userData;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });
    }
  }

  Future<void> _loadTodaysAppointments() async {
    try {
      final appointments = await AppointmentsService.getUserAppointments();
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Filtrer les rendez-vous du jour
      _todaysAppointments = appointments.where((apt) {
        try {
          final aptDate = apt['appointmentDate']?.toString() ?? '';
          // Essayer de parser la date pour être sûr
          if (aptDate.contains('T')) {
            final datePart = aptDate.split('T')[0];
            return datePart == todayStr;
          }
          return aptDate.startsWith(todayStr) || aptDate.contains(todayStr);
        } catch (e) {
          return false;
        }
      }).toList();

      // Trier par heure de début
      _todaysAppointments.sort((a, b) {
        final timeA = a['startTime']?.toString() ?? '';
        final timeB = b['startTime']?.toString() ?? '';
        return timeA.compareTo(timeB);
      });
    } catch (e) {
      // Erreur silencieuse pour ne pas bloquer le dashboard
      _todaysAppointments = [];
    }
  }

  void _createUrgence() {
    // TODO: Implémenter la logique de création d'urgence

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: Center(child: Text('Créer une urgence')),
        );
      },
    );
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
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

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

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkAuthAndLoadData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D3188), Color(0xFF8D3188)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          right: 50,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.wb_sunny_outlined,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        size: 40,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Bienvenu(e) sur Congo Medika !',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        'Bonjour,',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? 'Utilisateur'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Votre santé, notre priorité',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Card horaire du jour - Style Teams
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF8D3188,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF8D3188),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Aujourd\'hui',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    Text(
                                      _formatDate(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
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
                                  color: Color(
                                    0xFF8D3188,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_todaysAppointments.length} RDV',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8D3188),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        // Liste des rendez-vous
                        if (_todaysAppointments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun rendez-vous aujourd\'hui',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._todaysAppointments.map((apt) {
                            final startTime = _formatTime(apt['startTime']);
                            final endTime = _formatTime(apt['endTime']);
                            final reason =
                                apt['reason']?.toString() ?? 'Rendez-vous';
                            final status =
                                apt['status']?.toString() ?? 'pending';
                            final doctor =
                                apt['doctor'] as Map<String, dynamic>?;
                            final doctorName = doctor != null
                                ? '${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'
                                      .trim()
                                : 'Médecin';
                            final patient =
                                apt['patient'] as Map<String, dynamic>?;
                            final patientName = patient != null
                                ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                                      .trim()
                                : 'Patient';
                            final statusColor = _getStatusColor(status);
                            final statusBgColor = statusColor.withValues(
                              alpha: 0.1,
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Timeline indicator
                                    Column(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Container(
                                          width: 2,
                                          height: 40,
                                          color: Colors.grey[300],
                                        ),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Time column
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 70,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            startTime,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[900],
                                            ),
                                          ),
                                          Text(
                                            endTime,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reason,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[900],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$doctorName • $patientName',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatStatus(status),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Implémenter la logique de création de consultation
        _createUrgence();
      },
      backgroundColor: const Color(0xFF8D3188),
      child: const Icon(Icons.emergency, color: Colors.white),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirme':
        return Colors.green;
      case 'pending':
      case 'en_attente':
        return Colors.orange;
      case 'cancelled':
      case 'annule':
        return Colors.red;
      case 'completed':
      case 'termine':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirme':
        return 'Confirmé';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      case 'cancelled':
      case 'annule':
        return 'Annulé';
      case 'completed':
      case 'termine':
        return 'Terminé';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';

    // Si c'est déjà une string au format HH:MM
    if (time is String) {
      // Vérifier si c'est au format HH:MM ou HH:MM:SS
      final timeRegex = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
      if (timeRegex.hasMatch(time)) {
        // Extraire juste HH:MM
        return time.length >= 5 ? time.substring(0, 5) : time;
      }

      // Essayer de parser comme timestamp
      final parsed = int.tryParse(time);
      if (parsed != null) {
        return _formatTime(parsed);
      }

      return time;
    }

    // Si c'est un nombre (timestamp Unix)
    if (time is int || time is double) {
      final timestamp = time is int ? time : time.toInt();
      final isMilliseconds = timestamp > 1000000000000;
      final dateTime = isMilliseconds
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    // Si c'est un DateTime
    if (time is DateTime) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return '--:--';
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

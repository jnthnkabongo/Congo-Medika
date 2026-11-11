import 'package:flutter/material.dart';
import 'package:frontend/services/calls_service.dart';
import 'package:frontend/services/auth_service.dart';

class JournalsAdmin extends StatefulWidget {
  const JournalsAdmin({super.key});

  @override
  State<JournalsAdmin> createState() => _JournalsAdminState();
}

class _JournalsAdminState extends State<JournalsAdmin> {
  List<Map<String, dynamic>> _calls = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  String? _currentUserRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthService.getDonneesUser(AuthService.userKey);
      if (mounted) {
        setState(() {
          _currentUserRole = user?['role']?.toString();
          _currentUserId = user?['id']?.toString();
        });
      }

      final calls = await CallsService.getAllCalls();
      if (mounted) {
        setState(() {
          _calls = calls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCalls() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _calls;
    }

    return _calls.where((call) {
      final contactName = CallsService.getContactName(
        call,
        _currentUserRole,
        _currentUserId,
      );
      return contactName.toLowerCase().contains(_searchQuery!.toLowerCase());
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupCallsByDate(
    List<Map<String, dynamic>> calls,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final call in calls) {
      final createdAtData = call['createdAt'];
      DateTime? createdAt;
      if (createdAtData is String) {
        createdAt = DateTime.tryParse(createdAtData);
      }
      if (createdAt == null) continue;

      final callDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      String dateLabel;
      if (callDate == today) {
        dateLabel = 'Aujourd\'hui';
      } else if (callDate == yesterday) {
        dateLabel = 'Hier';
      } else {
        dateLabel =
            '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
      }

      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(call);
    }

    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return months[month - 1];
  }

  String _formatTime(dynamic dateTimeStr) {
    if (dateTimeStr is! String) return '--:--';
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return '--:--';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCallIcon(Map<String, dynamic> call) {
    final status = call['status'];
    if (status == 'missed' || status == 'rejected' || status == 'failed') {
      return Icons.call_missed;
    }
    final direction = CallsService.getCallDirection(
      call,
      _currentUserRole,
      _currentUserId,
    );
    return direction == 'Appel sortant' ? Icons.call_made : Icons.call_received;
  }

  Color _getStatusColor(dynamic status) {
    if (status == null) return Colors.grey;
    switch (status.toString().toLowerCase()) {
      case 'calling':
      case 'active':
        return Colors.blue;
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'missed':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
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
          'Journal d\'appels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildCallsJournal(),
    );
  }

  Widget _buildCallsJournal() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCalls,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final filteredCalls = _getFilteredCalls();

    return SingleChildScrollView(
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
                      hintText: 'Rechercher dans le journal...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (filteredCalls.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_disabled,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun appel enregistré',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._groupCallsByDate(filteredCalls).entries.map(
              (entry) => _buildJournalSection(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildJournalSection(String date, List<Map<String, dynamic>> calls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        ...calls.map((call) => _buildCallCard(call)),
      ],
    );
  }

  Widget _buildCallCard(Map<String, dynamic> call) {
    final contactName = CallsService.getContactName(
      call,
      _currentUserRole,
      _currentUserId,
    );
    final callDirection = CallsService.getCallDirection(
      call,
      _currentUserRole,
      _currentUserId,
    );
    final status = CallsService.formatCallStatus(call['status']);
    final callIcon = _getCallIcon(call);
    final statusColor = _getStatusColor(call['status']);
    final time = _formatTime(call['createdAt']);
    final duration = CallsService.formatDuration(call['duration']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(callIcon, color: const Color(0xFF8D3188), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$callDirection • ${call['type'] == 'video' ? 'Vidéo' : 'Audio'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    if (duration != '-')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.phone, color: statusColor, size: 16),
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
    );
  }
}

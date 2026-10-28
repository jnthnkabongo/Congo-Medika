import 'package:flutter/material.dart';

class JournalsAdmin extends StatefulWidget {
  const JournalsAdmin({super.key});

  @override
  State<JournalsAdmin> createState() => _JournalsAdminState();
}

class _JournalsAdminState extends State<JournalsAdmin> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF95057B),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Appels', 0),
                _buildTabButton('Messages', 1),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildCallsJournal()
                : _buildMessagesJournal(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF95057B).withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF95057B) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF95057B) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildCallsJournal() {
    return SingleChildScrollView(
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
                const Icon(Icons.search, color: Color(0xFF95057B)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
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

          _buildJournalSection('Aujourd\'hui', [
            _buildCallCard(
              'Dr. Jean-Pierre Kabongo',
              'Appel entrant',
              '10:30',
              '15 min',
              'Répondu',
              Icons.call_received,
              Colors.green,
            ),
            _buildCallCard(
              'Patient: Marie Lumbu',
              'Appel sortant',
              '09:15',
              '8 min',
              'Répondu',
              Icons.call_made,
              Colors.blue,
            ),
          ]),
          const SizedBox(height: 20),

          _buildJournalSection('Hier', [
            _buildCallCard(
              'Service Urgences',
              'Appel entrant',
              '22:45',
              '3 min',
              'Manqué',
              Icons.call_missed,
              Colors.red,
            ),
            _buildCallCard(
              'Pharmacie Centrale',
              'Appel sortant',
              '14:30',
              '5 min',
              'Répondu',
              Icons.call_made,
              Colors.blue,
            ),
            _buildCallCard(
              'Dr. François Mutombo',
              'Appel entrant',
              '11:00',
              '12 min',
              'Répondu',
              Icons.call_received,
              Colors.green,
            ),
          ]),
          const SizedBox(height: 20),

          _buildJournalSection('20 Jan 2026', [
            _buildCallCard(
              'Dr. Anne-Marie Lumbu',
              'Appel entrant',
              '16:00',
              '20 min',
              'Répondu',
              Icons.call_received,
              Colors.green,
            ),
            _buildCallCard(
              'Patient: Pierre Mwamba',
              'Appel entrant',
              '11:20',
              '-',
              'Manqué',
              Icons.call_missed,
              Colors.red,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMessagesJournal() {
    return SingleChildScrollView(
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
                const Icon(Icons.search, color: Color(0xFF95057B)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un message...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildMessageCard(
            'Dr. Jean-Pierre Kabongo',
            'Pouvez-vous confirmer le rendez-vous de demain?',
            '10:30',
            '2 messages',
            Icons.local_hospital,
            const Color(0xFF95057B),
          ),
          const SizedBox(height: 12),

          _buildMessageCard(
            'Patient: Marie Lumbu',
            'Merci pour la consultation d\'hier.',
            '09:15',
            '1 message',
            Icons.person,
            Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildMessageCard(
            'Dr. Marie-Claire Mbombo',
            'Les résultats sont prêts.',
            'Hier',
            '5 messages',
            Icons.local_hospital,
            const Color(0xFF95057B),
          ),
          const SizedBox(height: 12),

          _buildMessageCard(
            'Service Pharmacie',
            'Livraison confirmée pour ce matin.',
            'Hier',
            '3 messages',
            Icons.medical_services,
            Colors.green,
          ),
          const SizedBox(height: 12),

          _buildMessageCard(
            'Patient: Pierre Mwamba',
            'Je voudrais prendre un nouveau rendez-vous.',
            '20 Jan',
            '1 message',
            Icons.person,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildJournalSection(String date, List<Widget> calls) {
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
        ...calls,
      ],
    );
  }

  Widget _buildCallCard(
    String contactName,
    String callType,
    String time,
    String duration,
    String status,
    IconData callIcon,
    Color statusColor,
  ) {
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
              color: const Color(0xFF95057B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(callIcon, color: const Color(0xFF95057B), size: 28),
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
                  callType,
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

  Widget _buildMessageCard(
    String senderName,
    String lastMessage,
    String time,
    String messageCount,
    IconData icon,
    Color color,
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF95057B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        messageCount,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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

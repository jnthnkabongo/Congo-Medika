import 'package:flutter/material.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
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
              'Journal d\'appels',
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

            // Text(
            //   'Journal d\'appels',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.grey[800],
            //   ),
            // ),
            const SizedBox(height: 16),

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
                'Dr. Marie-Claire Mbombo',
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
                'Inconnu',
                'Appel entrant',
                '11:20',
                '-',
                'Manqué',
                Icons.call_missed,
                Colors.red,
              ),
            ]),
            const SizedBox(height: 20),

            _buildJournalSection('19 Jan 2026', [
              _buildCallCard(
                'Laboratoire',
                'Appel sortant',
                '15:30',
                '7 min',
                'Répondu',
                Icons.call_made,
                Colors.blue,
              ),
              _buildCallCard(
                'Dr. Pierre Mwamba',
                'Appel entrant',
                '09:45',
                '10 min',
                'Répondu',
                Icons.call_received,
                Colors.green,
              ),
            ]),
          ],
        ),
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
}

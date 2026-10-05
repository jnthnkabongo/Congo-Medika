import 'package:flutter/material.dart';
import 'package:frontend/pages/chats.dart';

class Consultations extends StatefulWidget {
  const Consultations({super.key});

  @override
  State<Consultations> createState() => _ConsultationsState();
}

class _ConsultationsState extends State<Consultations> {
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

            // Text(
            //   'Mes consultations',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.grey[800],
            //   ),
            // ),
            const SizedBox(height: 16),

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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Chats()),
        );
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

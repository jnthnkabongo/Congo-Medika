import 'package:flutter/material.dart';

class Calendriers extends StatefulWidget {
  const Calendriers({super.key});

  @override
  State<Calendriers> createState() => _CalendrierState();
}

class _CalendrierState extends State<Calendriers> {
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
              'Calendrier',
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            _buildAppointmentCard(
              'Dr. Jean-Pierre Kabongo',
              'Consultation générale',
              'Aujourd\'hui',
              '10:30 - 11:00',
              'Cabinet Médical',
              Colors.green,
            ),
            const SizedBox(height: 12),

            _buildAppointmentCard(
              'Dr. Marie-Claire Mbombo',
              'Examen cardiaque',
              'Demain',
              '14:00 - 15:00',
              'Hôpital Central',
              Colors.blue,
            ),
            const SizedBox(height: 12),

            _buildAppointmentCard(
              'Dr. François Mutombo',
              'Vaccination',
              '22 Jan 2026',
              '09:00 - 09:30',
              'Centre de Santé',
              Colors.orange,
            ),
            const SizedBox(height: 12),

            _buildAppointmentCard(
              'Dr. Anne-Marie Lumbu',
              'Suivi dermatologique',
              '25 Jan 2026',
              '11:30 - 12:00',
              'Cabinet Dermatologie',
              Colors.purple,
            ),
            const SizedBox(height: 12),

            _buildAppointmentCard(
              'Dr. Pierre Mwamba',
              'Bilan de santé',
              '28 Jan 2026',
              '16:00 - 17:00',
              'Polyclinique',
              Colors.teal,
            ),
            const SizedBox(height: 12),

            _buildAppointmentCard(
              'Laboratoire',
              'Analyses sanguines',
              '30 Jan 2026',
              '08:00 - 08:30',
              'Laboratoire Central',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    String doctorName,
    String appointmentType,
    String date,
    String time,
    String location,
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
            child: Icon(Icons.calendar_today, color: color, size: 28),
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
                  appointmentType,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                Icon(Icons.location_on, color: color, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

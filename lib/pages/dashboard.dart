import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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
              'Dashboard',
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
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF95057B), Color(0xFF95057B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 20,
                    offset: Offset(0, 10),
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
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 40,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bienvenu(e) sur Congo Medika !',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Text(
                                  'Bonjour,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  ' Utilisateur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Votre santé, notre priorité',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
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

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Consultations',
                    '12',
                    Icons.local_hospital,
                    Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Téléconsultation',
                    '8',
                    Icons.video_call,
                    Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Rendez-vous',
                    '5',
                    Icons.calendar_today,
                    Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Médicaments livrés',
                    '23',
                    Icons.medical_services,
                    Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            Text(
              'Dernières activités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            Container(
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
                children: [
                  _buildActivityItem(
                    'Consultation avec Dr. Kabongo',
                    'Aujourd\'hui, 10:30',
                    Icons.local_hospital,
                    Colors.purple,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActivityItem(
                    'Livraison de médicaments',
                    'Hier, 14:00',
                    Icons.delivery_dining,
                    Colors.purple,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActivityItem(
                    'Téléconsultation terminée',
                    '20 Jan 2026, 09:00',
                    Icons.video_call,
                    Colors.purple,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActivityItem(
                    'Rendez-vous confirmé',
                    '18 Jan 2026, 16:30',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF95057B),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
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

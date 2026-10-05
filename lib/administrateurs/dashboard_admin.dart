import 'package:flutter/material.dart';

class DashboardAdmins extends StatefulWidget {
  const DashboardAdmins({super.key});

  @override
  State<DashboardAdmins> createState() => _DashboardAdminsState();
}

class _DashboardAdminsState extends State<DashboardAdmins> {
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
      body: Center(child: Text('Dashboard administrateur')),
    );
  }
}

import 'package:flutter/material.dart';

class ParametresAdmin extends StatefulWidget {
  const ParametresAdmin({super.key});

  @override
  State<ParametresAdmin> createState() => _ParametresAdminState();
}

class _ParametresAdminState extends State<ParametresAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF95057B),
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(child: Text('Paramètres administrateur')),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Appels extends StatefulWidget {
  const Appels({super.key});

  @override
  State<Appels> createState() => _AppelsState();
}

class _AppelsState extends State<Appels> {
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
                'Appels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Color(0xFF8D3188)),
            ),
          ],
        ),
      ),
      body: Center(child: Text('Appels')),
    );
  }
}

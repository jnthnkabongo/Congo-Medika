// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import '../services/websocket_service.dart';

// class ChatExampleScreen extends StatefulWidget {
//   const ChatExampleScreen({super.key});

//   @override
//   State<ChatExampleScreen> createState() => _ChatExampleScreenState();
// }

// class _ChatExampleScreenState extends State<ChatExampleScreen> {
//   final AuthService _authService = AuthService();
//   final WebSocketService _wsService = WebSocketService();

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _codeController = TextEditingController();
//   final _messageController = TextEditingController();
//   final _roomIdController = TextEditingController();

//   String? _challengeId;
//   String? _accessToken;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isConnected = false;
//   String _status = 'Déconnecté';

//   @override
//   void initState() {
//     super.initState();
//     _setupWebSocketListeners();
//   }

//   void _setupWebSocketListeners() {
//     _wsService.onConnectionChanged.listen((connected) {
//       setState(() {
//         _isConnected = connected;
//         _status = connected ? 'Connecté' : 'Déconnecté';
//       });
//     });

//     _wsService.onMessage.listen((message) {
//       setState(() {
//         _messages.add(message);
//       });
//     });

//     _wsService.onError.listen((error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $error')),
//       );
//     });

//     _wsService.onRoomJoined.listen((roomId) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Room rejointe: $roomId')),
//       );
//     });
//   }

//   Future<void> _register() async {
//     try {
//       final result = await _authService.register(
//         email: _emailController.text,
//         password: _passwordController.text,
//         firstName: 'Test',
//         lastName: 'User',
//         phone: '+1234567890',
//         role: 'patient',
//         gender: 'male',
//       );
//       setState(() {
//         _challengeId = result['challengeId'];
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Inscription réussie. Vérifiez votre email.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   Future<void> _verifyEmail() async {
//     if (_challengeId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('D\'abord, inscrivez-vous')),
//       );
//       return;
//     }
//     try {
//       await _authService.verifyEmail(
//         challengeId: _challengeId!,
//         code: _codeController.text,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Email vérifié avec succès')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   Future<void> _login() async {
//     try {
//       final result = await _authService.login(
//         email: _emailController.text,
//         password: _passwordController.text,
//         role: 'patient',
//       );
//       setState(() {
//         _challengeId = result['challengeId'];
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Code de connexion envoyé')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   Future<void> _verifyLoginCode() async {
//     if (_challengeId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('D\'abord, connectez-vous')),
//       );
//       return;
//     }
//     try {
//       final result = await _authService.verifyLoginCode(
//         challengeId: _challengeId!,
//         code: _codeController.text,
//       );
//       setState(() {
//         _accessToken = result['accessToken'];
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Connexion réussie')),
//       );
//       // Connecter automatiquement au WebSocket
//       await _wsService.connect(result['accessToken']);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   void _joinRoom() {
//     try {
//       _wsService.joinRoom(_roomIdController.text);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   void _sendMessage() {
//     try {
//       _wsService.sendMessage(
//         roomId: _roomIdController.text,
//         content: _messageController.text,
//       );
//       _messageController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _wsService.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _codeController.dispose();
//     _messageController.dispose();
//     _roomIdController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Test Auth & WebSocket'),
//         backgroundColor: Colors.blue,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Status WebSocket
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _isConnected ? Colors.green[100] : Colors.red[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 'WebSocket: $_status',
//                 style: TextStyle(
//                   color: _isConnected ? Colors.green[900] : Colors.red[900],
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Inscription
//             const Text('Inscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(labelText: 'Mot de passe'),
//               obscureText: true,
//             ),
//             ElevatedButton(
//               onPressed: _register,
//               child: const Text('S\'inscrire'),
//             ),
//             const SizedBox(height: 20),

//             // Vérification email
//             TextField(
//               controller: _codeController,
//               decoration: const InputDecoration(labelText: 'Code de vérification'),
//             ),
//             ElevatedButton(
//               onPressed: _verifyEmail,
//               child: const Text('Vérifier l\'email'),
//             ),
//             const SizedBox(height: 20),

//             // Connexion
//             const Text('Connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ElevatedButton(
//               onPressed: _login,
//               child: const Text('Se connecter'),
//             ),
//             ElevatedButton(
//               onPressed: _verifyLoginCode,
//               child: const Text('Vérifier le code de connexion'),
//             ),
//             const SizedBox(height: 20),

//             // WebSocket
//             const Text('WebSocket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             TextField(
//               controller: _roomIdController,
//               decoration: const InputDecoration(labelText: 'Room ID'),
//             ),
//             ElevatedButton(
//               onPressed: _joinRoom,
//               child: const Text('Rejoindre la room'),
//             ),
//             TextField(
//               controller: _messageController,
//               decoration: const InputDecoration(labelText: 'Message'),
//             ),
//             ElevatedButton(
//               onPressed: _sendMessage,
//               child: const Text('Envoyer le message'),
//             ),
//             const SizedBox(height: 20),

//             // Messages
//             const Text('Messages reçus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: _messages.isEmpty
//                   ? const Center(child: Text('Aucun message'))
//                   : ListView.builder(
//                       itemCount: _messages.length,
//                       itemBuilder: (context, index) {
//                         final msg = _messages[index];
//                         return ListTile(
//                           title: Text(msg['content'] ?? '[Audio]'),
//                           subtitle: Text('${msg['senderType']} - ${msg['createdAt']}'),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

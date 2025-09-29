import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ControlaSchool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessIcon(),
              const SizedBox(height: 30),
              _buildWelcomeText(),
              const SizedBox(height: 40),
              const FeatureCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 60,
        color: Colors.green,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          '¡Bienvenido a ControlaSchool!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Has iniciado sesión correctamente',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
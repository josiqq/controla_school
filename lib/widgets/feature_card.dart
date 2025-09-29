import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFeatureTile(
              icon: Icons.check,
              title: 'Splash Screen',
              subtitle: 'Animación de inicio',
            ),
            _buildFeatureTile(
              icon: Icons.check,
              title: 'Login',
              subtitle: 'Sistema de autenticación',
            ),
            _buildFeatureTile(
              icon: Icons.check,
              title: 'Autenticación Local',
              subtitle: 'Biométrica o PIN del dispositivo',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
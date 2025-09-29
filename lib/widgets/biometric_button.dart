import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class BiometricButton extends StatelessWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const BiometricButton({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  Future<void> _authenticate() async {
    final authService = AuthService();
    final success = await authService.authenticateWithBiometric();
    
    if (success) {
      onSuccess();
    } else {
      onError('Autenticación fallida');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _authenticate,
      icon: const Icon(Icons.fingerprint),
      label: const Text('Autenticación Biométrica'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
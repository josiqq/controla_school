import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/login_form.dart';
import '../widgets/biometric_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authService.checkBiometricAvailability();
    setState(() {
      _biometricAvailable = isAvailable;
    });
  }

  void _handleLoginSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 30),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildLoginCard(),
                  const SizedBox(height: 20),
                  _buildRegisterLink(),
                  const SizedBox(height: 10),
                  _buildTestCredentials(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        size: 50,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inicia sesión para continuar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          LoginForm(
            onLoginSuccess: _handleLoginSuccess,
            onShowMessage: _showMessage,
          ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('O'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            BiometricButton(
              onSuccess: _handleLoginSuccess,
              onError: _showMessage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No tienes cuenta? ',
          style: TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: () => _showMessage('Función no implementada'),
          child: const Text(
            'Regístrate',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCredentials() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Text(
            'Credenciales de prueba:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Email: admin@school.com',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Contraseña: 123456',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

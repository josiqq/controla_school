import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Esperar un mínimo de tiempo para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // Verificar si hay un usuario autenticado
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        // Usuario ya autenticado, verificar si tiene biometría habilitada
        final biometricEnabled = await _authService.isBiometricEnabled();
        final biometricAvailable = await _authService.checkBiometricAvailability();
        
        if (biometricEnabled && biometricAvailable) {
          // Intentar autenticación biométrica
          _showBiometricPrompt();
        } else {
          // Ir directo a home si no hay biometría configurada
          _navigateToHome();
        }
      } else {
        // No hay usuario autenticado, ir al login
        _navigateToLogin();
      }
    } catch (e) {
      // En caso de error, ir al login
      _navigateToLogin();
    }
  }

  Future<void> _showBiometricPrompt() async {
    // Mostrar un diálogo indicando que se va a usar biometría
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Autenticación Biométrica'),
          content: const Text('Usa tu huella dactilar o Face ID para continuar'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin();
              },
              child: const Text('Usar contraseña'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authenticateWithBiometric();
              },
              child: const Text('Autenticar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _authenticateWithBiometric() async {
    final result = await _authService.loginWithBiometric();
    
    if (result['success']) {
      _navigateToHome();
    } else {
      // Si falla la biometría, mostrar opción de usar contraseña
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Autenticación fallida'),
            action: SnackBarAction(
              label: 'Usar contraseña',
              onPressed: _navigateToLogin,
            ),
          ),
        );
        
        // Después de 2 segundos, ir al login si no se ha navegado
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _navigateToLogin();
          }
        });
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 10),
                  _buildSubtitle(),
                  const SizedBox(height: 60),
                  _buildLoadingIndicator(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Transform.rotate(
        angle: _rotationAnimation.value * 0,
        child: Container(
          width: AppConstants.logoSize,
          height: AppConstants.logoSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: AppConstants.iconSize,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: const Text(
        'ControlaSchool',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: const Text(
        'Gestión Educativa',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white70,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: const SizedBox(
        width: 50,
        height: 50,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
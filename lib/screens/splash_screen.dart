import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
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
    _checkFirstTimeAndAuth();
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

  Future<void> _checkFirstTimeAndAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Si es la primera vez, mostrar onboarding
      if (!onboardingCompleted) {
        _navigateToOnboarding();
        return;
      }

      // Si no es la primera vez, verificar autenticación
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        final biometricEnabled = await _authService.isBiometricEnabled();
        final biometricAvailable = await _authService.checkBiometricAvailability();
        
        if (biometricEnabled && biometricAvailable) {
          _showBiometricPrompt();
        } else {
          _navigateToHome();
        }
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToOnboarding() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _showBiometricPrompt() async {
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
                color: Colors.black.withValues(alpha: 0.2),
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
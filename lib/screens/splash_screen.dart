import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../config/constants.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToLogin();
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

  void _navigateToLogin() {
    Timer(AppConstants.splashDuration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
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
      child: Text(
        'Gestión Educativa',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
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

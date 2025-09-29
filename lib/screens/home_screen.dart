import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/section_title.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../config/theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  void _onNavItemTapped(int index) {
    if (index == _currentNavIndex) return;
    
    setState(() => _currentNavIndex = index);
    
    // Mostrar mensaje para pestañas en desarrollo
    if (index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Próximamente disponible'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      // Volver al inicio después de un momento
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _currentNavIndex = 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ControlaSchool',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            color: AppTheme.primaryColor,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No tienes nuevas notificaciones'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            color: AppTheme.primaryColor,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/home'),
      body: Container(
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildWelcomeCard(),
                const SizedBox(height: 30),
                const SectionTitle(title: 'Resumen Rápido', icon: Icons.dashboard_rounded),
                const SizedBox(height: 15),
                _buildQuickStats(),
                const SizedBox(height: 30),
                const SectionTitle(title: 'Funcionalidades', icon: Icons.apps_rounded),
                const SizedBox(height: 15),
                const FeatureCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenid@!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Has iniciado sesión correctamente',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.school_rounded,
            title: 'Estudiantes',
            value: '0',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: StatCard(
            icon: Icons.class_rounded,
            title: 'Clases',
            value: '0',
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: StatCard(
            icon: Icons.event_rounded,
            title: 'Eventos',
            value: '0',
            color: AppTheme.primaryColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
import 'package:controla_school/screens/class_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/section_title.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../models/class_model.dart';
import '../config/theme.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();

  void _onNavItemTapped(int index) {
    if (index == _currentNavIndex) return;
    
    setState(() => _currentNavIndex = index);
    
    // Navegación real para clases
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClassesScreen()),
      ).then((_) {
        if (mounted) {
          setState(() => _currentNavIndex = 0);
        }
      });
    } else if (index != 0) {
      // Mostrar mensaje para pestañas en desarrollo
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
    final userId = _authService.currentUser?.uid ?? '';

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
          StreamBuilder<int>(
            stream: _classService.getUnreadNotificationsCount(userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notificaciones',
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
                _buildQuickStats(userId),
                const SizedBox(height: 30),
                const SectionTitle(title: 'Mis Clases', icon: Icons.class_rounded),
                const SizedBox(height: 15),
                _buildMyClasses(userId),
                const SizedBox(height: 30),
                const SectionTitle(title: 'Acceso Rápido', icon: Icons.apps_rounded),
                const SizedBox(height: 15),
                _buildQuickActions(),
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
    final userName = _authService.currentUser?.displayName ?? 'Usuario';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
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
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Hola, $userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenido de vuelta',
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

  Widget _buildQuickStats(String userId) {
    return StreamBuilder<List<ClassModel>>(
      stream: _classService.getUserClasses(userId),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        final totalClasses = classes.length;
        
        // Contar clases donde es tutor
        final tutorClasses = classes.where((c) => c.tutorId == userId).length;
        
        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.class_rounded,
                title: 'Mis Clases',
                value: '$totalClasses',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: StatCard(
                icon: Icons.star_rounded,
                title: 'Como Tutor',
                value: '$tutorClasses',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: StreamBuilder<int>(
                stream: _classService.getUnreadNotificationsCount(userId),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return StatCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notificaciones',
                    value: '$unread',
                    color: Colors.orange,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyClasses(String userId) {
    return StreamBuilder<List<ClassModel>>(
      stream: _classService.getUserClasses(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          );
        }

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.class_outlined,
                    size: 60,
                    color: AppTheme.textColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes clases aún',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClassesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crear o Unirse'),
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar solo las primeras 3 clases
        final displayClasses = classes.take(3).toList();

        return Column(
          children: [
            ...displayClasses.map((classModel) {
              final role = classModel.getUserRole(userId);
              final roleText = role == ClassRole.tutor
                  ? 'Tutor'
                  : role == ClassRole.admin
                      ? 'Admin'
                      : 'Estudiante';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.class_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    classModel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(classModel.subject),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      roleText,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClassesScreen(),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
            if (classes.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassesScreen(),
                    ),
                  );
                },
                child: Text('Ver todas (${classes.length})'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassesScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mis Clases',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
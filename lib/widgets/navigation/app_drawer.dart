import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../screens/home_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    final userEmail = user?.email ?? 'usuario@email.com';

    return Drawer(
      child: Container(
        decoration: BoxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(userName, userEmail),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.home_rounded,
                      title: 'Inicio',
                      route: '/home',
                      isSelected: currentRoute == '/home',
                      onTap: () {
                        if (currentRoute != '/home') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.school_rounded,
                      title: 'Estudiantes',
                      route: '/students',
                      isSelected: currentRoute == '/students',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.class_rounded,
                      title: 'Clases',
                      route: '/classes',
                      isSelected: currentRoute == '/classes',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.event_rounded,
                      title: 'Eventos',
                      route: '/events',
                      isSelected: currentRoute == '/events',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.assessment_rounded,
                      title: 'Reportes',
                      route: '/reports',
                      isSelected: currentRoute == '/reports',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context);
                      },
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      title: 'Configuración',
                      route: '/settings',
                      isSelected: currentRoute == '/settings',
                      onTap: () {
                        if (currentRoute != '/settings') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildLogoutButton(context, authService),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
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
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context, authService),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar Sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(color: AppTheme.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
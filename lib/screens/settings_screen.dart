import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/common/user_profile_header.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_title.dart';
import '../config/theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;
  String _userEmail = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final biometricEnabled = await _authService.isBiometricEnabled();
    final biometricAvailable = await _authService.checkBiometricAvailability();
    final email = await _authService.getSavedEmail();
    final user = _authService.currentUser;

    setState(() {
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _userEmail = email ?? user?.email ?? '';
      _userName = user?.displayName ?? 'Usuario';
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_biometricAvailable) {
      _showMessage('La autenticación biométrica no está disponible en este dispositivo');
      return;
    }

    if (value) {
      final authenticated = await _authService.authenticateWithBiometric();
      if (!authenticated) {
        _showMessage('Debes autenticarte para habilitar esta función');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateBiometricSetting(value);
      
      setState(() {
        _biometricEnabled = value;
        _isLoading = false;
      });

      _showMessage(
        value 
          ? 'Autenticación biométrica habilitada' 
          : 'Autenticación biométrica deshabilitada'
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error al actualizar la configuración');
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                await _authService.signOut();
                
                if (mounted) {
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileHeader(
                    userName: _userName,
                    userEmail: _userEmail,
                  ),
                  const SizedBox(height: 30),
                  _buildSecuritySection(),
                  const SizedBox(height: 30),
                  _buildAboutSection(),
                  const SizedBox(height: 30),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Seguridad', icon: Icons.security_rounded),
        const SizedBox(height: 10),
        CustomCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Autenticación Biométrica',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _biometricAvailable
                      ? 'Usa tu huella dactilar o Face ID para iniciar sesión'
                      : 'No disponible en este dispositivo',
                  style: TextStyle(
                    color: _biometricAvailable 
                        ? AppTheme.textColor.withValues(alpha: 0.6)
                        : Colors.red.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                value: _biometricEnabled && _biometricAvailable,
                onChanged: _biometricAvailable ? _toggleBiometric : null,
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: _biometricAvailable 
                      ? AppTheme.primaryColor 
                      : AppTheme.textColor.withValues(alpha: 0.3),
                  size: 28,
                ),
                activeColor: AppTheme.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Cambiar Contraseña',
                onTap: () => _showMessage('Función en desarrollo'),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacidad',
                onTap: () => _showMessage('Función en desarrollo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Acerca de', icon: Icons.info_outline_rounded),
        const SizedBox(height: 10),
        CustomCard(
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Versión',
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Términos y Condiciones',
                onTap: () => _showMessage('Función en desarrollo'),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de Privacidad',
                onTap: () => _showMessage('Función en desarrollo'),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda y Soporte',
                onTap: () => _showMessage('Función en desarrollo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppTheme.textColor.withValues(alpha: 0.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded, size: 22),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
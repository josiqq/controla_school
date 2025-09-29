import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserSection(),
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

  Widget _buildUserSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seguridad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Autenticación Biométrica',
                style: TextStyle(color: AppTheme.textColor),
              ),
              subtitle: Text(
                _biometricAvailable
                    ? 'Usa tu huella dactilar o Face ID para iniciar sesión'
                    : 'No disponible en este dispositivo',
                style: TextStyle(
                  color: _biometricAvailable 
                      ? AppTheme.textColor.withValues(alpha: 0.6)
                      : Colors.red,
                ),
              ),
              value: _biometricEnabled && _biometricAvailable,
              onChanged: _biometricAvailable ? _toggleBiometric : null,
              secondary: Icon(
                Icons.fingerprint,
                color: _biometricAvailable 
                    ? AppTheme.primaryColor 
                    : AppTheme.textColor.withValues(alpha: 0.3),
              ),
              activeThumbColor: AppTheme.primaryColor,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.lock_outline,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'Cambiar Contraseña',
                style: TextStyle(color: AppTheme.textColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textColor.withValues(alpha: 0.4),
              ),
              onTap: () {
                _showMessage('Función en desarrollo');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acerca de',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'Versión',
                style: TextStyle(color: AppTheme.textColor),
              ),
              trailing: Text(
                '1.0.0',
                style: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'Términos y Condiciones',
                style: TextStyle(color: AppTheme.textColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textColor.withValues(alpha: 0.4),
              ),
              onTap: () {
                _showMessage('Función en desarrollo');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'Política de Privacidad',
                style: TextStyle(color: AppTheme.textColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textColor.withValues(alpha: 0.4),
              ),
              onTap: () {
                _showMessage('Función en desarrollo');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
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
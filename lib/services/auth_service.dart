import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../config/constants.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Verificar disponibilidad de biometría
  Future<bool> checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Autenticación biométrica
  Future<bool> authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a ControlaSchool',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  // Login con email y contraseña
  Future<bool> login(String email, String password) async {
    // Simular delay de red
    await Future.delayed(AppConstants.loginDelay);
    
    // Verificar credenciales (en producción, esto sería una llamada API)
    return email == AppConstants.testEmail && 
           password == AppConstants.testPassword;
  }

  // Validar email
  bool isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  // Validar contraseña
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}

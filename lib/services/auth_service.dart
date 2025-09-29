import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys para SharedPreferences
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email';
  static const String _hasLoggedInKey = 'has_logged_in';

  // Obtener usuario actual
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Verificar si es la primera vez que el usuario inicia sesión
  Future<bool> isFirstTimeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_hasLoggedInKey);
  }

  // Verificar si la biometría está habilitada para el usuario
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Habilitar/Deshabilitar autenticación biométrica
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Guardar email del usuario para autenticación biométrica
  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  // Obtener email guardado
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

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

  // Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
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

      if (authenticated) {
        // Si la autenticación biométrica es exitosa,
        // intentamos hacer login silencioso con el email guardado
        final email = await getSavedEmail();
        if (email != null && currentUser != null) {
          return true;
        }
      }

      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  // Login automático con biometría
  Future<Map<String, dynamic>> loginWithBiometric() async {
    try {
      final biometricEnabled = await isBiometricEnabled();
      if (!biometricEnabled) {
        return {
          'success': false,
          'message': 'Autenticación biométrica no habilitada',
        };
      }

      final authenticated = await authenticateWithBiometric();
      if (authenticated) {
        // Si ya hay una sesión activa, retornamos éxito
        if (currentUser != null) {
          return {
            'success': true,
            'message': 'Autenticación exitosa',
            'user': currentUser,
          };
        }
      }

      return {'success': false, 'message': 'Autenticación biométrica fallida'};
    } catch (e) {
      return {'success': false, 'message': 'Error en autenticación biométrica'};
    }
  }

  // Registro con Firebase
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Actualizar el nombre del usuario
      await userCredential.user?.updateDisplayName(name);

      // Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'student',
        'biometricEnabled': false,
      });

      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          message = 'Este email ya está registrado';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
        default:
          message = 'Error en el registro: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // Login con Firebase
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Primero intentar con las credenciales de prueba
      if (email == AppConstants.testEmail &&
          password == AppConstants.testPassword) {
        await Future.delayed(AppConstants.loginDelay);

        // Guardar estado de login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hasLoggedInKey, true);
        await prefs.setString(_userEmailKey, email);

        return {
          'success': true,
          'message': 'Login exitoso',
          'isTestUser': true,
        };
      }

      // Luego intentar con Firebase
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // Guardar estado de login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasLoggedInKey, true);
      await prefs.setString(_userEmailKey, email);

      // Obtener configuración de biometría desde Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        final biometricEnabled = userDoc.data()?['biometricEnabled'] ?? false;
        await setBiometricEnabled(biometricEnabled);
      }

      return {
        'success': true,
        'message': 'Login exitoso',
        'user': userCredential.user,
        'isTestUser': false,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
        default:
          message = 'Error en el login: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // Actualizar configuración de biometría en Firestore
  Future<void> updateBiometricSetting(bool enabled) async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'biometricEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await setBiometricEnabled(enabled);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    // Mantener el email guardado pero resetear biometría si es necesario
    final prefs = await SharedPreferences.getInstance();
    // Opcional: puedes mantener o borrar estas preferencias según tu lógica de negocio
    // await prefs.remove(_biometricEnabledKey);
    // await prefs.remove(_hasLoggedInKey);
  }

  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Validar email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validar contraseña
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Limpiar todas las preferencias (útil para logout completo)
  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await signOut();
  }
}

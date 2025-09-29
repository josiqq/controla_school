import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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

  // Registro con Firebase
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el nombre del usuario
      await userCredential.user?.updateDisplayName(name);

      // Guardar datos adicionales en Firestore (opcional)
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'student', // o el rol que corresponda
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
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: ${e.toString()}',
      };
    }
  }

  // Login con Firebase
  Future<bool> login(String email, String password) async {
    try {
      // Primero intentar con las credenciales de prueba
      if (email == AppConstants.testEmail && 
          password == AppConstants.testPassword) {
        await Future.delayed(AppConstants.loginDelay);
        return true;
      }

      // Luego intentar con Firebase
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code}');
      return false;
    } catch (e) {
      print('Login error: ${e.toString()}');
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
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
}
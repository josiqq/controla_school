import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String _statusMessage = '';
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    final token = _notificationService.fcmToken;
    setState(() {
      _fcmToken = token;
    });
  }

  // Test 1: Notificación local inmediata
  Future<void> _testLocalNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando notificación local...';
    });

    try {
      await _notificationService.initialize();
      
      // Crear una notificación de prueba directamente en la cola
      await _firestore.collection('notifications_queue').add({
        'userId': _authService.currentUser?.uid ?? '',
        'fcmToken': _fcmToken ?? '',
        'title': '🔔 Test Notificación Local',
        'body': 'Esta es una notificación de prueba local - ${DateTime.now().toIso8601String()}',
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Notificación local enviada exitosamente';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  // Test 2: Notificación mediante Cloud Functions
  Future<void> _testCloudFunctionNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando notificación mediante Cloud Functions...';
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Agregar a la cola de notificaciones (Cloud Functions la procesará)
      await _firestore.collection('notifications_queue').add({
        'userId': userId,
        'fcmToken': _fcmToken ?? '',
        'title': '🚀 Test Cloud Functions',
        'body': 'Notificación enviada mediante Cloud Functions - ${DateTime.now().hour}:${DateTime.now().minute}',
        'data': {
          'type': 'cloud_test',
          'priority': 'high',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Notificación agregada a la cola. Cloud Functions la procesará.';
      });

      // Esperar 3 segundos y verificar si se envió
      await Future.delayed(const Duration(seconds: 3));
      _checkNotificationStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  // Test 3: Notificación con alta prioridad
  Future<void> _testHighPriorityNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando notificación de alta prioridad...';
    });

    try {
      await _notificationService.sendNotificationToUser(
        userId: _authService.currentUser!.uid,
        title: '⚡ Notificación Prioritaria',
        body: 'Esta notificación tiene alta prioridad y debe mostrarse en segundo plano',
        data: {
          'type': 'high_priority_test',
          'priority': 'high',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Notificación de alta prioridad enviada';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  // Test 4: Múltiples notificaciones
  Future<void> _testMultipleNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando 3 notificaciones de prueba...';
    });

    try {
      final userId = _authService.currentUser!.uid;
      
      for (int i = 1; i <= 3; i++) {
        await _firestore.collection('notifications_queue').add({
          'userId': userId,
          'fcmToken': _fcmToken ?? '',
          'title': '📱 Test $i de 3',
          'body': 'Esta es la notificación número $i',
          'data': {
            'type': 'multiple_test',
            'sequence': i.toString(),
          },
          'createdAt': FieldValue.serverTimestamp(),
          'sent': false,
        });
        
        // Pequeño delay entre notificaciones
        await Future.delayed(const Duration(milliseconds: 500));
      }

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ 3 notificaciones enviadas';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  // Test 5: Notificación programada (usando Cloud Functions scheduler)
  Future<void> _testScheduledNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Programando notificación para dentro de 10 segundos...';
    });

    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      
      await _firestore.collection('notifications_queue').add({
        'userId': _authService.currentUser!.uid,
        'fcmToken': _fcmToken ?? '',
        'title': '⏰ Notificación Programada',
        'body': 'Esta notificación fue programada para ${scheduledTime.hour}:${scheduledTime.minute}',
        'data': {
          'type': 'scheduled_test',
          'scheduledFor': scheduledTime.toIso8601String(),
        },
        'scheduledAt': Timestamp.fromDate(scheduledTime),
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Notificación programada para dentro de 10 segundos';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  // Verificar estado de las notificaciones enviadas
  Future<void> _checkNotificationStatus() async {
    try {
      final snapshot = await _firestore
          .collection('notifications_queue')
          .where('userId', isEqualTo: _authService.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      int sent = 0;
      int pending = 0;
      int failed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['sent'] == true) {
          sent++;
        } else if (data['error'] != null) {
          failed++;
        } else {
          pending++;
        }
      }

      setState(() {
        _statusMessage += '\n\n📊 Estado: $sent enviadas, $pending pendientes, $failed fallidas';
      });
    } catch (e) {
      print('Error verificando estado: $e');
    }
  }

  // Limpiar cola de notificaciones de prueba
  Future<void> _clearTestNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Limpiando notificaciones de prueba...';
    });

    try {
      final snapshot = await _firestore
          .collection('notifications_queue')
          .where('userId', isEqualTo: _authService.currentUser?.uid)
          .where('data.type', whereIn: ['test', 'cloud_test', 'high_priority_test', 'multiple_test'])
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ ${snapshot.docs.length} notificaciones de prueba eliminadas';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Notificaciones'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 10),
                        Text(
                          'Información del Dispositivo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FCM Token: ${_fcmToken ?? "Cargando..."}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User ID: ${_authService.currentUser?.uid ?? "No autenticado"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Test Buttons
            const Text(
              'Pruebas de Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildTestButton(
              icon: Icons.notifications_active,
              title: 'Test 1: Notificación Local',
              description: 'Envía una notificación local inmediata',
              onPressed: _testLocalNotification,
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.cloud_upload,
              title: 'Test 2: Cloud Functions',
              description: 'Notificación mediante Cloud Functions',
              onPressed: _testCloudFunctionNotification,
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.priority_high,
              title: 'Test 3: Alta Prioridad',
              description: 'Notificación con máxima prioridad',
              onPressed: _testHighPriorityNotification,
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.format_list_numbered,
              title: 'Test 4: Múltiples Notificaciones',
              description: 'Envía 3 notificaciones consecutivas',
              onPressed: _testMultipleNotifications,
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.schedule,
              title: 'Test 5: Notificación Programada',
              description: 'Notificación en 10 segundos',
              onPressed: _testScheduledNotification,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkNotificationStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Verificar Estado'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clearTestNotifications,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Instructions Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        const Text(
                          'Instrucciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Envía una notificación de prueba\n'
                      '2. Cierra la app (no la elimines, solo minimízala)\n'
                      '3. Espera unos segundos\n'
                      '4. La notificación debe aparecer en segundo plano\n\n'
                      'Si no aparece, verifica:\n'
                      '• Permisos de notificaciones\n'
                      '• Cloud Functions desplegadas\n'
                      '• Logs de Firebase Console',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
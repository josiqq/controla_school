import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar código único para la clase
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Crear nueva clase
  Future<Map<String, dynamic>> createClass({
    required String name,
    required String description,
    required String subject,
    required String tutorId,
    required String tutorName,
    String? imageUrl,
  }) async {
    try {
      final classCode = _generateClassCode();
      
      final classData = ClassModel(
        id: '',
        name: name,
        description: description,
        tutorId: tutorId,
        tutorName: tutorName,
        classCode: classCode,
        adminIds: [],
        studentIds: [],
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        subject: subject,
      ).toMap();

      final docRef = await _firestore.collection('classes').add(classData);

      return {
        'success': true,
        'classId': docRef.id,
        'classCode': classCode,
        'message': 'Clase creada exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear la clase: ${e.toString()}',
      };
    }
  }

  // Unirse a una clase con código
  Future<Map<String, dynamic>> joinClassWithCode({
    required String classCode,
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('classCode', isEqualTo: classCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Código de clase inválido',
        };
      }

      final classDoc = querySnapshot.docs.first;
      final classData = ClassModel.fromFirestore(classDoc);

      // Verificar si ya está en la clase
      if (classData.tutorId == userId ||
          classData.adminIds.contains(userId) ||
          classData.studentIds.contains(userId)) {
        return {
          'success': false,
          'message': 'Ya eres miembro de esta clase',
        };
      }

      // Agregar usuario como estudiante
      await classDoc.reference.update({
        'studentIds': FieldValue.arrayUnion([userId]),
      });

      return {
        'success': true,
        'classId': classDoc.id,
        'message': 'Te has unido a la clase exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al unirse a la clase: ${e.toString()}',
      };
    }
  }

  // Obtener clases del usuario
  Stream<List<ClassModel>> getUserClasses(String userId) {
    return _firestore
        .collection('classes')
        .where('studentIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ClassModel> classes = snapshot.docs
          .map((doc) => ClassModel.fromFirestore(doc))
          .toList();

      // También obtener clases donde es tutor o admin
      final tutorSnapshot = await _firestore
          .collection('classes')
          .where('tutorId', isEqualTo: userId)
          .get();

      classes.addAll(
        tutorSnapshot.docs.map((doc) => ClassModel.fromFirestore(doc)),
      );

      final adminSnapshot = await _firestore
          .collection('classes')
          .where('adminIds', arrayContains: userId)
          .get();

      classes.addAll(
        adminSnapshot.docs.map((doc) => ClassModel.fromFirestore(doc)),
      );

      // Remover duplicados
      final uniqueClasses = <String, ClassModel>{};
      for (var classModel in classes) {
        uniqueClasses[classModel.id] = classModel;
      }

      return uniqueClasses.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Promover estudiante a administrador
  Future<Map<String, dynamic>> promoteToAdmin({
    required String classId,
    required String userId,
    required String requestingUserId,
  }) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      // Solo el tutor puede promover administradores
      if (classData.tutorId != requestingUserId) {
        return {
          'success': false,
          'message': 'Solo el tutor puede asignar administradores',
        };
      }

      await classDoc.reference.update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });

      // Crear notificación
      await _createNotification(
        userId: userId,
        title: 'Nuevo rol asignado',
        body: 'Has sido promovido a administrador en ${classData.name}',
        type: 'admin',
        relatedId: classId,
      );

      return {
        'success': true,
        'message': 'Usuario promovido a administrador',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al promover usuario: ${e.toString()}',
      };
    }
  }

  // Remover administrador
  Future<Map<String, dynamic>> removeAdmin({
    required String classId,
    required String userId,
    required String requestingUserId,
  }) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      if (classData.tutorId != requestingUserId) {
        return {
          'success': false,
          'message': 'Solo el tutor puede remover administradores',
        };
      }

      await classDoc.reference.update({
        'adminIds': FieldValue.arrayRemove([userId]),
      });

      return {
        'success': true,
        'message': 'Administrador removido',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al remover administrador: ${e.toString()}',
      };
    }
  }

  // Crear tarea
  Future<Map<String, dynamic>> createTask({
    required String classId,
    required String title,
    required String description,
    required DateTime dueDate,
    required String createdBy,
    required String createdByName,
    List<String>? attachments,
    int maxScore = 100,
  }) async {
    try {
      // Verificar permisos
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      if (!classData.canManageClass(createdBy)) {
        return {
          'success': false,
          'message': 'No tienes permisos para crear tareas',
        };
      }

      final taskData = TaskModel(
        id: '',
        classId: classId,
        title: title,
        description: description,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        attachments: attachments ?? [],
        maxScore: maxScore,
      ).toMap();

      final docRef = await _firestore.collection('tasks').add(taskData);

      // Enviar notificaciones a todos los estudiantes
      await _notifyClassMembers(
        classData: classData,
        title: 'Nueva tarea: $title',
        body: 'Se ha asignado una nueva tarea en ${classData.name}',
        type: 'task',
        relatedId: docRef.id,
      );

      return {
        'success': true,
        'taskId': docRef.id,
        'message': 'Tarea creada exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear la tarea: ${e.toString()}',
      };
    }
  }

  // Obtener tareas de una clase
  Stream<List<TaskModel>> getClassTasks(String classId) {
    return _firestore
        .collection('tasks')
        .where('classId', isEqualTo: classId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  // Crear evento
  Future<Map<String, dynamic>> createEvent({
    required String classId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required String type,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      if (!classData.canManageClass(createdBy)) {
        return {
          'success': false,
          'message': 'No tienes permisos para crear eventos',
        };
      }

      final eventData = EventModel(
        id: '',
        classId: classId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        location: location,
        type: type,
      ).toMap();

      final docRef = await _firestore.collection('events').add(eventData);

      // Notificar a todos los miembros
      await _notifyClassMembers(
        classData: classData,
        title: 'Nuevo evento: $title',
        body: 'Se ha programado un nuevo evento en ${classData.name}',
        type: 'event',
        relatedId: docRef.id,
      );

      return {
        'success': true,
        'eventId': docRef.id,
        'message': 'Evento creado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear el evento: ${e.toString()}',
      };
    }
  }

  // Obtener eventos de una clase
  Stream<List<EventModel>> getClassEvents(String classId) {
    return _firestore
        .collection('events')
        .where('classId', isEqualTo: classId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Crear notificación
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final notificationData = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    ).toMap();

    await _firestore.collection('notifications').add(notificationData);
    
    // Enviar notificación push
    final NotificationService notificationService = NotificationService();
    await notificationService.sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': type,
        'relatedId': relatedId ?? '',
      },
    );
  }

  // Notificar a todos los miembros de una clase
  Future<void> _notifyClassMembers({
    required ClassModel classData,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final allMembers = [
      ...classData.studentIds,
      ...classData.adminIds,
    ];

    for (String userId in allMembers) {
      await _createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
      );
    }
  }

  // Obtener notificaciones del usuario
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Obtener cantidad de notificaciones no leídas
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Salir de una clase
  Future<Map<String, dynamic>> leaveClass({
    required String classId,
    required String userId,
  }) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      if (classData.tutorId == userId) {
        return {
          'success': false,
          'message': 'El tutor no puede salir de su propia clase',
        };
      }

      await classDoc.reference.update({
        'studentIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });

      return {
        'success': true,
        'message': 'Has salido de la clase',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al salir de la clase: ${e.toString()}',
      };
    }
  }

  // Eliminar clase (solo tutor)
  Future<Map<String, dynamic>> deleteClass({
    required String classId,
    required String userId,
  }) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final classData = ClassModel.fromFirestore(classDoc);

      if (classData.tutorId != userId) {
        return {
          'success': false,
          'message': 'Solo el tutor puede eliminar la clase',
        };
      }

      // Eliminar tareas asociadas
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('classId', isEqualTo: classId)
          .get();

      for (var doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar eventos asociados
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('classId', isEqualTo: classId)
          .get();

      for (var doc in eventsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar la clase
      await classDoc.reference.delete();

      return {
        'success': true,
        'message': 'Clase eliminada exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al eliminar la clase: ${e.toString()}',
      };
    }
  }
}
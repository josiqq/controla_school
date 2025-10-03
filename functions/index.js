const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// Enviar notificaciones desde la cola
exports.sendNotificationFromQueue = onDocumentCreated(
    "notifications_queue/{notificationId}",
    async (event) => {
      const data = event.data.data();

      if (data.sent) {
        return null;
      }

      // Configuración mejorada del mensaje para segundo plano
      const message = {
        notification: {
          title: data.title,
          body: data.body,
        },
        data: {
          // Convertir todos los datos a strings (requisito de FCM)
          ...(data.data || {}),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          // Agregar timestamp para debugging
          timestamp: Date.now().toString(),
        },
        token: data.fcmToken,
        // Configuración CRÍTICA para Android
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
            // IMPORTANTE: contentAvailable debe ser true
            visibility: "public",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
          // Configuración para que funcione en segundo plano
          collapseKey: "controlaschool",
          ttl: 86400, // 24 horas en segundos
        },
        // Configuración CRÍTICA para iOS
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              "alert": {
                title: data.title,
                body: data.body,
              },
              "sound": "default",
              "badge": 1,
              // IMPORTANTE para iOS
              "content-available": 1,
              "mutable-content": 1,
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Notificación enviada exitosamente:", response);

        // Marcar como enviada
        await event.data.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: response,
        });

        return null;
      } catch (error) {
        console.error("Error al enviar notificación:", error);

        // Registrar el error con más detalles
        await event.data.ref.update({
          error: error.message,
          errorCode: error.code,
          errorDetails: JSON.stringify(error),
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return null;
      }
    },
);

// Limpiar notificaciones antiguas de la cola (cada día)
exports.cleanOldNotifications = onSchedule("every 24 hours", async (event) => {
  const db = admin.firestore();
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 7); // 7 días atrás

  const snapshot = await db
      .collection("notifications_queue")
      .where("createdAt", "<", cutoffDate)
      .where("sent", "==", true)
      .get();

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Eliminadas ${snapshot.size} notificaciones antiguas`);
  return null;
});

// Función para enviar notificación cuando se crea una tarea
exports.onTaskCreated = onDocumentCreated(
    "tasks/{taskId}",
    async (event) => {
      const taskData = event.data.data();
      const classId = taskData.classId;

      // Obtener información de la clase
      const classDoc = await admin.firestore()
          .collection("classes")
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        return null;
      }

      const classData = classDoc.data();
      const members = [
        ...classData.studentIds,
        ...classData.adminIds,
      ];

      // Obtener tokens de todos los miembros
      const usersSnapshot = await admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", members)
          .get();

      const tokens = [];
      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        return null;
      }

      const message = {
        notification: {
          title: `Nueva tarea: ${taskData.title}`,
          body: `Se ha asignado una nueva tarea en ${classData.name}`,
        },
        data: {
          type: "task",
          taskId: event.params.taskId,
          classId: classId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
            visibility: "public",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              "sound": "default",
              "badge": 1,
              "content-available": 1,
            },
          },
        },
      };

      // Enviar a múltiples dispositivos
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });

      console.log(
          `${response.successCount} notificaciones enviadas, ` +
      `${response.failureCount} fallidas`,
      );

      // Log de tokens que fallaron
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Error en token ${tokens[idx]}:`, resp.error);
          }
        });
      }

      return null;
    },
);

// Función para enviar notificación cuando se crea un evento
exports.onEventCreated = onDocumentCreated(
    "events/{eventId}",
    async (event) => {
      const eventData = event.data.data();
      const classId = eventData.classId;

      // Obtener información de la clase
      const classDoc = await admin.firestore()
          .collection("classes")
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        return null;
      }

      const classData = classDoc.data();
      const members = [
        ...classData.studentIds,
        ...classData.adminIds,
      ];

      // Obtener tokens de todos los miembros
      const usersSnapshot = await admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", members)
          .get();

      const tokens = [];
      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        return null;
      }

      const message = {
        notification: {
          title: `Nuevo evento: ${eventData.title}`,
          body: `Se ha programado un nuevo evento en ${classData.name}`,
        },
        data: {
          type: "event",
          eventId: event.params.eventId,
          classId: classId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
            visibility: "public",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              "sound": "default",
              "badge": 1,
              "content-available": 1,
            },
          },
        },
      };

      // Enviar a múltiples dispositivos
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });

      console.log(
          `${response.successCount} notificaciones enviadas, ` +
      `${response.failureCount} fallidas`,
      );
      return null;
    },
);

// Recordatorio de tareas próximas a vencer (ejecutar cada hora)
exports.checkDueTasks = onSchedule("every 1 hours", async (event) => {
  const db = admin.firestore();
  const now = new Date();
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Buscar tareas que vencen en las próximas 24 horas
  const tasksSnapshot = await db
      .collection("tasks")
      .where("dueDate", ">", now)
      .where("dueDate", "<", tomorrow)
      .where("isCompleted", "==", false)
      .get();

  if (tasksSnapshot.empty) {
    console.log("No hay tareas próximas a vencer");
    return null;
  }

  for (const taskDoc of tasksSnapshot.docs) {
    const taskData = taskDoc.data();

    // Obtener la clase
    const classDoc = await db
        .collection("classes")
        .doc(taskData.classId)
        .get();
    if (!classDoc.exists) continue;

    const classData = classDoc.data();
    const members = classData.studentIds;

    // Obtener tokens
    const usersSnapshot = await db
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", members)
        .get();

    const tokens = [];
    usersSnapshot.docs.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length > 0) {
      const message = {
        notification: {
          title: "⏰ Recordatorio de tarea",
          body: `La tarea "${taskData.title}" vence mañana`,
        },
        data: {
          type: "task_reminder",
          taskId: taskDoc.id,
          classId: taskData.classId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            priority: "high",
            visibility: "public",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              "sound": "default",
              "badge": 1,
              "content-available": 1,
            },
          },
        },
      };

      await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });
    }
  }

  console.log(`Procesadas ${tasksSnapshot.size} tareas`);
  return null;
});

// Función HTTP para testing (útil para debugging)
const {onRequest} = require("firebase-functions/v2/https");

exports.testNotification = onRequest(async (req, res) => {
  const {userId, title, body} = req.body;

  if (!userId) {
    res.status(400).send({error: "userId es requerido"});
    return;
  }

  try {
    const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      res.status(404).send({error: "Usuario no encontrado"});
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      res.status(400).send({error: "Usuario no tiene FCM token"});
      return;
    }

    const message = {
      notification: {
        title: title || "🧪 Test de Notificación",
        body: body || "Esta es una notificación desde Cloud Functions",
      },
      data: {
        type: "test",
        timestamp: Date.now().toString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      token: fcmToken,
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          priority: "high",
          visibility: "public",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            "alert": {
              title: title || "🧪 Test de Notificación",
              body: body || "Esta es una notificación de prueba",
            },
            "sound": "default",
            "badge": 1,
            "content-available": 1,
            "mutable-content": 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);

    res.status(200).send({
      success: true,
      messageId: response,
      message: "Notificación enviada exitosamente",
    });
  } catch (error) {
    console.error("Error en testNotification:", error);
    res.status(500).send({
      error: error.message,
      code: error.code,
      details: JSON.stringify(error),
    });
  }
});

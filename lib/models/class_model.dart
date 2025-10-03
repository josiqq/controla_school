import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassRole { tutor, admin, student }

class ClassModel {
  final String id;
  final String name;
  final String description;
  final String tutorId;
  final String tutorName;
  final String classCode; // Código único para unirse
  final List<String> adminIds;
  final List<String> studentIds;
  final DateTime createdAt;
  final String? imageUrl;
  final String subject; // Materia

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tutorId,
    required this.tutorName,
    required this.classCode,
    required this.adminIds,
    required this.studentIds,
    required this.createdAt,
    this.imageUrl,
    required this.subject,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      tutorId: data['tutorId'] ?? '',
      tutorName: data['tutorName'] ?? '',
      classCode: data['classCode'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      subject: data['subject'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'classCode': classCode,
      'adminIds': adminIds,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'subject': subject,
    };
  }

  ClassRole getUserRole(String userId) {
    if (userId == tutorId) return ClassRole.tutor;
    if (adminIds.contains(userId)) return ClassRole.admin;
    return ClassRole.student;
  }

  bool canManageClass(String userId) {
    return userId == tutorId || adminIds.contains(userId);
  }

  int get totalMembers => 1 + adminIds.length + studentIds.length;
}
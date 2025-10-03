import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final List<String> attachments;
  final bool isCompleted;
  final int maxScore;

  TaskModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.attachments,
    this.isCompleted = false,
    this.maxScore = 100,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      maxScore: data['maxScore'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'attachments': attachments,
      'isCompleted': isCompleted,
      'maxScore': maxScore,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isCompleted;
  
  int get daysUntilDue {
    final difference = dueDate.difference(DateTime.now());
    return difference.inDays;
  }
}
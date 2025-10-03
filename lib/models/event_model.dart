import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final String location;
  final String type; // 'exam', 'meeting', 'activity', 'other'

  EventModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.location,
    required this.type,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'location': location,
      'type': type,
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  bool get isUpcoming => startDate.isAfter(DateTime.now());
}

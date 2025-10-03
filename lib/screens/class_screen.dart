// lib/screens/classes_screen.dart
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'create_class_screen.dart';
import 'join_class_screen.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({Key? key}) : super(key: key);

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Clases',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: StreamBuilder<List<ClassModel>>(
          stream: _classService.getUserClasses(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final classes = snapshot.data ?? [];

            if (classes.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classModel = classes[index];
                return _buildClassCard(classModel, userId);
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JoinClassScreen(),
                ),
              );
            },
            heroTag: 'join',
            backgroundColor: AppTheme.accentColor,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Unirse'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateClassScreen(),
                ),
              );
            },
            heroTag: 'create',
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear Clase'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 100,
            color: AppTheme.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No tienes clases aún',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Crea una clase o únete a una existente',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel, String userId) {
    final role = classModel.getUserRole(userId);
    final roleText = role == ClassRole.tutor
        ? 'Tutor'
        : role == ClassRole.admin
            ? 'Admin'
            : 'Estudiante';
    
    final roleColor = role == ClassRole.tutor
        ? Colors.purple
        : role == ClassRole.admin
            ? Colors.orange
            : AppTheme.primaryColor;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(classModel: classModel),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_rounded,
                      size: 30,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classModel.subject,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleText,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                classModel.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    classModel.tutorName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${classModel.totalMembers} miembros',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
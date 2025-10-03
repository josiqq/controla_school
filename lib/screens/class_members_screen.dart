import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

class ClassMembersScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassMembersScreen({Key? key, required this.classModel}) : super(key: key);

  @override
  State<ClassMembersScreen> createState() => _ClassMembersScreenState();
}

class _ClassMembersScreenState extends State<ClassMembersScreen> {
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _isTutor {
    final userId = _authService.currentUser?.uid ?? '';
    return widget.classModel.tutorId == userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros de la Clase'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildTutorSection(),
            const SizedBox(height: 20),
            if (widget.classModel.adminIds.isNotEmpty) ...[
              _buildAdminsSection(),
              const SizedBox(height: 20),
            ],
            _buildStudentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '${widget.classModel.totalMembers}',
              'Total',
              Icons.people,
              AppTheme.primaryColor,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            _buildStatItem(
              '${widget.classModel.adminIds.length}',
              'Admins',
              Icons.admin_panel_settings,
              Colors.orange,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            _buildStatItem(
              '${widget.classModel.studentIds.length}',
              'Estudiantes',
              Icons.school,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tutor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(widget.classModel.tutorId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final name = userData?['name'] ?? widget.classModel.tutorName;
            final email = userData?['email'] ?? '';

            return _buildMemberCard(
              name: name,
              email: email,
              role: 'Tutor',
              roleColor: Colors.purple,
              roleIcon: Icons.star,
              userId: widget.classModel.tutorId,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Administradores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.classModel.adminIds.map((adminId) {
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(adminId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final name = userData?['name'] ?? 'Usuario';
              final email = userData?['email'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMemberCard(
                  name: name,
                  email: email,
                  role: 'Admin',
                  roleColor: Colors.orange,
                  roleIcon: Icons.admin_panel_settings,
                  userId: adminId,
                  canDemote: _isTutor,
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estudiantes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.classModel.studentIds.isEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No hay estudiantes aún',
                  style: TextStyle(
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          ...widget.classModel.studentIds.map((studentId) {
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(studentId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final name = userData?['name'] ?? 'Usuario';
                final email = userData?['email'] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMemberCard(
                    name: name,
                    email: email,
                    role: 'Estudiante',
                    roleColor: AppTheme.primaryColor,
                    roleIcon: Icons.school,
                    userId: studentId,
                    canPromote: _isTutor,
                  ),
                );
              },
            );
          }).toList(),
      ],
    );
  }

  Widget _buildMemberCard({
    required String name,
    required String email,
    required String role,
    required Color roleColor,
    required IconData roleIcon,
    required String userId,
    bool canPromote = false,
    bool canDemote = false,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 16, color: roleColor),
                  const SizedBox(width: 4),
                  Text(
                    role,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (canPromote || canDemote)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, userId, name),
                itemBuilder: (context) => [
                  if (canPromote)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 18),
                          SizedBox(width: 8),
                          Text('Promover a Admin'),
                        ],
                      ),
                    ),
                  if (canDemote)
                    const PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 18),
                          SizedBox(width: 8),
                          Text('Remover Admin'),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(String action, String userId, String userName) async {
    if (action == 'promote') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Promover a Admin'),
          content: Text('¿Deseas promover a $userName como administrador?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Promover'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final result = await _classService.promoteToAdmin(
          classId: widget.classModel.id,
          userId: userId,
          requestingUserId: _authService.currentUser!.uid,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  result['success'] ? Colors.green : Colors.red,
            ),
          );
          if (result['success']) {
            setState(() {});
          }
        }
      }
    } else if (action == 'demote') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remover Admin'),
          content: Text('¿Deseas remover a $userName como administrador?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final result = await _classService.removeAdmin(
          classId: widget.classModel.id,
          userId: userId,
          requestingUserId: _authService.currentUser!.uid,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  result['success'] ? Colors.green : Colors.red,
            ),
          );
          if (result['success']) {
            setState(() {});
          }
        }
      }
    }
  }
}
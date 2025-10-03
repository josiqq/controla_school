// lib/screens/class_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/class_model.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'create_task_screen.dart';
import 'create_event_screen.dart';
import 'class_members_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailScreen({Key? key, required this.classModel})
      : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canManage {
    final userId = _authService.currentUser?.uid ?? '';
    return widget.classModel.canManageClass(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassMembersScreen(
                    classModel: widget.classModel,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share_code',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Compartir código'),
                  ],
                ),
              ),
              if (_canManage)
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Configuración'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Salir de la clase', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Tareas'),
            Tab(text: 'Eventos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildTasksTab(),
          _buildEventsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_canManage) return null;

    return FloatingActionButton(
      onPressed: () => _showCreateMenu(),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment, color: AppTheme.primaryColor),
              title: const Text('Crear Tarea'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTaskScreen(classModel: widget.classModel),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: AppTheme.accentColor),
              title: const Text('Crear Evento'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(classModel: widget.classModel),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.class_rounded,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.classModel.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.classModel.subject,
                              style: TextStyle(
                                color: AppTheme.textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.description, 'Descripción'),
                  const SizedBox(height: 8),
                  Text(
                    widget.classModel.description,
                    style: TextStyle(
                      color: AppTheme.textColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Tutor'),
                  const SizedBox(height: 8),
                  Text(
                    widget.classModel.tutorName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.vpn_key, 'Código de la clase'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: Text(
                          widget.classModel.classCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.classModel.classCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    '${widget.classModel.totalMembers}',
                    'Miembros',
                    Icons.people,
                  ),
                  _buildStatColumn(
                    '${widget.classModel.adminIds.length}',
                    'Admins',
                    Icons.admin_panel_settings,
                  ),
                  _buildStatColumn(
                    '${widget.classModel.studentIds.length}',
                    'Estudiantes',
                    Icons.school,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
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

  Widget _buildTasksTab() {
    return StreamBuilder<List<TaskModel>>(
      stream: _classService.getClassTasks(widget.classModel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: AppTheme.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay tareas asignadas',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final isOverdue = task.isOverdue;
    final daysUntil = task.daysUntilDue;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue 
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.transparent,
          width: isOverdue ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOverdue ? Colors.red : AppTheme.primaryColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: isOverdue ? Colors.red : AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por ${task.createdByName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vencida',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isOverdue ? Colors.red : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Vence: ${_formatDate(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue ? Colors.red : AppTheme.textColor,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  daysUntil < 0 
                      ? '${-daysUntil} días atrasada'
                      : daysUntil == 0
                          ? 'Hoy'
                          : 'En $daysUntil días',
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
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _classService.getClassEvents(widget.classModel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 80,
                  color: AppTheme.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay eventos programados',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) => _buildEventCard(events[index]),
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event) {
    final eventColor = _getEventColor(event.type);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEventIcon(event.type),
                    color: eventColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por ${event.createdByName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEventTypeLabel(event.type),
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(event.startDate)} - ${_formatTime(event.startDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'exam':
        return Colors.red;
      case 'meeting':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'meeting':
        return Icons.video_call_rounded;
      case 'activity':
        return Icons.sports_esports_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case 'exam':
        return 'Examen';
      case 'meeting':
        return 'Reunión';
      case 'activity':
        return 'Actividad';
      default:
        return 'Evento';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'share_code':
        await Clipboard.setData(
          ClipboardData(text: widget.classModel.classCode),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código copiado al portapapeles'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración en desarrollo'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'leave':
        _showLeaveDialog();
        break;
    }
  }

  void _showLeaveDialog() {
    final userId = _authService.currentUser?.uid ?? '';
    final isTutor = widget.classModel.tutorId == userId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTutor ? 'Eliminar Clase' : 'Salir de la Clase'),
        content: Text(
          isTutor
              ? '¿Estás seguro de que deseas eliminar esta clase? Esta acción no se puede deshacer.'
              : '¿Estás seguro de que deseas salir de esta clase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final result = isTutor
                  ? await _classService.deleteClass(
                      classId: widget.classModel.id,
                      userId: userId,
                    )
                  : await _classService.leaveClass(
                      classId: widget.classModel.id,
                      userId: userId,
                    );

              if (mounted) {
                if (result['success']) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isTutor ? 'Eliminar' : 'Salir'),
          ),
        ],
      ),
    );
  }
}
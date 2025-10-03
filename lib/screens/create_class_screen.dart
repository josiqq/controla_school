import 'package:flutter/material.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateClass() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user == null) {
        _showMessage('Error: Usuario no autenticado');
        setState(() => _isLoading = false);
        return;
      }

      final result = await _classService.createClass(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _subjectController.text.trim(),
        tutorId: user.uid,
        tutorName: user.displayName ?? 'Usuario',
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessDialog(result['classCode']);
      } else {
        _showMessage(result['message']);
      }
    }
  }

  void _showSuccessDialog(String classCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('¡Clase Creada!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu clase ha sido creada exitosamente.'),
              const SizedBox(height: 16),
              const Text(
                'Código de la clase:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    classCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Comparte este código con tus estudiantes para que puedan unirse.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Clase'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildSubjectField(),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                  const SizedBox(height: 30),
                  _buildCreateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_circle_outline,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nueva Clase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa los datos para crear tu clase',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre de la clase',
        prefixIcon: Icon(Icons.class_rounded),
        hintText: 'Ej: Matemáticas Avanzadas',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el nombre de la clase';
        }
        if (value.length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: _subjectController,
      decoration: const InputDecoration(
        labelText: 'Materia',
        prefixIcon: Icon(Icons.book_rounded),
        hintText: 'Ej: Matemáticas',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa la materia';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        prefixIcon: Icon(Icons.description_outlined),
        hintText: 'Describe brevemente la clase',
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa una descripción';
        }
        if (value.length < 10) {
          return 'La descripción debe tener al menos 10 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleCreateClass,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          _isLoading ? 'Creando...' : 'Crear Clase',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

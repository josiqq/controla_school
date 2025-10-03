import 'package:flutter/material.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({Key? key}) : super(key: key);

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinClass() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user == null) {
        _showMessage('Error: Usuario no autenticado');
        setState(() => _isLoading = false);
        return;
      }

      final result = await _classService.joinClassWithCode(
        classCode: _codeController.text.trim().toUpperCase(),
        userId: user.uid,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showMessage(result['message']);
        Navigator.of(context).pop();
      } else {
        _showMessage(result['message']);
      }
    }
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
        title: const Text('Unirse a Clase'),
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
                  const SizedBox(height: 40),
                  _buildCodeField(),
                  const SizedBox(height: 30),
                  _buildJoinButton(),
                  const SizedBox(height: 20),
                  _buildInfo(),
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
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.group_add_rounded,
            size: 40,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Unirse a una Clase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el código de la clase',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      decoration: const InputDecoration(
        labelText: 'Código de la clase',
        prefixIcon: Icon(Icons.vpn_key_rounded),
        hintText: 'Ej: ABC123',
      ),
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        fontSize: 18,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el código';
        }
        if (value.length != 6) {
          return 'El código debe tener 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleJoinClass,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.login_rounded),
        label: Text(
          _isLoading ? 'Uniéndose...' : 'Unirse a la Clase',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solicita el código de 6 caracteres al tutor de la clase',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
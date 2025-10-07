import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  String _tipoLabel(int t) {
    switch (t) {
      case 1:
        return 'Passageiro';
      case 2:
        return 'Motorista';
      case 3:
        return 'Admin';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileData = Provider.of<UserProfileData>(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header com gradiente
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar e informações principais
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: Text(
                              userProfileData.name.isNotEmpty 
                                  ? userProfileData.name[0].toUpperCase() 
                                  : '?',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        userProfileData.name.isNotEmpty 
                            ? userProfileData.name 
                            : 'Nome não informado',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTipoIcon(userProfileData.userType),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tipoLabel(userProfileData.userType),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: userProfileData.email));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Email copiado para a área de transferência!'),
                                    backgroundColor: Colors.green.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.email,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'Copiar Email',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Cards de informações
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do Perfil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoCard(
                        icon: Icons.person,
                        title: 'Nome Completo',
                        value: userProfileData.name.isNotEmpty 
                            ? userProfileData.name 
                            : 'Não informado',
                        copyable: false,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoCard(
                        icon: Icons.email,
                        title: 'Email',
                        value: userProfileData.email.isNotEmpty 
                            ? userProfileData.email 
                            : 'Não informado',
                        copyable: true,
                        copyValue: userProfileData.email,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Telefone',
                        value: userProfileData.phone.isNotEmpty 
                            ? userProfileData.phone 
                            : 'Não informado',
                        copyable: true,
                        copyValue: userProfileData.phone,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildInfoCard(
                        icon: Icons.badge,
                        title: 'Tipo de Usuário',
                        value: _tipoLabel(userProfileData.userType),
                        copyable: false,
                        statusColor: _getTipoColor(userProfileData.userType),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Card de ações
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF4FC3F7).withOpacity(0.1),
                                const Color(0xFF29B6F6).withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Color(0xFF1976D2),
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Ações Rápidas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.copy,
                                      label: 'Copiar Email',
                                      onPressed: () {
                                        if (userProfileData.email.isNotEmpty) {
                                          Clipboard.setData(ClipboardData(text: userProfileData.email));
                                          _showCopySuccess(context, 'Email copiado!');
                                        } else {
                                          _showCopyError(context, 'Email não disponível');
                                        }
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.phone,
                                      label: 'Copiar Telefone',
                                      onPressed: () {
                                        if (userProfileData.phone.isNotEmpty) {
                                          Clipboard.setData(ClipboardData(text: userProfileData.phone));
                                          _showCopySuccess(context, 'Telefone copiado!');
                                        } else {
                                          _showCopyError(context, 'Telefone não disponível');
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool copyable,
    String? copyValue,
    Color? statusColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor?.withOpacity(0.1) ?? const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: statusColor ?? const Color(0xFF1976D2),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF546E7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            
            if (copyable && copyValue != null && copyValue.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyValue));
                    // Implementar feedback de sucesso
                  },
                  icon: const Icon(
                    Icons.copy,
                    color: Color(0xFF1976D2),
                    size: 18,
                  ),
                  tooltip: 'Copiar',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    );
  }

  IconData _getTipoIcon(int userType) {
    switch (userType) {
      case 1:
        return Icons.directions_bus;
      case 2:
        return Icons.drive_eta;
      case 3:
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTipoColor(int userType) {
    switch (userType) {
      case 1:
        return const Color(0xFF4CAF50); // Verde para passageiro
      case 2:
        return const Color(0xFFFF9800); // Laranja para motorista
      case 3:
        return const Color(0xFFE91E63); // Rosa para admin
      default:
        return const Color(0xFF9E9E9E); // Cinza para desconhecido
    }
  }

  void _showCopySuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showCopyError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}


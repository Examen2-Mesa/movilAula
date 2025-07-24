// lib/screens/padre/padre_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/estudiante.dart';
import '../../services/padre_api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/debug_logger.dart';
import '../../widgets/notification_icon_widget.dart';
import './info_academica_hijo_screen.dart'; // Nueva importación

class PadreHomeScreen extends StatefulWidget {
  static const routeName = '/padre-home';

  const PadreHomeScreen({Key? key}) : super(key: key);

  @override
  _PadreHomeScreenState createState() => _PadreHomeScreenState();
}

class _PadreHomeScreenState extends State<PadreHomeScreen> 
    with AutomaticKeepAliveClientMixin {
  
  List<Estudiante>? _hijos;
  bool _isLoading = false;
  String? _errorMessage;
  late PadreApiService _padreApiService;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _padreApiService = PadreApiService(authService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarHijos();
    });
  }

  Future<void> _cargarHijos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DebugLogger.info('Cargando lista de hijos', tag: 'PADRE_HOME');
      final hijos = await _padreApiService.getMisHijos();
      
      setState(() {
        _hijos = hijos;
        _isLoading = false;
      });
      
      DebugLogger.info('Hijos cargados exitosamente: ${hijos.length}', tag: 'PADRE_HOME');
    } catch (e) {
      DebugLogger.error('Error cargando hijos: $e', tag: 'PADRE_HOME');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescarHijos() async {
    await _cargarHijos();
  }

  // Método para navegar a la información académica del hijo
  void _navigateToInfoAcademica(Estudiante hijo) {
    DebugLogger.info('Navegando a información académica del hijo: ${hijo.nombreCompleto}', tag: 'PADRE_HOME');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InfoAcademicaHijoScreen(hijo: hijo),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthService>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header moderno con gradiente
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar manual con acciones
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.family_restroom_rounded,
                          color: isDarkMode 
                            ? const Color(0xFF2E3B42)
                            : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portal Padre/Madre',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AsistIA - Aula Inteligente',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Acciones del AppBar
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: _refrescarHijos,
                        tooltip: 'Actualizar lista',
                      ),
                      const NotificationIconWidget(),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _showLogoutDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Cerrar Sesión'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Header Card con información del padre
                  _buildHeaderCard(),
                ],
              ),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: _buildHijosContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.usuario?.nombreCompleto ?? 'Padre/Madre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (authService.correo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authService.correo!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hijos != null 
                        ? '${_hijos!.length} hijo${_hijos!.length == 1 ? '' : 's'} registrado${_hijos!.length == 1 ? '' : 's'}'
                        : 'Cargando...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode 
                        ? const Color(0xFF2E3B42)
                        : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijosContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando información de los hijos...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar información',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarHijos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_hijos == null || _hijos!.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.family_restroom_outlined,
        title: 'No hay hijos registrados',
        subtitle: 'No se encontraron hijos asociados a su cuenta',
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarHijos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hijos!.length,
        itemBuilder: (context, index) {
          final hijo = _hijos![index];
          return _buildModernHijoCard(hijo, index);
        },
      ),
    );
  }

  Widget _buildModernHijoCard(Estudiante hijo, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToInfoAcademica(hijo),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar moderno con gradiente
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getGradientForChild(index),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _getGradientForChild(index)[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      hijo.nombre.substring(0, 1) + hijo.apellido.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Información del hijo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hijo.nombreCompleto,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cake_rounded,
                                  size: 14,
                                  color: const Color(0xFF2196F3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatearFecha(hijo.fechaNacimiento),
                                  style: TextStyle(
                                    color: const Color(0xFF2196F3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hijo.direccionCasa.isNotEmpty 
                                ? hijo.direccionCasa 
                                : 'Dirección no disponible',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Indicador de navegación
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares
  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final edad = now.year - fecha.year;
    return '$edad años';
  }

  List<Color> _getGradientForChild(int index) {
    final gradients = [
      [const Color(0xFF2E3B42), const Color(0xFF607D8B)],
      [const Color(0xFFFFC107), const Color(0xFFFFB300)],
      [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
      [const Color(0xFF2196F3), const Color(0xFF1976D2)],
      [const Color(0xFFE91E63), const Color(0xFFC2185B)],
      [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
    ];
    return gradients[index % gradients.length];
  }
}
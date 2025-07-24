// lib/screens/asistencia/lista_asistencia_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/curso_provider.dart';
import '../../models/asistencia.dart';
import '../../utils/debug_logger.dart';
import '../../widgets/search_header_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/asistencia_item.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/sesion_asistencia_service.dart';
import '../../widgets/sesion_status_widget.dart';

class ListaAsistenciaScreen extends StatefulWidget {
  static const routeName = '/asistencia';

  const ListaAsistenciaScreen({Key? key}) : super(key: key);

  @override
  _ListaAsistenciaScreenState createState() => _ListaAsistenciaScreenState();
}

class _ListaAsistenciaScreenState extends State<ListaAsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;
  String _searchQuery = '';
  bool _localeInitialized = false;
  bool _isCreatingSession = false;
  late SesionAsistenciaService _sesionService;
  final TextEditingController _searchController = TextEditingController();
  bool _haySesionActiva = false;
  String? _nombreSesionActiva;
  int? _estudiantesPresentes = 0;
  int? _sesionActivaId;
  Timer? _timerActualizacion;
  bool _isCerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    // Inicializar el servicio de sesiones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _sesionService = SesionAsistenciaService(authService);
      _cargarAsistencia();
      _verificarSesionActiva();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timerActualizacion?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _cargarAsistencia() async {
    if (!mounted) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);

    if (!cursoProvider.tieneSeleccionCompleta) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cursoId = cursoProvider.cursoSeleccionado!.id;
      final materiaId = cursoProvider.materiaSeleccionada!.id;

      // Configurar el provider con los datos actuales
      asistenciaProvider.setCursoId(materiaId.toString());
      asistenciaProvider.setMateriaId(materiaId);
      asistenciaProvider.setFechaSeleccionada(_fechaSeleccionada);

      // Cargar asistencias desde el backend para la fecha seleccionada
      await asistenciaProvider.cargarAsistenciasDesdeBackend(
        cursoId: cursoId,
        materiaId: materiaId,
        fecha: _fechaSeleccionada,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar asistencia: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verificarSesionActiva() async {
    try {
      final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
      if (!cursoProvider.tieneSeleccionCompleta) return;

      final sesiones = await _sesionService.obtenerMisSesiones(
        cursoId: cursoProvider.cursoSeleccionado!.id,
        materiaId: cursoProvider.materiaSeleccionada!.id,
        estado: 'activa',
      );

      if (sesiones.isNotEmpty && mounted) {
        final sesionActiva = sesiones.first;
        setState(() {
          _haySesionActiva = true;
          _nombreSesionActiva = sesionActiva['titulo'];
          _sesionActivaId = sesionActiva['id'];
        });

        // Obtener estadísticas de la sesión activa
        _obtenerEstadisticasSesion(sesionActiva['id']);
        // Iniciar polling para actualizar estudiantes presentes
        _iniciarActualizacionEstudiantes(sesionActiva['id']);
      }
    } catch (e) {
      DebugLogger.error('Error verificando sesión activa: $e');
    }
  }

  //Actualizar cantidad de estudiantes presentes
  void _iniciarActualizacionEstudiantes(int sesionId) {
    _timerActualizacion?.cancel(); // Cancelar timer anterior si existe
    _timerActualizacion = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_haySesionActiva) {
        timer.cancel();
        return;
      }
      _obtenerEstadisticasSesion(sesionId);
    });
  }

  // Obtener estadísticas de la sesión
  Future<void> _obtenerEstadisticasSesion(int sesionId) async {
    try {
      final estadisticas =
          await _sesionService.obtenerEstadisticasSesion(sesionId);

      if (mounted) {
        setState(() {
          _estudiantesPresentes =
              estadisticas['estadisticas']['presentes'] ?? 0;
        });
      }
    } catch (e) {
      DebugLogger.error('Error obteniendo estadísticas: $e');
    }
  }

  // Agregar este método para crear sesión automática
  Future<void> _crearSesionAutomatica() async {
    if (!mounted) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);

    if (!cursoProvider.tieneSeleccionCompleta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un curso y materia primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingSession = true;
    });

    try {
      // Obtener ubicación actual
      final location = await LocationService.instance.getCurrentLocation();

      if (location == null) {
        throw Exception(
            'No se pudo obtener la ubicación. Verifique los permisos.');
      }

      // Crear sesión automática
      final resultado = await _sesionService.crearSesionAutomatica(
        cursoId: cursoProvider.cursoSeleccionado!.id,
        materiaId: cursoProvider.materiaSeleccionada!.id,
        latitud: location['latitude']!,
        longitud: location['longitude']!,
      );

      if (resultado != null && mounted) {
        setState(() {
          _haySesionActiva = true;
          _nombreSesionActiva =
              resultado['data']?['titulo'] ?? 'Sesión de Asistencia';
          _estudiantesPresentes = 0; // Inicialmente 0
          _sesionActivaId = resultado['data']?['id'];
        });

        if (_sesionActivaId != null) {
          _iniciarActualizacionEstudiantes(_sesionActivaId!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Sesión creada exitosamente'),
                Text(
                  'Los estudiantes ya pueden marcar asistencia automáticamente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade100,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    if (_sesionActivaId == null) return;

    // Mostrar diálogo de confirmación
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro que desea cerrar la sesión de asistencia activa?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información importante:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Los estudiantes ya no podrán marcar asistencia\n'
                      '• La sesión se sincronizará con el sistema de evaluaciones\n'
                      '• Esta acción no se puede deshacer',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, proceder a cerrar la sesión
    if (confirmar == true && mounted) {
      await _ejecutarCierreSesion();
    }
  }

  // Método para ejecutar el cierre de sesión
  Future<void> _ejecutarCierreSesion() async {
    setState(() {
      _isCerrandoSesion = true;
    });

    try {
      // Llamar al servicio para cerrar la sesión
      final resultado = await _sesionService.cerrarSesion(_sesionActivaId!);

      if (resultado != null && mounted) {
        // Actualizar el estado local
        setState(() {
          _haySesionActiva = false;
          _nombreSesionActiva = null;
          _estudiantesPresentes = 0;
          _sesionActivaId = null;
        });

        // Cancelar el timer de actualización
        _timerActualizacion?.cancel();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultado['message'] ?? 'Sesión cerrada exitosamente',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Recargar la lista de asistencia
        await _cargarAsistencia();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al cerrar la sesión: ${error.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _cerrarSesion(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCerrandoSesion = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _fechaSeleccionada = newDate;
    });
    _cargarAsistencia();
  }

  String _mapearEstadoAsistencia(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'presente';
      case EstadoAsistencia.ausente:
        return 'ausente';
      case EstadoAsistencia.tardanza:
        return 'tardanza';
      case EstadoAsistencia.justificado:
        return 'justificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<CursoProvider, EstudiantesProvider, AsistenciaProvider>(
      builder: (context, cursoProvider, estudiantesProvider, asistenciaProvider,
          child) {
        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;

        if (!cursoProvider.tieneSeleccionCompleta) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const EmptyStateWidget(
              icon: Icons.class_outlined,
              title:
                  'Seleccione un curso y una materia para gestionar asistencias',
            ),
          );
        }

        // Cargar estudiantes cuando hay selección completa
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cursoSeleccionado != null && materiaSeleccionada != null) {
            estudiantesProvider.cargarEstudiantesPorMateria(
                cursoSeleccionado.id, materiaSeleccionada.id);
          }
        });

        // Filtrar estudiantes por búsqueda
        var estudiantes = _searchQuery.isEmpty
            ? estudiantesProvider.estudiantes
            : estudiantesProvider.buscarEstudiantes(_searchQuery);

        final asistencias = asistenciaProvider.asistenciasPorCursoYFecha(
            materiaSeleccionada!.id.toString(), _fechaSeleccionada);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Widget de estado de sesión (original)
              SesionStatusWidget(
                hasSesionActiva: _haySesionActiva,
                nombreSesion: _nombreSesionActiva,
                estudiantesPresentes: _estudiantesPresentes,
                onCerrarSesion: _isCerrandoSesion ? null : _cerrarSesion,
              ),

              // Barra de búsqueda con header modernizado
              SearchHeaderWidget(
                hintText: 'Buscar estudiante...',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                controller: _searchController,
                searchValue: _searchQuery,
                additionalWidget: Column(
                  children: [
                    // Header moderno con curso y materia
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fact_check_rounded,
                              color: isDarkMode
                                  ? const Color(0xFF2E3B42)
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro de Asistencia - AsistIA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${materiaSeleccionada.nombre} - ${cursoSeleccionado!.nombreCompleto}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selector de fecha
                    DateSelectorWidget(
                      selectedDate: _fechaSeleccionada,
                      onDateChanged: _onDateChanged,
                      localeInitialized: _localeInitialized,
                    ),
                  ],
                ),
              ),

              // Sección de asistencia automática moderna
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: isDarkMode
                                  ? const Color(0xFF2E3B42)
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asistencia Automática',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Los estudiantes podrán marcar asistencia automáticamente usando GPS',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingSession
                              ? null
                              : _crearSesionAutomatica,
                          icon: _isCreatingSession
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(_isCreatingSession
                              ? 'Creando sesión...'
                              : 'Iniciar Sesión GPS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Espacio adicional para mejor diseño
              const SizedBox(height: 5),

              // Información adicional sobre la asistencia GPS
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AsistIA - Sistema Inteligente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  // Eliminar método _buildEstudiantesList ya que no se usa

  // Método de guardado ya no necesario (solo GPS)
  // La asistencia se guarda automáticamente a través de las sesiones GPS
}

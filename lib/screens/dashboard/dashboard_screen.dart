// lib/screens/dashboard/dashboard_screen.dart
// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/curso_provider.dart';
import '../../providers/estudiantes_provider.dart';
import '../../providers/resumen_provider.dart';
import '../../screens/estudiantes/detalle_estudiante_screen.dart';
import '../../models/estudiante.dart';
import '../../models/resumen_materia.dart';
import '../../widgets/resumen_card.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool _dataLoaded = false;
  DateTime? _lastRefresh;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  // Cargar datos iniciales de forma optimizada
  Future<void> _cargarDatosIniciales() async {
    if (_dataLoaded && _isDataFresh()) return;

    final cursoProvider = Provider.of<CursoProvider>(context, listen: false);
    final estudiantesProvider =
        Provider.of<EstudiantesProvider>(context, listen: false);
    final resumenProvider =
        Provider.of<ResumenProvider>(context, listen: false);

    if (!cursoProvider.tieneSeleccionCompleta) return;

    final cursoSeleccionado = cursoProvider.cursoSeleccionado!;
    final materiaSeleccionada = cursoProvider.materiaSeleccionada!;

    try {
      // Cargar datos en paralelo para optimizar
      await Future.wait([
        resumenProvider.cargarResumenMateria(
          cursoSeleccionado.id,
          materiaSeleccionada.id,
        ),
        estudiantesProvider.cargarEstudiantesPorMateria(
          cursoSeleccionado.id,
          materiaSeleccionada.id,
        ),
      ]);

      _dataLoaded = true;
      _lastRefresh = DateTime.now();
    } catch (e) {
      // Error manejado por los providers individuales
      debugPrint('Error cargando datos del dashboard: $e');
    }
  }

  // Verificar si los datos están frescos (15 minutos)
  bool _isDataFresh() {
    if (_lastRefresh == null) return false;
    final now = DateTime.now();
    return now.difference(_lastRefresh!).inMinutes < 15;
  }

  // Método de refrescar datos (mantenido)
  Future<void> _refreshData({bool force = false}) async {
    if (!force && _isDataFresh()) return;
    await _cargarDatosIniciales();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer3<CursoProvider, EstudiantesProvider, ResumenProvider>(
      builder: (context, cursoProvider, estudiantesProvider, resumenProvider,
          child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        if (!cursoProvider.tieneSeleccionCompleta) {
          return _buildEmptyState();
        }

        final cursoSeleccionado = cursoProvider.cursoSeleccionado;
        final materiaSeleccionada = cursoProvider.materiaSeleccionada;

        if ((resumenProvider.isLoading || estudiantesProvider.isLoading) &&
            !_dataLoaded) {
          return _buildLoadingState();
        }

        if (resumenProvider.errorMessage != null) {
          return _buildErrorState(resumenProvider.errorMessage!);
        }

        final resumenMateria = resumenProvider.resumenMateria;
        final estudiantes = estudiantesProvider.estudiantes;

        if (resumenMateria == null && _dataLoaded) {
          return _buildNoDataState();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () => _refreshData(force: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header moderno con información del curso
                    _buildModernHeaderCard(context, cursoSeleccionado!,
                        materiaSeleccionada!, isDarkMode),

                    const SizedBox(height: 20),

                    if (resumenMateria != null) ...[
                      // Saludo personalizado y fecha
                      _buildWelcomeSection(context, isDarkMode),

                      const SizedBox(height: 20),

                      // Tarjetas principales de estadísticas con nuevo diseño
                      _buildModernMainStatsCards(context, resumenMateria),

                      const SizedBox(height: 20),

                      // Tarjetas detalladas con nuevo diseño
                      _buildModernDetailedStatsCards(context, resumenMateria),

                      // Sección de estudiantes modernizada
                      if (estudiantes.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildModernEstudiantesSection(
                            context, estudiantes, isDarkMode),
                      ],

                      // Análisis de datos modernizado
                      const SizedBox(height: 28),
                      _buildModernAnalisisSection(
                          context, resumenMateria, isDarkMode),
                    ],

                    const SizedBox(height: 80), // Espacio para el FAB
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildModernRefreshFAB(),
        );
      },
    );
  }

  Widget _buildModernHeaderCard(
      BuildContext context, curso, materia, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: isDarkMode ? const Color(0xFF2E3B42) : Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AsistIA - Aula Inteligente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
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
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        curso.nombreCompleto,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDarkMode) {
    final now = DateTime.now();
    final hora = now.hour;
    String saludo;

    if (hora < 12) {
      saludo = '¡Buenos días!';
    } else if (hora < 18) {
      saludo = '¡Buenas tardes!';
    } else {
      saludo = '¡Buenas noches!';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aquí tienes el resumen de tu clase',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMainStatsCards(
      BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: _buildModernResumenCard(
            context,
            titulo: 'Estudiantes',
            valor: resumen.totalEstudiantes.toString(),
            icono: Icons.people_rounded,
            color: const Color(0xFF2E3B42),
            subtitle: 'Total registrados',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernResumenCard(
            context,
            titulo: 'Asistencia',
            valor: '${resumen.promedioGeneral.asistencia.toStringAsFixed(1)}%',
            icono: Icons.calendar_today_rounded,
            color: _getColorForAsistencia(resumen.promedioGeneral.asistencia),
            subtitle: 'Promedio general',
          ),
        ),
      ],
    );
  }

  Widget _buildModernDetailedStatsCards(
      BuildContext context, ResumenMateriaCompleto resumen) {
    return Row(
      children: [
        Expanded(
          child: _buildModernResumenCard(
            context,
            titulo: resumen.tieneNotas ? 'Notas' : 'Sin Notas',
            valor: resumen.tieneNotas
                ? resumen.promedioGeneral.notas.toStringAsFixed(1)
                : 'N/A',
            icono: Icons.school_rounded,
            color: resumen.tieneNotas
                ? _getColorForNota(resumen.promedioGeneral.notas)
                : Colors.grey,
            subtitle: resumen.tieneNotas ? 'Promedio general' : 'No disponible',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernResumenCard(
            context,
            titulo: 'Participación',
            valor: resumen.promedioGeneral.participacion.toStringAsFixed(2),
            icono: Icons.record_voice_over_rounded,
            color: _getColorForParticipacion(
                resumen.promedioGeneral.participacion),
            subtitle: 'Promedio de intervenciones',
          ),
        ),
      ],
    );
  }

  Widget _buildModernResumenCard(
    BuildContext context, {
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required String subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up_rounded,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEstudiantesSection(
      BuildContext context, List<Estudiante> estudiantes, bool isDarkMode) {
    final estudiantesMuestra = estudiantes.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.people_rounded,
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Estudiantes Destacados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/estudiantes'),
              icon: Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Ver todos'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: estudiantesMuestra.map((estudiante) {
              final isLast = estudiantesMuestra.indexOf(estudiante) ==
                  estudiantesMuestra.length - 1;
              return Column(
                children: [
                  _buildModernEstudianteItem(context, estudiante),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                          height: 1,
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3)),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernEstudianteItem(
      BuildContext context, Estudiante estudiante) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetalleEstudianteScreen(
              estudianteId: estudiante.id.toString(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  estudiante.nombre.substring(0, 1) +
                      estudiante.apellido.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombreCompleto,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Asistencia: ${estudiante.porcentajeAsistencia.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getColorForAsistencia(
                              estudiante.porcentajeAsistencia),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAnalisisSection(
      BuildContext context, ResumenMateriaCompleto resumen, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Análisis Inteligente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAnalisisItem(
                context,
                'Rendimiento General',
                _getRendimientoTexto(resumen.promedioGeneral.asistencia),
                _getColorForAsistencia(resumen.promedioGeneral.asistencia),
                Icons.trending_up_rounded,
              ),
              const SizedBox(height: 16),
              Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              _buildAnalisisItem(
                context,
                'Participación Activa',
                _getParticipacionTexto(resumen.promedioGeneral.participacion),
                _getColorForParticipacion(
                    resumen.promedioGeneral.participacion),
                Icons.voice_chat_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalisisItem(BuildContext context, String titulo,
      String descripcion, Color color, IconData icono) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icono,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Estados de la aplicación (mantenidos)
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 72,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Selecciona un curso y materia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para ver el dashboard necesitas seleccionar\nun curso y materia primero',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando dashboard...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
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
              error,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _refreshData(force: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRefreshFAB() {
    return FloatingActionButton(
      onPressed: () => _refreshData(),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E3B42)
          : Colors.white,
      tooltip: 'Actualizar dashboard',
      child: const Icon(Icons.refresh_rounded),
    );
  }

  // Métodos auxiliares (mantenidos)
  Color _getColorForAsistencia(double asistencia) {
    if (asistencia >= 90) return const Color(0xFF4CAF50);
    if (asistencia >= 75) return const Color(0xFFFFC107);
    if (asistencia >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  Color _getColorForNota(double nota) {
    if (nota >= 8.5) return const Color(0xFF4CAF50);
    if (nota >= 7.0) return const Color(0xFFFFC107);
    if (nota >= 6.0) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  Color _getColorForParticipacion(double participacion) {
    if (participacion >= 4.0) return const Color(0xFF4CAF50);
    if (participacion >= 2.5) return const Color(0xFFFFC107);
    if (participacion >= 1.0) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }

  String _getRendimientoTexto(double asistencia) {
    if (asistencia >= 90) return 'Excelente rendimiento académico';
    if (asistencia >= 75) return 'Buen rendimiento, sigue así';
    if (asistencia >= 60) return 'Rendimiento regular, puede mejorar';
    return 'Necesita atención urgente';
  }

  String _getParticipacionTexto(double participacion) {
    if (participacion >= 4.0) return 'Participación muy activa en clase';
    if (participacion >= 2.5) return 'Buena participación estudiantil';
    if (participacion >= 1.0) return 'Participación moderada';
    return 'Necesita incentivar más participación';
  }
}

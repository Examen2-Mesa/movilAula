import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/seleccion/seleccion_curso_materia_screen.dart';
import '../../screens/asistencia/lista_asistencia_screen.dart';
import '../../screens/participacion/registro_participacion_screen.dart';
import '../../screens/estudiantes/lista_estudiantes_screen.dart';
import '../screens/login/login_screen.dart';
import 'theme_toggle_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer con información del usuario
            Flexible(
              flex: 0,
              child: _buildDrawerHeader(context),
            ),

            // Opciones de navegación - En scroll si es necesario
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Navegación principal
                    _buildModernListTile(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      color: const Color(0xFF2E3B42),
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed(HomeScreen.routeName);
                      },
                    ),
                    _buildDivider(context),

                    _buildModernListTile(
                      context,
                      icon: Icons.filter_list_rounded,
                      title: 'Cambiar Curso/Materia',
                      color: const Color(0xFF607D8B),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                            SeleccionCursoMateriaScreen.routeName);
                      },
                    ),
                    _buildDivider(context),

                    _buildModernListTile(
                      context,
                      icon: Icons.people_rounded,
                      title: 'Gestión de Asistencia',
                      color: const Color(0xFFFFC107),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                            ListaAsistenciaScreen.routeName);
                      },
                    ),
                   /* _buildModernListTile(
                      context,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Registro de Participación',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                            RegistroParticipacionScreen.routeName);
                      },
                    ),*/
                    _buildModernListTile(
                      context,
                      icon: Icons.school_rounded,
                      title: 'Lista de Estudiantes',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                            ListaEstudiantesScreen.routeName);
                      },
                    ),

                    const SizedBox(height: 16),
                    _buildDivider(context),

                    // Opciones de tema
                    _buildThemeSection(context),
                    _buildDivider(context),

                    // Opción para ver perfil
                    _buildModernListTile(
                      context,
                      icon: Icons.account_circle_rounded,
                      title: 'Mi Perfil',
                      color: Theme.of(context).primaryColor,
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                    ),

                    // Opción de cerrar sesión
                    _buildModernListTile(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión',
                      color: Colors.red,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor:
                                Theme.of(context).dialogBackgroundColor,
                            title: Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color),
                            ),
                            content: Text(
                              '¿Está seguro que desea cerrar sesión?',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.color),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Cerrar diálogo
                                  Navigator.of(context).pop(); // Cerrar drawer
                                  // Ejecutar logout después de la navegación
                                  Provider.of<AuthService>(context,
                                          listen: false)
                                      .logout();
                                  // Redirigir directamente al LoginScreen
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                    (route) => false,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('ACEPTAR'),
                              ),
                            ],
                          ),
                        );
                      },
                      isDestructive: true,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final usuario = authService.usuario;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
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
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color:
                          isDarkMode ? const Color(0xFF2E3B42) : Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AsistIA',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aula Inteligente',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: usuario != null
                          ? Text(
                              usuario.nombre.isNotEmpty &&
                                      usuario.apellido.isNotEmpty
                                  ? usuario.nombre.substring(0, 1) +
                                      usuario.apellido.substring(0, 1)
                                  : usuario.correo
                                      .substring(0, 1)
                                      .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nombreCompleto ?? 'Usuario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            usuario?.correo ??
                                authService.correo ??
                                'Sin correo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (usuario?.isDoc == true)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeProvider.themeIcon,
                color: const Color(0xFFFF9800),
                size: 20,
              ),
            ),
            title: Text(
              themeProvider.themeText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            trailing: const QuickThemeToggle(),
            onTap: () async {
              await themeProvider.toggleTheme();
            },
          ),
        );
      },
    );
  }

  Widget _buildModernListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDestructive
            ? color.withOpacity(0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDestructive
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDestructive ? color : null,
              ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Divider(
        color: Theme.of(context).dividerColor.withOpacity(0.3),
        thickness: 1,
        height: 1,
      ),
    );
  }
}

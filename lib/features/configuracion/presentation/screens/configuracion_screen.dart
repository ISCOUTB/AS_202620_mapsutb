import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/features/idioma/presentation/seleccion_idioma_screen.dart';
import 'package:mapsutb/l10n/app_localizations.dart';

/// Pantalla de configuración del sistema.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      children: [
        Text(
          l10n?.configTitulo ?? 'Configuración',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.azulOscuro,
          ),
        ),
        const SizedBox(height: 16),
        _OpcionConfiguracion(
          icono: Icons.notifications_outlined,
          titulo: l10n?.configNotificaciones ?? 'Notificaciones',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.configNotificacionesWeb ??
                      'Las notificaciones están desactivadas en la versión web.',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        _OpcionConfiguracion(
          icono: Icons.language,
          titulo: l10n?.configIdioma ?? 'Idioma',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => SeleccionIdiomaScreen(
                  siguiente: (ctx) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.of(ctx).canPop()) {
                        Navigator.of(ctx).pop();
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
          },
        ),
        _OpcionConfiguracion(
          icono: Icons.info_outline,
          titulo: l10n?.configAcercaDe ?? 'Acerca de',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'MAPSUTB',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  '© 2026 Universidad Tecnológica de Bolívar\nArquitectura de Software',
              children: [
                const SizedBox(height: 12),
                Text(
                  l10n?.acercaDeDescripcion ??
                      'Mapa interactivo y sistema de ruteo peatonal para el campus de la UTB.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OpcionConfiguracion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback? onTap;

  const _OpcionConfiguracion({
    required this.icono,
    required this.titulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.azulOscuro,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icono, color: Colors.white),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}
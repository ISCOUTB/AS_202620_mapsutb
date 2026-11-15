import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';

/// Pantalla de configuración. Es una base: agrega aquí tus opciones.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      children: const [
        Text(
          'Configuración',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.azulOscuro,
          ),
        ),
        SizedBox(height: 16),
        _OpcionConfiguracion(
          icono: Icons.notifications_outlined,
          titulo: 'Notificaciones',
        ),
        _OpcionConfiguracion(
          icono: Icons.language,
          titulo: 'Idioma',
        ),
        _OpcionConfiguracion(
          icono: Icons.info_outline,
          titulo: 'Acerca de',
        ),
      ],
    );
  }
}

class _OpcionConfiguracion extends StatelessWidget {
  final IconData icono;
  final String titulo;

  const _OpcionConfiguracion({required this.icono, required this.titulo});

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
        onTap: () {
          // TODO: acción de cada opción
        },
      ),
    );
  }
}
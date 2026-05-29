// =============================================================================
// Pestaña SIMBA — visor de cámara Raspberry Pi
// =============================================================================
//
// Contenido de la 6ª pestaña del SalomonBottomBar.
// Carga la IP del servidor guardada en Firestore para el usuario actual.
// Permite configurarla y abre la pantalla del stream MJPEG.
//
// Estilo visual: dark navy del proyecto (0xFF1a1a2e / 0xFF16213e / blue).
// =============================================================================

import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'simba_camera_screen.dart';
import 'login_screen.dart';

class SimbaTab extends StatefulWidget {
  const SimbaTab({super.key});

  @override
  State<SimbaTab> createState() => _SimbaTabState();
}

class _SimbaTabState extends State<SimbaTab> {
  final _authService = AuthService();

  String _serverIp = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServerIp();
  }

  Future<void> _loadServerIp() async {
    final ip = await _authService.getServerIp();
    if (!mounted) return;
    setState(() {
      _serverIp = ip;
      _isLoading = false;
    });
    if (ip.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showIpDialog(isFirst: true);
      });
    }
  }

  // ── Diálogo de configuración de IP ───────────────────────────────────────

  Future<void> _showIpDialog({bool isFirst = false}) async {
    final controller = TextEditingController(text: _serverIp);

    final newIp = await showDialog<String>(
      context: context,
      barrierDismissible: !isFirst,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        title: Text(
          isFirst ? 'Configura el servidor' : 'Cambiar IP del servidor',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFirst
                  ? 'Introduce la IP de la Raspberry Pi para conectarte a la cámara.'
                  : 'Introduce la nueva IP del servidor.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'IP del servidor',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
                hintText: 'Ej: 10.42.0.1',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                ),
                prefixIcon: const Icon(
                  Icons.router,
                  color: Colors.white54,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isFirst)
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) Navigator.pop(ctx, ip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newIp != null && newIp.isNotEmpty) {
      await _authService.saveServerIp(newIp);
      if (mounted) setState(() => _serverIp = newIp);
    }
  }

  // ── Navegar a la pantalla de cámara ──────────────────────────────────────

  void _openCamera() {
    if (_serverIp.isEmpty) {
      _showIpDialog(isFirst: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimbaCameraScreen(
          serverIp: _serverIp,
          username: _authService.currentUser?.email ?? '',
        ),
      ),
    );
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Stack(
      children: [
        // Fondo con patrón sutil
        Container(color: const Color(0xFF1a1a2e)),

        // Contenido principal
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Icono de cámara ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.videocam,
                          size: 56,
                          color: Colors.blue.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Email del usuario ────────────────────────
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Estado de la IP ──────────────────────────
                      _serverIp.isNotEmpty
                          ? GestureDetector(
                              onTap: _showIpDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.router,
                                      size: 14,
                                      color: Colors.green.shade400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _serverIp,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _showIpDialog(isFirst: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 14,
                                      color: Colors.orange.shade400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sin IP configurada · Pulsa para añadir',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 40),

                      // ── Botón Ver Cámara ─────────────────────────
                      SizedBox(
                        width: 200,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openCamera,
                          icon: const Icon(Icons.play_circle_outline, size: 22),
                          label: const Text('Ver Cámara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        // ── Botones superiores (lado izquierdo para no solapar con
        //    el selector de idioma que Principal coloca en top-right) ──────
        Positioned(
          top: 16,
          left: 10,
          child: Row(
            children: [
              // Configurar IP
              IconButton(
                icon: const Icon(Icons.settings_ethernet, color: Colors.white54),
                tooltip: 'Cambiar IP',
                onPressed: _showIpDialog,
              ),
              // Cerrar sesión
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white54),
                tooltip: 'Cerrar sesión',
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

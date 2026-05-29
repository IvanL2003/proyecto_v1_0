// =============================================================================
// Pantalla del visor de cámara SIMBA (Raspberry Pi)
// =============================================================================
//
// Muestra el stream MJPEG de la cámara montada en las gafas, retransmitido
// desde la Raspberry Pi mediante un servidor Flask (puerto 5000).
//
// Flujo de conexión:
//   1. Pre-chequeo TCP (8 s timeout) — falla rápido si no hay servidor.
//   2. Si el socket conecta, se carga el WebView con la URL del stream.
//   3. onerror del <img> HTML → avisa a Flutter si /video_feed falla.
//   4. onWebResourceError → fallback para errores de carga del WebView.
//
// Controles inferiores: cambiar el modelo activo en la Raspberry Pi
//   (LSE, Semáforos, Parar) mediante POST /set_mode.
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SimbaCameraScreen extends StatefulWidget {
  final String serverIp;
  final String username;

  const SimbaCameraScreen({
    super.key,
    required this.serverIp,
    required this.username,
  });

  @override
  State<SimbaCameraScreen> createState() => _SimbaCameraScreenState();
}

class _SimbaCameraScreenState extends State<SimbaCameraScreen> {
  late WebViewController _controller;

  bool _isLoading = true;
  bool _hasError = false;
  bool _webViewReady = false;
  String _errorDetail = '';
  String? _activeMode;

  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    _baseUrl = _buildBaseUrl();
    _connectAndLoad();
  }

  String _buildBaseUrl() {
    String ip = widget.serverIp.trim();
    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      ip = 'http://$ip';
    }
    final uri = Uri.parse(ip);
    if (!uri.hasPort || uri.port == 80 || uri.port == 443) {
      return '${uri.scheme}://${uri.host}:5000';
    }
    return ip;
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorDetail = '';
      _webViewReady = false;
    });

    final uri = Uri.parse(_baseUrl);
    final host = uri.host;
    final port = uri.hasPort ? uri.port : 5000;

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 8),
      );
      socket.destroy();
      if (mounted) _initWebView();
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorDetail = _friendlySocketError(e, host, port);
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorDetail =
              'Tiempo de espera agotado (8 s).\nVerifica que estás en la misma red WiFi que la Raspberry Pi.';
        });
      }
    }
  }

  String _friendlySocketError(SocketException e, String host, int port) {
    final msg = e.message.toLowerCase();
    if (msg.contains('refused')) {
      return 'Conexión rechazada.\n$host:$port está accesible pero el servidor Flask no está arrancado.\nEjecuta: python server.py';
    }
    if (msg.contains('host') ||
        msg.contains('network') ||
        msg.contains('unreachable')) {
      return 'Host no encontrado ($host).\nVerifica que la IP es correcta y que el móvil está en la misma red WiFi.';
    }
    return 'No se pudo conectar a $host:$port.\n${e.message}';
  }

  void _initWebView() {
    final streamUrl = '$_baseUrl/video_feed';

    final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          background: #000;
          display: flex;
          align-items: center;
          justify-content: center;
          width: 100vw;
          height: 100vh;
          overflow: hidden;
        }
        img { max-width: 100%; max-height: 100%; object-fit: contain; }
      </style>
    </head>
    <body>
      <img
        src="$streamUrl"
        alt="Stream"
        onerror="SimbaChannel.postMessage('stream_error')"
      />
    </body>
    </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'SimbaChannel',
        onMessageReceived: (msg) {
          if (msg.message == 'stream_error' && mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorDetail =
                  'El servidor responde pero /video_feed no está disponible.\nVerifica que server.py está ejecutándose.';
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorDetail =
                    'Error de red en el WebView: ${error.description}';
              });
            }
          },
          onHttpAuthRequest: (request) {
            request.onProceed(
              WebViewCredential(user: widget.username, password: ''),
            );
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: _baseUrl);

    if (mounted) setState(() => _webViewReady = true);
  }

  void _reload() => _connectAndLoad();

  Future<void> _setMode(String mode) async {
    final js = '''
      fetch('$_baseUrl/set_mode', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({mode: '$mode'})
      }).then(r => r.json()).catch(() => null);
    ''';
    try {
      await _controller.runJavaScript(js);
      if (mounted) setState(() => _activeMode = mode == 'stop' ? null : mode);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¿Sigue conectado el servidor?',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF16213e),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Cámara en vivo',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reintentar',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Zona del stream ────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasError)
                  _SimbaErrorView(
                    onRetry: _reload,
                    serverUrl: '$_baseUrl/video_feed',
                    detail: _errorDetail,
                  )
                else if (_webViewReady)
                  WebViewWidget(controller: _controller)
                else
                  const ColoredBox(color: Colors.black),

                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Conectando al servidor...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Barra de controles ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF16213e),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SimbaMode(
                  label: 'LSE',
                  icon: Icons.sign_language,
                  isActive: _activeMode == 'lse',
                  enabled: !_hasError && !_isLoading && _webViewReady,
                  onPressed: () => _setMode('lse'),
                ),
                _SimbaMode(
                  label: 'Semáforos',
                  icon: Icons.traffic,
                  isActive: _activeMode == 'semaforos',
                  enabled: !_hasError && !_isLoading && _webViewReady,
                  onPressed: () => _setMode('semaforos'),
                ),
                _SimbaMode(
                  label: 'Parar',
                  icon: Icons.stop_circle_outlined,
                  isActive: _activeMode == null,
                  enabled: !_hasError && !_isLoading && _webViewReady,
                  onPressed: () => _setMode('stop'),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón de modo ─────────────────────────────────────────────────────────────

class _SimbaMode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressed;
  final Color? color;

  const _SimbaMode({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.blue;
    final effectiveColor = enabled ? activeColor : Colors.white24;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive && enabled
              ? activeColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive && enabled ? activeColor : Colors.white24,
            width: isActive && enabled ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive && enabled ? effectiveColor : Colors.white24,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive && enabled ? effectiveColor : Colors.white24,
                fontSize: 11,
                fontWeight:
                    isActive && enabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vista de error ────────────────────────────────────────────────────────────

class _SimbaErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String serverUrl;
  final String detail;

  const _SimbaErrorView({
    required this.onRetry,
    required this.serverUrl,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.signal_wifi_off,
                size: 60,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin conexión al servidor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                serverUrl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

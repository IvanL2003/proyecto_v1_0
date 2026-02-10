import 'package:flutter/material.dart';
import 'dart:async';
import 'models/hand_detection_result.dart';
import 'services/hand_detection_service.dart';
import 'services/sign_language_api_service.dart';
import 'widgets/native_camera_preview.dart';

class PantallaCurso extends StatefulWidget {
  const PantallaCurso({super.key});

  @override
  State<PantallaCurso> createState() => _PantallaCursoState();
}

class _PantallaCursoState extends State<PantallaCurso> {
  final HandDetectionService _detectionService = HandDetectionService();
  final SignLanguageApiService _apiService = SignLanguageApiService(
    baseUrl: 'https://subcruciform-treacherously-sam.ngrok-free.dev', // ngrok tunnel publico
  );

  StreamSubscription<HandDetectionResult>? _landmarkSubscription;
  bool _cameraReady = false;
  int _handsDetected = 0;
  bool _isSendingToApi = false;

  // Variables del juego
  final List<String> _palabras = [
    'Hola', 'Gracias', 'Por favor', 'Adios', 'Si', 'No',
    'Tiempo', 'Persona', 'Rojo', 'Azul', 'Verde', 'Amarillo'
  ];

  int _palabraActualIndex = 0;
  int _vidas = 5;
  int _intentos = 3;
  int _tiempoRestante = 10;
  int _puntuacion = 0;
  Timer? _timer;
  bool _juegoIniciado = false;
  bool _juegoTerminado = false;
  bool _esperandoRespuesta = false;

  String get _palabraActual => _palabras[_palabraActualIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDetection();
    });
  }

  Future<void> _startDetection() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      _landmarkSubscription = _detectionService.landmarkStream.listen(
        _onLandmarkData,
      );

      await _detectionService.startDetectionWithPreview();

      if (mounted) {
        setState(() {
          _cameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Error iniciando deteccion: $e');
    }
  }

  void _onLandmarkData(HandDetectionResult result) {
    if (!mounted) return;

    setState(() {
      _handsDetected = result.hands.length;
    });

    // Solo enviar a la API si el juego esta en marcha y hay mano detectada
    if (_juegoIniciado && !_esperandoRespuesta && result.hasHands && !_isSendingToApi) {
      _enviarAApi(result.firstHand!);
    }
  }

  Future<void> _enviarAApi(HandData handData) async {
    if (_isSendingToApi) return;
    _isSendingToApi = true;

    try {
      final response = await _apiService.sendLandmarks(
        handData: handData,
        palabraObjetivo: _palabraActual,
      );

      if (mounted && response != null && _juegoIniciado && !_esperandoRespuesta) {
        if (response['correcto'] == true) {
          _verificarRespuesta(true);
        }
      }
    } catch (e) {
      // No bloquear el juego si la API falla
    }

    // Throttle: esperar antes del siguiente envio
    await Future.delayed(const Duration(seconds: 1));
    _isSendingToApi = false;
  }

  void _iniciarJuego() {
    setState(() {
      _juegoIniciado = true;
      _juegoTerminado = false;
      _vidas = 5;
      _puntuacion = 0;
      _palabraActualIndex = 0;
      _intentos = 3;
      _palabras.shuffle();
    });
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    setState(() {
      _tiempoRestante = 10;
      _esperandoRespuesta = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _tiempoRestante--;
      });

      if (_tiempoRestante <= 0) {
        timer.cancel();
        _verificarRespuesta(false);
      }
    });
  }

  void _verificarRespuesta(bool correcto) {
    if (_esperandoRespuesta) return;

    setState(() {
      _esperandoRespuesta = true;
    });

    _timer?.cancel();

    if (correcto) {
      setState(() {
        _puntuacion += 10;
      });
      _mostrarFeedback(true);

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _siguientePalabra();
      });
    } else {
      setState(() {
        _intentos--;
      });

      if (_intentos <= 0) {
        setState(() {
          _vidas--;
          _intentos = 3;
        });

        if (_vidas <= 0) {
          _finalizarJuego();
          return;
        }

        _mostrarFeedback(false);
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _siguientePalabra();
        });
      } else {
        _mostrarFeedback(false);
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _iniciarTemporizador();
        });
      }
    }
  }

  void _mostrarFeedback(bool correcto) {
    final snackBar = SnackBar(
      content: Text(
        correcto ? '!Correcto! +10 puntos' : '!Incorrecto! Intentos: $_intentos',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: correcto ? Colors.green : Colors.red,
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _siguientePalabra() {
    if (_palabraActualIndex < _palabras.length - 1) {
      setState(() {
        _palabraActualIndex++;
      });
      _iniciarTemporizador();
    } else {
      _finalizarJuego();
    }
  }

  void _finalizarJuego() {
    _timer?.cancel();
    setState(() {
      _juegoTerminado = true;
      _juegoIniciado = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _landmarkSubscription?.cancel();
    _detectionService.stopDetection();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Column(
        children: [
          // Mitad superior - Camara nativa
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Preview de camara nativo (CameraX via PlatformView)
                    const NativeCameraPreview(),

                    // HUD Superior - Vidas y Puntuacion
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Vidas
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'x $_vidas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Puntuacion
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '$_puntuacion pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indicador de mano detectada
                    Positioned(
                      top: 70,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _handsDetected > 0
                              ? Colors.green.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _handsDetected > 0
                                  ? Icons.back_hand
                                  : Icons.back_hand_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _handsDetected > 0 ? 'Mano detectada' : 'Sin mano',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Temporizador circular
                    if (_juegoIniciado)
                      Positioned(
                        top: 80,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$_tiempoRestante',
                                style: TextStyle(
                                  color: _tiempoRestante <= 3 ? Colors.red : Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Loading mientras no esta lista la camara
                    if (!_cameraReady)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Mitad inferior - Juego
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _juegoTerminado
                  ? _buildPantallaFinal()
                  : _juegoIniciado
                  ? _buildPantallaJuego()
                  : _buildPantallaInicio(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaInicio() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.school,
          size: 80,
          color: Colors.white,
        ),
        const SizedBox(height: 20),
        const Text(
          'Modo Curso',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: const [],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _iniciarJuego,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0f3460),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            '!Comenzar!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaJuego() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Palabra a realizar
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'Realiza el signo:',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _palabraActual,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Indicadores de intentos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                index < _intentos ? Icons.circle : Icons.circle_outlined,
                color: Colors.white,
                size: 20,
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        Text(
          'Intentos restantes: $_intentos',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 20),

        // Progreso
        Text(
          'Palabra ${_palabraActualIndex + 1} de ${_palabras.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 10),

        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_palabraActualIndex + 1) / _palabras.length,
            minHeight: 8,
            backgroundColor: const Color(0xFF0f3460),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaFinal() {
    final bool ganado = _vidas > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          ganado ? Icons.emoji_events : Icons.sentiment_dissatisfied,
          size: 60,
          color: Colors.white,
        ),
        const SizedBox(height: 12),
        Text(
          ganado ? '!Felicitaciones!' : 'Juego Terminado',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'Puntuacion Final',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_puntuacion',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vidas restantes: $_vidas',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white54,
                ),
              ),
              Text(
                'Palabras completadas: $_palabraActualIndex',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _iniciarJuego,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0f3460),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Jugar de Nuevo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

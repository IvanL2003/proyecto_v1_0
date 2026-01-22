import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class PantallaCurso extends StatefulWidget {
  const PantallaCurso({super.key});

  @override
  State<PantallaCurso> createState() => _PantallaCursoState();
}

class _PantallaCursoState extends State<PantallaCurso> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  // Variables del juego
  final List<String> _palabras = [
    'Hola', 'Gracias', 'Por favor', 'Adiós', 'Sí', 'No',
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
  String _detectedSign = "";
  bool _esperandoRespuesta = false;

  String get _palabraActual => _palabras[_palabraActualIndex];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        print('No se encontraron cámaras');
        return;
      }

      CameraDescription frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        frontCamera = _cameras!.first;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Simular detección continua
      _cameraController!.startImageStream((CameraImage image) {
        if (_juegoIniciado && !_esperandoRespuesta) {
          _simularDeteccion();
        }
      });
    } catch (e) {
      print('Error al inicializar la cámara: $e');
    }
  }

  void _simularDeteccion() {
    // Simulación: hay un 30% de probabilidad de detectar el signo correcto
    if (DateTime.now().millisecond % 10 < 3) {
      setState(() {
        _detectedSign = _palabraActual;
      });
      _verificarRespuesta(true);
    }
  }

  void _iniciarJuego() {
    setState(() {
      _juegoIniciado = true;
      _juegoTerminado = false;
      _vidas = 5;
      _puntuacion = 0;
      _palabraActualIndex = 0;
      _intentos = 3;
      _palabras.shuffle(); // Mezclar palabras
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
      // Respuesta correcta
      setState(() {
        _puntuacion += 10;
      });
      _mostrarFeedback(true);

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _siguientePalabra();
      });
    } else {
      // Respuesta incorrecta
      setState(() {
        _intentos--;
      });

      if (_intentos <= 0) {
        // Se acabaron los intentos, restar vida
        setState(() {
          _vidas--;
          _intentos = 3;
        });

        if (_vidas <= 0) {
          // Game Over
          _finalizarJuego();
          return;
        }

        _mostrarFeedback(false);
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _siguientePalabra();
        });
      } else {
        // Aún quedan intentos
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
        correcto ? '¡Correcto! +10 puntos' : '¡Incorrecto! Intentos: $_intentos',
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
        _detectedSign = "";
      });
      _iniciarTemporizador();
    } else {
      // Todas las palabras completadas
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
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CE489),
      body: Column(
        children: [
          // Mitad superior - Cámara
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
                child: _isInitialized && _cameraController != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),

                          // HUD Superior - Vidas y Puntuación
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

                                // Puntuación
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
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),
          ),

          // Mitad inferior - Juego
          Expanded(
            flex: 1,
            child: Container(
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
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: const [
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _iniciarJuego,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            '¡Comenzar!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CE489),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Realiza el signo:',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _palabraActual,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CE489),
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
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),

        const SizedBox(height: 20),

        // Botón de simulación (para testing)
        ElevatedButton(
          onPressed: () => _verificarRespuesta(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text(
            'Simular Acierto (TEST)',
            style: TextStyle(color: Colors.white),
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
          size: 100,
          color: Colors.white,
        ),
        const SizedBox(height: 20),
        Text(
          ganado ? '¡Felicitaciones!' : 'Juego Terminado',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Puntuación Final',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_puntuacion',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CE489),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Vidas restantes: $_vidas',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Palabras completadas: $_palabraActualIndex',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _iniciarJuego,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Jugar de Nuevo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CE489),
            ),
          ),
        ),
      ],
    );
  }
}

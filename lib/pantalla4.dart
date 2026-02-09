import 'package:flutter/material.dart';
import 'dart:async';
import 'models/hand_detection_result.dart';
import 'services/hand_detection_service.dart';
import 'services/sign_language_api_service.dart';
import 'widgets/native_camera_preview.dart';

class Pantalla4 extends StatefulWidget {
  const Pantalla4({super.key});

  @override
  State<Pantalla4> createState() => _Pantalla4State();
}

class _Pantalla4State extends State<Pantalla4> {
  final HandDetectionService _detectionService = HandDetectionService();
  final SignLanguageApiService _apiService = SignLanguageApiService(
    baseUrl: 'https://subcruciform-treacherously-sam.ngrok-free.dev', // ngrok tunnel publico
  );

  StreamSubscription<HandDetectionResult>? _landmarkSubscription;
  bool _isDetecting = false;
  bool _cameraReady = false;
  String _detectedSign = "Esperando...";
  double _confidence = 0.0;
  bool _isProcessingApi = false;
  int _handsDetected = 0;

  @override
  void initState() {
    super.initState();
    // Esperar un frame para que el AndroidView se monte antes de iniciar deteccion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDetection();
    });
  }

  Future<void> _startDetection() async {
    // Delay para asegurar que el AndroidView (NativeCameraPreview)
    // esta completamente montado y el PreviewView esta registrado
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Escuchar el stream de landmarks
      _landmarkSubscription = _detectionService.landmarkStream.listen(
        _onLandmarkData,
      );

      // Iniciar deteccion con preview
      await _detectionService.startDetectionWithPreview();

      if (mounted) {
        setState(() {
          _isDetecting = true;
          _cameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detectedSign = "Error: $e";
        });
      }
    }
  }

  void _onLandmarkData(HandDetectionResult result) {
    if (!mounted) return;

    final hadHands = _handsDetected > 0;

    setState(() {
      _handsDetected = result.hands.length;
    });

    // Si deja de detectar manos, limpiar resultado
    if (hadHands && _handsDetected == 0) {
      setState(() {
        _detectedSign = "Esperando...";
        _confidence = 0.0;
      });
    }

    if (result.hasHands && !_isProcessingApi) {
      _sendToApi(result.firstHand!);
    }
  }

  Future<void> _sendToApi(HandData handData) async {
    if (_isProcessingApi) return;
    _isProcessingApi = true;

    try {
      final response = await _apiService.sendLandmarks(
        handData: handData,
        palabraObjetivo: '', // Pantalla4 no tiene palabra objetivo (modo libre)
      );

      if (mounted && response != null) {
        setState(() {
          if (response['correcto'] == true) {
            _detectedSign = response['mensaje'] ?? 'Gesto reconocido';
            _confidence = (response['confianza'] as num?)?.toDouble() ?? 0.0;
          } else {
            _detectedSign = response['mensaje'] ?? 'Analizando...';
            _confidence = (response['confianza'] as num?)?.toDouble() ?? 0.0;
          }
        });
      }
    } catch (e) {
      // No bloquear al usuario si falla la API
      if (mounted) {
        setState(() {
          _detectedSign = _handsDetected > 0
              ? 'Mano detectada (API no disponible)'
              : 'Esperando...';
        });
      }
    }

    // Throttle: esperar 1 segundo antes del siguiente envio
    await Future.delayed(const Duration(seconds: 1));
    _isProcessingApi = false;
  }

  @override
  void dispose() {
    _landmarkSubscription?.cancel();
    _detectionService.stopDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CE489),
      body: Column(
        children: [
          // Mitad superior - Preview de camara nativo
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

                    // Label de camara frontal
                    Positioned(
                      top: 40,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.camera_front,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Camara Frontal',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Indicador de manos detectadas
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _handsDetected > 0
                              ? Colors.green.withOpacity(0.8)
                              : Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _handsDetected > 0
                              ? Icons.back_hand
                              : Icons.back_hand_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Loading mientras no esta lista la camara
                    if (!_cameraReady)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Iniciando camara...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Mitad inferior - Resultados de deteccion
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Deteccion de Lenguaje de Signos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Resultado principal - solo visible cuando hay mano
                  if (_handsDetected > 0 && _detectedSign != "Esperando...")
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            'Signo detectado:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _detectedSign,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CE489),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    )
                  else
                    // Mensaje cuando no hay mano
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.back_hand_outlined,
                            color: Colors.white.withOpacity(0.7),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Esperando mano...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Informacion adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            'Coloca tu mano frente a la camara',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

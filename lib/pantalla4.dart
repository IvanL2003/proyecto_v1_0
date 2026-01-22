import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class Pantalla4 extends StatefulWidget {
  const Pantalla4({super.key});

  @override
  State<Pantalla4> createState() => _Pantalla4State();
}

class _Pantalla4State extends State<Pantalla4> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String _detectedSign = "Esperando...";
  double _confidence = 0.0;
  bool _isProcessing = false;

  static const platform = MethodChannel('com.example.proyecto_v1_0/sign_language');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSignDetection();
  }

  Future<void> _initializeCamera() async {
    try {
      // Obtener todas las c�maras disponibles
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        print('No se encontraron c�maras');
        return;
      }

      // Buscar la c�mara frontal
      CameraDescription frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // Si no hay c�mara frontal, usar la primera disponible
        frontCamera = _cameras!.first;
      }

      // Inicializar el controlador con resoluci�n media para mejor rendimiento
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

      // Iniciar el stream de im�genes para procesamiento
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processImage(image);
        }
      });
    } catch (e) {
      print('Error al inicializar la camara: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;

    try {
      // Aqu� llamar�as al c�digo Python a trav�s del MethodChannel
      // Por ahora, simulamos la detecci�n
      final result = await platform.invokeMethod('detectSign', {
        'width': image.width,
        'height': image.height,
        'planes': image.planes.map((plane) => {
          'bytes': plane.bytes,
          'bytesPerRow': plane.bytesPerRow,
        }).toList(),
      });

      if (mounted) {
        setState(() {
          _detectedSign = result['sign'] ?? 'Desconocido';
          _confidence = result['confidence'] ?? 0.0;
        });
      }
    } catch (e) {
      // Si el metodo nativo no est� implementado, usar datos simulados
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _detectedSign = _getDemoSign();
          _confidence = 0.85;
        });
      }
    }

    _isProcessing = false;
  }

  String _getDemoSign() {
    // Simula detecci�n rotando entre diferentes signos
    final signs = ['Hola', 'Gracias', 'Por favor', 'Adios', 'Si', 'No'];
    return signs[DateTime.now().second % signs.length];
  }

  void _startSignDetection() {
    // Timer para actualizar la detecci�n peri�dicamente
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CE489),
      body: Column(
        children: [
          // Mitad superior - Preview de c�mara
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
                          // Indicador de procesamiento
                          if (_isProcessing)
                            Positioned(
                              top: 40,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Iniciando c�mara...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // Mitad inferior - Resultados de detecci�n
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // T�tulo
                  const Text(
                    'Deteccion de Lenguaje de Signos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Resultado principal
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
                          'Signo detectado:',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _detectedSign,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CE489),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informaci�n adicional
                  Container(
                    padding: const EdgeInsets.all(16),
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

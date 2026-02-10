import 'dart:async';
import 'package:flutter/services.dart';
import '../models/hand_detection_result.dart';

/// Servicio singleton que encapsula la comunicacion con el plugin nativo
/// de MediaPipe para deteccion de manos.
///
/// Expone un stream de [HandDetectionResult] que las pantallas pueden
/// escuchar para recibir landmarks en tiempo real.
class HandDetectionService {
  static final HandDetectionService _instance = HandDetectionService._internal();
  factory HandDetectionService() => _instance;
  HandDetectionService._internal();

  static const _methodChannel =
      MethodChannel('com.example.proyecto_v1_0/hand_landmark');
  static const _eventChannel =
      EventChannel('com.example.proyecto_v1_0/hand_landmark_stream');

  StreamSubscription? _streamSubscription;
  final StreamController<HandDetectionResult> _resultController =
      StreamController<HandDetectionResult>.broadcast();

  bool _isDetecting = false;
  HandDetectionResult? _lastResult;

  /// Stream de resultados de deteccion en tiempo real.
  Stream<HandDetectionResult> get landmarkStream => _resultController.stream;

  /// Si la deteccion esta activa.
  bool get isDetecting => _isDetecting;

  /// Ultimo resultado recibido (puede ser null si no se ha detectado nada aun).
  HandDetectionResult? get lastResult => _lastResult;

  /// Inicia la deteccion de manos en modo headless (sin preview de camara).
  /// Usado por test_pantalla_curso.
  Future<void> startDetection() async {
    if (_isDetecting) return;

    _setupStreamListener();

    try {
      await _methodChannel.invokeMethod('startHandDetection');
      _isDetecting = true;
    } on PlatformException catch (e) {
      _isDetecting = false;
      _streamSubscription?.cancel();
      rethrow;
    }
  }

  /// Inicia la deteccion de manos CON preview de camara.
  /// El AndroidView con el PreviewView debe estar ya montado en el widget tree
  /// antes de llamar a este metodo.
  Future<void> startDetectionWithPreview() async {
    if (_isDetecting) return;

    _setupStreamListener();

    try {
      await _methodChannel.invokeMethod('startHandDetectionWithPreview');
      _isDetecting = true;
    } on PlatformException catch (e) {
      _isDetecting = false;
      _streamSubscription?.cancel();
      rethrow;
    }
  }

  /// Detiene la deteccion y libera recursos.
  Future<void> stopDetection() async {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    try {
      await _methodChannel.invokeMethod('stopHandDetection');
    } catch (e) {
      // Ignorar errores al detener (puede que ya este detenido)
    }

    _isDetecting = false;
    _lastResult = null;
  }

  void _setupStreamListener() {
    _streamSubscription?.cancel();
    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        if (data != null && data is Map) {
          final result = HandDetectionResult.fromMap(data);
          _lastResult = result;
          _resultController.add(result);
        }
      },
      onError: (error) {
        _isDetecting = false;
      },
    );
  }

  /// Libera todos los recursos. Llamar cuando la app se cierra.
  void dispose() {
    _streamSubscription?.cancel();
    _resultController.close();
  }
}

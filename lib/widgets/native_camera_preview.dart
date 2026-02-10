import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que muestra el preview de la camara nativa CameraX.
///
/// Usa un AndroidView para embedir el PreviewView nativo dentro del
/// widget tree de Flutter. Cuando este widget se monta, el lado nativo
/// (CameraPreviewFactory) crea el PreviewView y lo registra en
/// HandLandmarkPlugin_copia para que CameraX lo use como surface.
///
/// Uso:
/// ```dart
/// NativeCameraPreview()
/// ```
///
/// Debe montarse ANTES de llamar a
/// `HandDetectionService.startDetectionWithPreview()`.
class NativeCameraPreview extends StatelessWidget {
  const NativeCameraPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'com.example.proyecto_v1_0/camera_preview',
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

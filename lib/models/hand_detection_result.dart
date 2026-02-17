import 'dart:math';

/// Representa un punto landmark de la mano con coordenadas x, y, z.
class HandLandmark {
  final double x;
  final double y;
  final double z;

  HandLandmark({required this.x, required this.y, required this.z});

  factory HandLandmark.fromMap(Map<String, dynamic> map) {
    return HandLandmark(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, double> toMap() => {'coordx': x, 'coordy': y, 'coordz': z};
}

/// Datos de una mano detectada: landmarks, world landmarks, y clasificacion.
class HandData {
  final List<HandLandmark> landmarks;
  final List<HandLandmark> worldLandmarks;
  final String handedness;
  final double handednessScore;

  HandData({
    required this.landmarks,
    required this.worldLandmarks,
    required this.handedness,
    required this.handednessScore,
  });

  factory HandData.fromMap(Map<String, dynamic> map) {
    final landmarksList = (map['landmarks'] as List<dynamic>? ?? [])
        .map((lm) => HandLandmark.fromMap(Map<String, dynamic>.from(lm)))
        .toList();

    final worldLandmarksList = (map['worldLandmarks'] as List<dynamic>? ?? [])
        .map((lm) => HandLandmark.fromMap(Map<String, dynamic>.from(lm)))
        .toList();

    return HandData(
      landmarks: landmarksList,
      worldLandmarks: worldLandmarksList,
      handedness: map['handedness'] as String? ?? 'Unknown',
      handednessScore: (map['handednessScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte los landmarks al formato de la API:
  /// {"punto1": {"coordx": 0.5, "coordy": 0.3, "coordz": -0.01}, ...}
  Map<String, dynamic> landmarksToApiFormat() {
    final Map<String, dynamic> result = {};
    for (int i = 0; i < landmarks.length; i++) {
      result['punto${i + 1}'] = landmarks[i].toMap();
    }
    return result;
  }

  /// Normaliza landmarks: resta muñeca como origen y escala por distancia maxima.
  /// Mantiene formato punto1/punto2 con coordx/coordy/coordz.
  Map<String, dynamic> normalizedLandmarksToApiFormat() {
    if (landmarks.isEmpty) return {};

    final wx = landmarks[0].x;
    final wy = landmarks[0].y;
    final wz = landmarks[0].z;

    // Centrar respecto a la muñeca
    final centered = landmarks.map((lm) => [
      lm.x - wx,
      lm.y - wy,
      lm.z - wz,
    ]).toList();

    // Distancia maxima desde la muñeca
    double maxDist = 0.0;
    for (final p in centered) {
      final dist = sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
      if (dist > maxDist) maxDist = dist;
    }
    if (maxDist == 0.0) maxDist = 1.0;

    // Escalar y formatear
    final Map<String, dynamic> result = {};
    for (int i = 0; i < centered.length; i++) {
      result['punto${i + 1}'] = {
        'coordx': centered[i][0] / maxDist,
        'coordy': centered[i][1] / maxDist,
        'coordz': centered[i][2] / maxDist,
      };
    }
    return result;
  }

  /// Genera el payload completo para la API con landmarks normalizados.
  Map<String, dynamic> toApiPayload(String palabraObjetivo) {
    return {
      'palabra_objetivo': palabraObjetivo,
      'mano': handedness,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'landmarks': normalizedLandmarksToApiFormat(),
    };
  }
}

/// Resultado completo de deteccion: puede contener 0, 1 o 2 manos.
class HandDetectionResult {
  final List<HandData> hands;
  final int timestamp;

  HandDetectionResult({required this.hands, required this.timestamp});

  bool get hasHands => hands.isNotEmpty;

  /// La primera mano detectada (o null si no hay ninguna).
  HandData? get firstHand => hands.isNotEmpty ? hands.first : null;

  factory HandDetectionResult.fromMap(Map<dynamic, dynamic> map) {
    final handsList = (map['hands'] as List<dynamic>? ?? [])
        .map((hand) => HandData.fromMap(Map<String, dynamic>.from(hand)))
        .toList();

    return HandDetectionResult(
      hands: handsList,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}

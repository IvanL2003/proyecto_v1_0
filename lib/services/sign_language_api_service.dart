import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/hand_detection_result.dart';

/// Servicio para enviar coordenadas de landmarks a la API externa.
///
/// La API recibe las coordenadas de la mano y responde indicando
/// si el gesto es correcto o no.
///
/// Formato del payload enviado:
/// ```json
/// {
///   "palabra_objetivo": "Hola",
///   "mano": "Right",
///   "timestamp": 1644234567890,
///   "landmarks": {
///     "punto1": {"coordx": 0.5, "coordy": 0.3, "coordz": -0.01},
///     "punto2": {"coordx": 0.6, "coordy": 0.2, "coordz": -0.02},
///     ...
///     "punto21": {"coordx": 0.4, "coordy": 0.7, "coordz": -0.03}
///   }
/// }
/// ```
///
/// Respuesta esperada:
/// ```json
/// {
///   "correcto": true,
///   "confianza": 0.92,
///   "mensaje": "Gesto reconocido correctamente"
/// }
/// ```
class SignLanguageApiService {
  final String baseUrl;
  final http.Client _client;
  DateTime? _lastSentTime;
  static const _minInterval = Duration(milliseconds: 100);

  SignLanguageApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Envia las coordenadas de los landmarks a la API.
  ///
  /// Retorna el Map de la respuesta de la API, o null si fue throttled o hubo error.
  /// Incluye throttle interno de 0.1 segundos entre envios.
  Future<Map<String, dynamic>?> sendLandmarks({
    required HandData handData,
    required String palabraObjetivo,
  }) async {
    // Throttle: no enviar mas de una vez por segundo
    final now = DateTime.now();
    if (_lastSentTime != null &&
        now.difference(_lastSentTime!) < _minInterval) {
      return null;
    }
    _lastSentTime = now;

    try {
      final payload = handData.toApiPayload(palabraObjetivo);

      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/gestures'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

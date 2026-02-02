import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const TestPantallaCurso());
}

class TestPantallaCurso extends StatelessWidget {
  const TestPantallaCurso({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hand Landmarks Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HandLandmarksPage(),
    );
  }
}

class HandLandmarksPage extends StatefulWidget {
  const HandLandmarksPage({super.key});

  @override
  State<HandLandmarksPage> createState() => _HandLandmarksPageState();
}

class _HandLandmarksPageState extends State<HandLandmarksPage> {
  static const _methodChannel = MethodChannel('com.example.proyecto_v1_0/hand_landmark');
  static const _eventChannel = EventChannel('com.example.proyecto_v1_0/hand_landmark_stream');

  List<Map<String, dynamic>> _handsData = [];
  bool _isDetecting = false;
  String _statusMessage = 'Presiona el botón para iniciar';
  StreamSubscription? _streamSubscription;
  int _selectedHandIndex = 0;
  bool _showGraph = true;

  @override
  void dispose() {
    _stopDetection();
    super.dispose();
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _statusMessage = 'Iniciando cámara...';
    });

    try {
      _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
        (data) {
          if (data != null && data is Map) {
            final hands = data['hands'] as List<dynamic>? ?? [];
            setState(() {
              _handsData = hands.map((hand) => Map<String, dynamic>.from(hand)).toList();
              _statusMessage = hands.isEmpty
                  ? 'No se detectan manos'
                  : '${hands.length} mano(s) detectada(s)';
              if (_selectedHandIndex >= _handsData.length) {
                _selectedHandIndex = 0;
              }
            });
          }
        },
        onError: (error) {
          setState(() {
            _statusMessage = 'Error: $error';
            _isDetecting = false;
          });
        },
      );

      await _methodChannel.invokeMethod('startHandDetection');

    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.message}';
        _isDetecting = false;
      });
      _streamSubscription?.cancel();
    }
  }

  Future<void> _stopDetection() async {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    try {
      await _methodChannel.invokeMethod('stopHandDetection');
    } catch (e) {
      debugPrint('Error deteniendo detección: $e');
    }

    setState(() {
      _isDetecting = false;
      _statusMessage = 'Detección detenida';
      _handsData = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Hand Landmarks', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_showGraph ? Icons.list : Icons.auto_graph, color: Colors.white),
            onPressed: () => setState(() => _showGraph = !_showGraph),
            tooltip: _showGraph ? 'Ver lista' : 'Ver gráfico',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controles
          Container(
            padding: const EdgeInsets.all(12.0),
            color: const Color(0xFF16213e),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _handsData.isNotEmpty ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDetecting ? Icons.sensors : Icons.sensors_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isDetecting ? _stopDetection : _startDetection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDetecting ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isDetecting ? Icons.stop : Icons.play_arrow, size: 20),
                      const SizedBox(width: 6),
                      Text(_isDetecting ? 'Detener' : 'Iniciar'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selector de mano si hay más de una
          if (_handsData.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0f3460),
              child: Row(
                children: [
                  const Text('Mano: ', style: TextStyle(color: Colors.white70)),
                  ...List.generate(_handsData.length, (i) {
                    final handedness = _handsData[i]['handedness'] ?? 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${i + 1} ($handedness)'),
                        selected: _selectedHandIndex == i,
                        onSelected: (_) => setState(() => _selectedHandIndex = i),
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: _selectedHandIndex == i ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Contenido principal
          Expanded(
            child: _handsData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.back_hand_outlined, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          _isDetecting ? 'Esperando manos...' : 'Presiona Iniciar',
                          style: const TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : _showGraph
                    ? _buildGraphView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphView() {
    final hand = _handsData[_selectedHandIndex];
    final landmarks = hand['landmarks'] as List<dynamic>? ?? [];
    final handedness = hand['handedness'] ?? 'Unknown';
    final score = hand['handednessScore'] as double? ?? 0.0;

    return Column(
      children: [
        // Gráfico de la mano
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0f3460),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: HandLandmarkPainter(
                  landmarks: landmarks,
                  handedness: handedness,
                ),
                child: Container(),
              ),
            ),
          ),
        ),

        // Info de la mano
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip('Mano', handedness, Icons.back_hand),
              _buildInfoChip('Confianza', '${(score * 100).toStringAsFixed(1)}%', Icons.verified),
              _buildInfoChip('Puntos', '${landmarks.length}', Icons.scatter_plot),
            ],
          ),
        ),

        // Datos en tiempo real de puntos clave
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Puntos clave en tiempo real',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildKeyPointRow(landmarks, 0, 'Muñeca', Colors.red),
                      _buildKeyPointRow(landmarks, 4, 'Pulgar', Colors.orange),
                      _buildKeyPointRow(landmarks, 8, 'Índice', Colors.yellow),
                      _buildKeyPointRow(landmarks, 12, 'Medio', Colors.green),
                      _buildKeyPointRow(landmarks, 16, 'Anular', Colors.cyan),
                      _buildKeyPointRow(landmarks, 20, 'Meñique', Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildKeyPointRow(List<dynamic> landmarks, int index, String name, Color color) {
    if (index >= landmarks.length) return const SizedBox.shrink();

    final lm = landmarks[index];
    final x = (lm['x'] as double?) ?? 0.0;
    final y = (lm['y'] as double?) ?? 0.0;
    final z = (lm['z'] as double?) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              'x: ${x.toStringAsFixed(3)}  y: ${y.toStringAsFixed(3)}  z: ${z.toStringAsFixed(3)}',
              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _handsData.length,
      itemBuilder: (context, index) {
        final hand = _handsData[index];
        return HandCard(handIndex: index, handData: hand);
      },
    );
  }
}

// Painter para dibujar la mano
class HandLandmarkPainter extends CustomPainter {
  final List<dynamic> landmarks;
  final String handedness;

  HandLandmarkPainter({required this.landmarks, required this.handedness});

  // Conexiones entre landmarks de MediaPipe
  static const List<List<int>> connections = [
    // Pulgar
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Índice
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Medio
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Anular
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Meñique
    [0, 17], [17, 18], [18, 19], [19, 20],
    // Conexiones de la palma
    [5, 9], [9, 13], [13, 17],
  ];

  // Colores por dedo
  Color _getFingerColor(int index) {
    if (index == 0) return Colors.red; // Muñeca
    if (index <= 4) return Colors.orange; // Pulgar
    if (index <= 8) return Colors.yellow; // Índice
    if (index <= 12) return Colors.green; // Medio
    if (index <= 16) return Colors.cyan; // Anular
    return Colors.purple; // Meñique
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Escalar y centrar
    final scale = size.width * 0.8;
    final offsetX = size.width * 0.1;
    final offsetY = size.height * 0.1;

    // Convertir landmarks a puntos
    List<Offset> points = [];
    for (var lm in landmarks) {
      final x = (lm['x'] as double?) ?? 0.5;
      final y = (lm['y'] as double?) ?? 0.5;
      points.add(Offset(
        offsetX + x * scale,
        offsetY + y * scale * (size.height / size.width),
      ));
    }

    // Dibujar conexiones
    for (var connection in connections) {
      if (connection[0] < points.length && connection[1] < points.length) {
        final color = _getFingerColor(connection[1]);
        linePaint.color = color.withOpacity(0.7);
        canvas.drawLine(points[connection[0]], points[connection[1]], linePaint);
      }
    }

    // Dibujar puntos
    for (int i = 0; i < points.length; i++) {
      final color = _getFingerColor(i);
      paint.color = color;

      // Puntos más grandes para las puntas de los dedos
      final radius = (i == 4 || i == 8 || i == 12 || i == 16 || i == 20) ? 10.0 : 6.0;
      canvas.drawCircle(points[i], radius, paint);

      // Borde blanco
      paint.color = Colors.white.withOpacity(0.5);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      canvas.drawCircle(points[i], radius, paint);
      paint.style = PaintingStyle.fill;
    }

    // Dibujar número de cada punto
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, points[i] + const Offset(8, -4));
    }

    // Indicador de mano
    textPainter.text = TextSpan(
      text: handedness == 'Left' ? 'Izquierda' : 'Derecha',
      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    return true; // Siempre repintar para animación fluida
  }
}

class HandCard extends StatelessWidget {
  final int handIndex;
  final Map<String, dynamic> handData;

  const HandCard({
    super.key,
    required this.handIndex,
    required this.handData,
  });

  @override
  Widget build(BuildContext context) {
    final landmarks = handData['landmarks'] as List<dynamic>? ?? [];
    final worldLandmarks = handData['worldLandmarks'] as List<dynamic>? ?? [];
    final handedness = handData['handedness'] as String? ?? 'Unknown';
    final score = handData['handednessScore'] as double? ?? 0.0;

    return Card(
      color: const Color(0xFF16213e),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Mano ${handIndex + 1}: $handedness',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Confianza: ${(score * 100).toStringAsFixed(1)}% | ${landmarks.length} puntos',
          style: const TextStyle(color: Colors.white54),
        ),
        leading: Icon(
          handedness == 'Left' ? Icons.back_hand : Icons.front_hand,
          color: Colors.blue,
          size: 32,
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        children: [
          ExpansionTile(
            title: const Text('Landmarks Normalizados', style: TextStyle(color: Colors.white70)),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white54,
            children: [
              SizedBox(
                height: 300,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: landmarks.length,
                  itemBuilder: (context, i) {
                    final lm = landmarks[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0f3460),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue,
                            child: Text('$i', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getLandmarkName(i),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          Text(
                            'x:${(lm['x'] as double).toStringAsFixed(3)} y:${(lm['y'] as double).toStringAsFixed(3)} z:${(lm['z'] as double).toStringAsFixed(3)}',
                            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('World Landmarks (metros)', style: TextStyle(color: Colors.white70)),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white54,
            children: [
              SizedBox(
                height: 300,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: worldLandmarks.length,
                  itemBuilder: (context, i) {
                    final lm = worldLandmarks[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0f3460),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.green,
                            child: Text('$i', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getLandmarkName(i),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          Text(
                            'x:${(lm['x'] as double).toStringAsFixed(4)} y:${(lm['y'] as double).toStringAsFixed(4)} z:${(lm['z'] as double).toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLandmarkName(int index) {
    const names = [
      'Muñeca', 'Pulgar CMC', 'Pulgar MCP', 'Pulgar IP', 'Pulgar Punta',
      'Índice MCP', 'Índice PIP', 'Índice DIP', 'Índice Punta',
      'Medio MCP', 'Medio PIP', 'Medio DIP', 'Medio Punta',
      'Anular MCP', 'Anular PIP', 'Anular DIP', 'Anular Punta',
      'Meñique MCP', 'Meñique PIP', 'Meñique DIP', 'Meñique Punta',
    ];
    return index < names.length ? names[index] : 'Punto $index';
  }
}

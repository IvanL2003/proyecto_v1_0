# Plan: Integrar MediaPipe + API en pantallas con cámara

## Paso 0: Copiar proyecto base al worktree

El proyecto real está en `C:\Users\ivanl\AndroidStudioProjects\proyecto_v1_0\`.
Este worktree (`nice-volhard`) está vacío. Primero copiar todo el proyecto aquí.

```bash
cp -r C:\Users\ivanl\AndroidStudioProjects\proyecto_v1_0\* C:\Users\ivanl\.claude-worktrees\proyecto_v1_0\nice-volhard\
```

## Resumen

Integrar la detección de manos MediaPipe (ya funcional en `test_pantalla_curso.dart`) en `pantalla4.dart` y `pantalla_curso.dart`, reemplazando la detección simulada. Las coordenadas se enviarán continuamente a una API externa que verificará si el gesto es correcto.

**Restricción**: No se modifican archivos existentes directamente. Se crean copias (`_copia`) con el código nuevo. No se elimina nada del `pubspec.yaml`.

**Proyecto fuente**: `C:\Users\ivanl\AndroidStudioProjects\proyecto_v1_0\`
**Worktree destino**: `C:\Users\ivanl\.claude-worktrees\proyecto_v1_0\nice-volhard\`

## Flujo objetivo

```
Cámara captura → MediaPipe detecta mano → Envío continuo a API (cada ~1s) →
API responde {correcto: true/false} → Si correcto → juego avanza
```

---

## Problema principal: conflicto de cámara

`HandLandmarkPlugin.java` abre CameraX (headless, solo ImageAnalysis). Las pantallas Flutter abren la cámara con el plugin `camera`. Ambos compiten por el hardware.

**Solución**: Usar CameraX nativo para TODO (preview + análisis). Exponer el preview como PlatformView (`AndroidView`) en Flutter.

---

## Archivos a crear - Capa Nativa Android (4)

### 1. `android/.../CameraPreviewFactory.java` (NUEVO)
- PlatformViewFactory que crea instancias de CameraPreviewView
- Se registra con viewType `"com.example.proyecto_v1_0/camera_preview"`

### 2. `android/.../CameraPreviewView.java` (NUEVO)
- Implementa `PlatformView`, contiene un `PreviewView` de CameraX
- Expone `getPreviewView()` para que HandLandmarkPlugin lo use

### 3. `android/.../HandLandmarkPlugin_copia.java` (COPIA de HandLandmarkPlugin.java)
- Añadir campo `static PreviewView previewView`
- Nuevo método `startWithPreview(Context, PreviewView)`
- Modificar `bindCameraUseCases()`: si hay previewView, crear `Preview` use case junto con `ImageAnalysis`
- Mantener `start()` sin preview para compatibilidad con test_pantalla_curso

### 4. `android/.../MainActivity_copia.java` (COPIA de MainActivity.java)
- Registrar `CameraPreviewFactory` en `configureFlutterEngine()`
- Añadir método `startHandDetectionWithPreview` en el MethodChannel

---

## Archivos a crear - Capa Flutter (8)

### 5. `lib/models/hand_detection_result.dart` (NUEVO)
- Clases: `HandLandmark`, `HandData`, `HandDetectionResult`
- Parseo del Map que llega del EventChannel
- Método `toApiJson(String targetWord)` para formatear el payload

### 6. `lib/services/hand_detection_service.dart` (NUEVO)
- Singleton que encapsula MethodChannel + EventChannel de hand_landmark
- Expone `Stream<HandDetectionResult>` para que las pantallas escuchen
- Métodos: `startDetection()`, `stopDetection()`
- Guarda `lastRawData` para enviar a la API

### 7. `lib/services/sign_language_api_service.dart` (NUEVO)
- Servicio HTTP para enviar coordenadas a la API continuamente
- URL placeholder: `https://api.example.com/api/gestures`
- Método `sendLandmarks()` que envía y devuelve si el gesto es correcto
- Throttle de ~1 segundo entre envíos
- Manejo de errores (no bloquear al usuario si falla la red)

### 8. `lib/widgets/native_camera_preview.dart` (NUEVO)
- Widget que wrappea `AndroidView` con viewType `camera_preview`
- Reutilizable en todas las pantallas

### 9. `lib/pantalla4_copia.dart` (COPIA de pantalla4.dart)
- Reemplazar imports de `camera` package por los nuevos servicios
- Eliminar `CameraController`, `_initializeCamera()`, `_processImage()`, `_getDemoSign()`, `_startSignDetection()`
- Reemplazar `CameraPreview(_cameraController!)` por `NativeCameraPreview()`
- Usar `HandDetectionService` para recibir landmarks en tiempo real
- Usar `SignLanguageApiService` para enviar coordenadas continuamente
- Mostrar resultado de la API (signo detectado) en la UI existente

### 10. `lib/pantalla_curso_copia.dart` (COPIA de pantalla_curso.dart)
- Mismos cambios de cámara que pantalla4_copia
- Eliminar `_simularDeteccion()` y el botón "Simular Acierto (TEST)"
- Integrar `SignLanguageApiService`: enviar coordenadas continuamente
- Cuando la API responde `correcto: true`, llamar `_verificarRespuesta(true)`
- La lógica de juego (vidas, intentos, timer) se mantiene intacta

### 11. `pubspec_copia.yaml` (COPIA de pubspec.yaml)
- Añadir: `http: ^1.1.0`
- Mantener todo lo existente (incluido `camera: ^0.10.5+5`)

---

## Formato del payload a la API

```json
{
  "palabra_objetivo": "Hola",
  "mano": "Right",
  "timestamp": 1644234567890,
  "landmarks": {
    "punto1": {"coordx": 0.5234, "coordy": 0.3421, "coordz": -0.0123},
    "punto2": {"coordx": 0.5891, "coordy": 0.2987, "coordz": -0.0089},
    "...": "...",
    "punto21": {"coordx": 0.4123, "coordy": 0.6789, "coordz": -0.0234}
  }
}
```

Respuesta esperada de la API (placeholder):
```json
{
  "correcto": true,
  "confianza": 0.92,
  "mensaje": "Gesto reconocido correctamente"
}
```

---

## Orden de implementación

1. Crear `HandLandmarkPlugin_copia.java` (soporte Preview)
2. Crear `CameraPreviewView.java` + `CameraPreviewFactory.java`
3. Crear `MainActivity_copia.java` (registrar PlatformView)
4. Crear `hand_detection_result.dart` (modelos)
5. Crear `hand_detection_service.dart` (servicio singleton)
6. Crear `native_camera_preview.dart` (widget)
7. Crear `pantalla4_copia.dart` (más simple, sin juego)
8. Crear `pubspec_copia.yaml` (añadir http)
9. Crear `sign_language_api_service.dart`
10. Crear `pantalla_curso_copia.dart` (juego + API)

---

## Archivos originales que NO se tocan

- `HandLandmarkPlugin.java` - se crea copia
- `MainActivity.java` - se crea copia
- `pantalla4.dart` - se crea copia
- `pantalla_curso.dart` - se crea copia
- `pubspec.yaml` - se crea copia (sin eliminar nada)
- `test_pantalla_curso.dart` - no se toca en absoluto
- `main.dart`, `principal.dart`, `pantalla2.dart`, `pantalla3.dart` - sin cambios
- `build.gradle.kts` - ya tiene dependencias nativas necesarias
- `AndroidManifest.xml` - ya tiene permisos CAMERA e INTERNET

---

## Verificación / Testing

1. Para probar, renombrar los archivos `_copia` para que reemplacen a los originales
2. Compilar el proyecto Android (`flutter build apk --debug`)
3. En `pantalla4`: verificar que se ve el preview de la cámara y que los landmarks se reciben
4. En `pantalla_curso`: iniciar juego, hacer un gesto, verificar que se envían coordenadas a la API
5. Verificar que `test_pantalla_curso` sigue funcionando sin cambios
6. Comprobar logs de red (HTTP POST) para confirmar formato del payload
7. Verificar que al cambiar de tab la cámara se libera y reinicia correctamente

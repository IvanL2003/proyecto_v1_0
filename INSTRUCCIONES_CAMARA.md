# Instrucciones de Configuración - Cámara y Detección de Lenguaje de Signos

## ✅ Archivos Modificados

1. **lib/pantalla4.dart** - Vista con cámara y detección de signos
2. **lib/principal.dart** - Integración de pantalla4 en el navigation bar
3. **pubspec.yaml** - Dependencias añadidas
4. **android/app/src/main/AndroidManifest.xml** - Permisos de cámara
5. **lib/sign_language_detector.py** - Script Python para detección (opcional)

---

## 📦 Paso 1: Instalar Dependencias

Ejecuta en la terminal:

```bash
flutter pub get
```

Las dependencias añadidas son:
- `camera: ^0.10.5+5` - Para acceder a la cámara
- `path_provider: ^2.1.1` - Para gestión de archivos

---

## 🎯 Paso 2: Funcionamiento Actual

### Modo Demo (Actual)
La app está configurada en **modo demostración** que:
- ✅ Muestra la cámara frontal en tiempo real (mitad superior)
- ✅ Simula detección de signos rotando entre: Hola, Gracias, Por favor, Adiós, Sí, No
- ✅ Muestra confianza simulada del 85%
- ✅ Funciona SIN necesidad de Python

### Cómo funciona
- Al abrir la pestaña "Camera" (icono de cámara en el bottom bar)
- Se inicia automáticamente la cámara frontal
- Cada 2 segundos cambia el signo detectado (modo demo)

---

## 🔧 Paso 3: Configuración iOS (Si usas iOS)

Edita `ios/Runner/Info.plist` y añade:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para detectar lenguaje de signos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Esta app no usa el micrófono</string>
```

---

## 🐍 Paso 4: Integración con Python (OPCIONAL - Avanzado)

Si quieres usar el script Python real para detección:

### Opción A: Usar Chaquopy (Solo Android)

1. Edita `android/app/build.gradle`:

```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'dev.flutter.flutter-gradle-plugin'
    id 'com.chaquo.python' version '14.0.2'  // Añadir esta línea
}

// Añadir después de android { ... }
chaquopy {
    defaultConfig {
        version "3.8"
        pip {
            install "opencv-python"
            install "mediapipe"
            install "numpy"
        }
    }
}
```

2. Edita `android/build.gradle`:

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url "https://chaquo.com/maven" }  // Añadir esta línea
    }
}
```

3. Copia `sign_language_detector.py` a `android/app/src/main/python/`

### Opción B: Backend Python Separado (Recomendado)

Crear un servidor Flask/FastAPI y comunicarte vía HTTP.

---

## 🚀 Paso 5: Ejecutar la App

```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios

# Para depurar
flutter run --verbose
```

---

## 📱 Cómo Usar la Pantalla

1. Abre la app
2. Toca el icono de **cámara** en el bottom navigation bar (tercer icono)
3. Acepta los permisos de cámara cuando se soliciten
4. La cámara frontal se mostrará en la mitad superior
5. En la mitad inferior verás:
   - El signo detectado (actualmente en modo demo)
   - Barra de confianza
   - Instrucciones

---

## 🛠️ Solución de Problemas

### Error: "Camera not found"
- Verifica que el dispositivo tenga cámara frontal
- Comprueba que los permisos estén en AndroidManifest.xml

### Error: "Permission denied"
- Desinstala la app
- Vuelve a instalar con `flutter run`
- Acepta los permisos cuando se soliciten

### Error: "Method channel not implemented"
- Es normal, la app está en modo demo
- El script Python es opcional

### Pantalla negra
- Espera unos segundos, la cámara tarda en iniciar
- Verifica los logs con `flutter logs`

---

## 🎨 Personalización

### Cambiar signos detectados (modo demo)
Edita `lib/pantalla4.dart`, línea 115:

```dart
String _getDemoSign() {
  final signs = ['Hola', 'Gracias', 'Adiós'];  // Personaliza aquí
  return signs[DateTime.now().second % signs.length];
}
```

### Cambiar velocidad de detección
Edita línea 121:

```dart
Timer.periodic(const Duration(seconds: 2), (timer) {  // Cambia '2' por el tiempo deseado
```

---

## 📝 Notas Importantes

1. **La app funciona SIN Python** - El modo demo no requiere configuración adicional
2. **Python es opcional** - Solo si quieres detección real con MediaPipe
3. **La cámara se inicia automáticamente** - Al entrar en la pestaña
4. **Funciona en modo debug** - Para producción optimiza el código

---

## 📚 Próximos Pasos

Para implementar detección REAL:

1. Entrenar un modelo ML con TensorFlow Lite
2. Convertirlo a formato `.tflite`
3. Usar el paquete `tflite_flutter` en Flutter
4. Reemplazar `_getDemoSign()` con el modelo real

O usar el script Python con Chaquopy siguiendo el Paso 4.

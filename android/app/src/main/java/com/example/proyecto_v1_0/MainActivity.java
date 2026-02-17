//package com.example.proyecto_v1_0;
//
//import android.Manifest;
//import android.content.pm.PackageManager;
//import android.os.Bundle;
//
//import androidx.annotation.NonNull;
//import androidx.core.app.ActivityCompat;
//import androidx.core.content.ContextCompat;
//
//import io.flutter.embedding.android.FlutterActivity;
//import io.flutter.embedding.engine.FlutterEngine;
//import io.flutter.plugin.common.EventChannel;
//import io.flutter.plugin.common.MethodChannel;
//
//public class MainActivity extends FlutterActivity {
//
//    private static final String METHOD_CHANNEL = "com.example.proyecto_v1_0/hand_landmark";
//    private static final String EVENT_CHANNEL = "com.example.proyecto_v1_0/hand_landmark_stream";
//    private static final int CAMERA_PERMISSION_REQUEST_CODE = 1001;
//
//    private MethodChannel.Result pendingResult;
//
//    @Override
//    protected void onCreate(Bundle savedInstanceState) {
//        super.onCreate(savedInstanceState);
//    }
//
//    @Override
//    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
//        super.configureFlutterEngine(flutterEngine);
//
//        // MethodChannel para comandos (start/stop)
//        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
//                .setMethodCallHandler((call, result) -> {
//                    switch (call.method) {
//                        case "startHandDetection":
//                            pendingResult = result;
//                            checkCameraPermission();
//                            break;
//                        case "stopHandDetection":
//                            HandLandmarkPlugin.stop();
//                            result.success(null);
//                            break;
//                        default:
//                            result.notImplemented();
//                    }
//                });
//
//        // EventChannel para stream de landmarks
//        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
//                .setStreamHandler(new EventChannel.StreamHandler() {
//                    @Override
//                    public void onListen(Object arguments, EventChannel.EventSink events) {
//                        HandLandmarkPlugin.setEventSink(events);
//                    }
//
//                    @Override
//                    public void onCancel(Object arguments) {
//                        HandLandmarkPlugin.setEventSink(null);
//                    }
//                });
//    }
//
//    /**
//     * Verifica y solicita permiso de cámara
//     */
//    private void checkCameraPermission() {
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
//                == PackageManager.PERMISSION_GRANTED) {
//            startHandDetection();
//        } else {
//            ActivityCompat.requestPermissions(
//                    this,
//                    new String[]{Manifest.permission.CAMERA},
//                    CAMERA_PERMISSION_REQUEST_CODE
//            );
//        }
//    }
//
//    @Override
//    public void onRequestPermissionsResult(int requestCode,
//                                           @NonNull String[] permissions,
//                                           @NonNull int[] grantResults) {
//        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
//
//        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
//            if (grantResults.length > 0 &&
//                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
//                startHandDetection();
//            } else {
//                if (pendingResult != null) {
//                    pendingResult.error("PERMISSION_DENIED",
//                            "Permiso de cámara denegado", null);
//                    pendingResult = null;
//                }
//            }
//        }
//    }
//
//    /**
//     * Inicia la detección de manos
//     */
//    private void startHandDetection() {
//        HandLandmarkPlugin.start(this);
//        if (pendingResult != null) {
//            pendingResult.success(true);
//            pendingResult = null;
//        }
//    }
//
//    @Override
//    protected void onDestroy() {
//        super.onDestroy();
//        HandLandmarkPlugin.stop();
//    }
//}
package com.example.proyecto_v1_0;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    
    private static final String METHOD_CHANNEL = "com.example.proyecto_v1_0/hand_landmark";
    private static final String EVENT_CHANNEL = "com.example.proyecto_v1_0/hand_landmark_stream";
    private static final String VIEW_TYPE_CAMERA_PREVIEW = "com.example.proyecto_v1_0/camera_preview";
    private static final int CAMERA_PERMISSION_REQUEST_CODE = 1001;
    
    private MethodChannel.Result pendingResult;
    private boolean pendingWithPreview = false;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Registrar PlatformView para el preview de camara
        flutterEngine.getPlatformViewsController()
                .getRegistry()
                .registerViewFactory(
                        VIEW_TYPE_CAMERA_PREVIEW,
                        new CameraPreviewFactory(this)
                );
        
        // MethodChannel para comandos (start/stop)
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startHandDetection":
                            pendingResult = result;
                            pendingWithPreview = false;
                            checkCameraPermission();
                            break;
                        case "startHandDetectionWithPreview":
                            pendingResult = result;
                            pendingWithPreview = true;
                            checkCameraPermission();
                            break;
                        case "stopHandDetection":
                            HandLandmarkPlugin.stop();
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                    }
                });
        
        // EventChannel para stream de landmarks
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
                .setStreamHandler(new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        HandLandmarkPlugin.setEventSink(events);
                    }
                    
                    @Override
                    public void onCancel(Object arguments) {
                        HandLandmarkPlugin.setEventSink(null);
                    }
                });
    }
    
    /**
     * Verifica y solicita permiso de camara
     */
    private void checkCameraPermission() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED) {
            startHandDetection();
        } else {
            ActivityCompat.requestPermissions(
                    this,
                    new String[]{Manifest.permission.CAMERA},
                    CAMERA_PERMISSION_REQUEST_CODE
            );
        }
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startHandDetection();
            } else {
                if (pendingResult != null) {
                    pendingResult.error("PERMISSION_DENIED",
                            "Permiso de camara denegado", null);
                    pendingResult = null;
                }
            }
        }
    }
    
    /**
     * Inicia la deteccion de manos (con o sin preview segun pendingWithPreview)
     */
    private void startHandDetection() {
        if (pendingWithPreview) {
            // startWithPreview usa el PreviewView que ya fue registrado
            // por CameraPreviewFactory cuando Flutter creo el AndroidView
            HandLandmarkPlugin.startWithPreview(this,
                    HandLandmarkPlugin.getPreviewView());
        } else {
            // Modo headless (compatibilidad con test_pantalla_curso)
            HandLandmarkPlugin.start(this);
        }
        
        if (pendingResult != null) {
            pendingResult.success(true);
            pendingResult = null;
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        HandLandmarkPlugin.stop();
    }
}

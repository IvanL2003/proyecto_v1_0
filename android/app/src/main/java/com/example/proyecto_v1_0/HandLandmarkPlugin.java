package com.example.proyecto_v1_0;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.mediapipe.framework.image.BitmapImageBuilder;
import com.google.mediapipe.framework.image.MPImage;
import com.google.mediapipe.tasks.components.containers.Landmark;
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark;
import com.google.mediapipe.tasks.core.BaseOptions;
import com.google.mediapipe.tasks.vision.core.RunningMode;
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker;
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.EventChannel;

public class HandLandmarkPlugin {
    private static final String TAG = "HandLandmarkPlugin";
    private static final String MODEL_PATH = "hand_landmarker.task";
    
    private static HandLandmarker handLandmarker;
    private static ExecutorService executorService;
    private static ProcessCameraProvider cameraProvider;
    private static boolean isProcessing = false;
    private static LifecycleOwner lifecycleOwner;
    private static EventChannel.EventSink eventSink; // CAMBIO: Usar EventSink
    
    // Configuración
    private static final int MAX_HANDS = 2;
    private static final float MIN_DETECTION_CONFIDENCE = 0.5f;
    private static final float MIN_PRESENCE_CONFIDENCE = 0.5f;
    private static final float MIN_TRACKING_CONFIDENCE = 0.5f;
    
    /**
     * Establece el EventSink para enviar datos a Flutter
     */
    public static void setEventSink(EventChannel.EventSink sink) {
        eventSink = sink;
    }
    
    /**
     * Inicializa y comienza la detección de manos
     */
    public static void start(Context context) {
        try {
            Log.d(TAG, "Iniciando detección de manos...");
            
            // Guardar referencia al LifecycleOwner
            if (context instanceof LifecycleOwner) {
                lifecycleOwner = (LifecycleOwner) context;
            } else {
                Log.e(TAG, "Context debe ser una Activity/LifecycleOwner");
                return;
            }
            
            // Inicializar HandLandmarker
            setupHandLandmarker(context);
            
            // Iniciar cámara
            startCamera(context);
            
        } catch (Exception e) {
            Log.e(TAG, "Error iniciando detección: " + e.getMessage());
            if (eventSink != null) {
                eventSink.error("INITIALIZATION_ERROR", e.getMessage(), null);
            }
        }
    }
    
    /**
     * Configura el HandLandmarker de MediaPipe
     */
    private static void setupHandLandmarker(Context context) {
        try {
            if (handLandmarker != null) {
                handLandmarker.close();
            }
            
            BaseOptions baseOptions = BaseOptions.builder()
                    .setModelAssetPath(MODEL_PATH)
                    .build();
            
            HandLandmarker.HandLandmarkerOptions options =
                    HandLandmarker.HandLandmarkerOptions.builder()
                            .setBaseOptions(baseOptions)
                            .setRunningMode(RunningMode.LIVE_STREAM)
                            .setNumHands(MAX_HANDS)
                            .setMinHandDetectionConfidence(MIN_DETECTION_CONFIDENCE)
                            .setMinHandPresenceConfidence(MIN_PRESENCE_CONFIDENCE)
                            .setMinTrackingConfidence(MIN_TRACKING_CONFIDENCE)
                            .setResultListener((handLandmarkerResult, mpImage) -> {
                                onHandLandmarkerResults(handLandmarkerResult);
                            })
                            .setErrorListener((RuntimeException error) -> {
                                Log.e(TAG, "HandLandmarker error: " + error.getMessage());
                            })
                            .build();
            
            handLandmarker = HandLandmarker.createFromOptions(context, options);
            Log.d(TAG, "HandLandmarker inicializado correctamente");
            
        } catch (Exception e) {
            Log.e(TAG, "Error configurando HandLandmarker: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }
    
    /**
     * Callback cuando se detectan landmarks de manos
     */
    private static void onHandLandmarkerResults(HandLandmarkerResult handResult) {
        if (eventSink == null) return; // No hay nadie escuchando
        
        int handsDetected = handResult.landmarks().size();
        
        // Convertir resultados a formato para Flutter
        List<Map<String, Object>> handsData = new ArrayList<>();
        
        for (int i = 0; i < handsDetected; i++) {
            Map<String, Object> handData = new HashMap<>();
            
            // Obtener landmarks normalizados (x, y, z)
            List<NormalizedLandmark> landmarks = handResult.landmarks().get(i);
            List<Map<String, Float>> landmarkList = new ArrayList<>();
            
            for (int j = 0; j < landmarks.size(); j++) {
                NormalizedLandmark landmark = landmarks.get(j);
                Map<String, Float> point = new HashMap<>();
                point.put("x", landmark.x());
                point.put("y", landmark.y());
                point.put("z", landmark.z());
                landmarkList.add(point);
            }
            
            // Obtener world landmarks (coordenadas 3D reales)
            List<Landmark> worldLandmarks = handResult.worldLandmarks().get(i);
            List<Map<String, Float>> worldLandmarkList = new ArrayList<>();
            
            for (int j = 0; j < worldLandmarks.size(); j++) {
                Landmark landmark = worldLandmarks.get(j);
                Map<String, Float> point = new HashMap<>();
                point.put("x", landmark.x());
                point.put("y", landmark.y());
                point.put("z", landmark.z());
                worldLandmarkList.add(point);
            }
            
            // Obtener handedness (izquierda/derecha)
            String handedness = handResult.handedness().get(i).get(0).categoryName();
            float handednessScore = handResult.handedness().get(i).get(0).score();
            
            handData.put("landmarks", landmarkList);
            handData.put("worldLandmarks", worldLandmarkList);
            handData.put("handedness", handedness);
            handData.put("handednessScore", handednessScore);
            
            handsData.add(handData);
        }
        
        // Enviar resultados a Flutter en el hilo principal
        new Handler(Looper.getMainLooper()).post(() -> {
            if (eventSink != null) {
                Map<String, Object> response = new HashMap<>();
                response.put("hands", handsData);
                response.put("timestamp", System.currentTimeMillis());
                eventSink.success(response);
            }
        });
    }
    
    /**
     * Inicia CameraX para captura de video
     */
    private static void startCamera(Context context) {
        if (executorService == null) {
            executorService = Executors.newSingleThreadExecutor();
        }
        
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture =
                ProcessCameraProvider.getInstance(context);
        
        cameraProviderFuture.addListener(() -> {
            try {
                cameraProvider = cameraProviderFuture.get();
                bindCameraUseCases(context);
            } catch (ExecutionException | InterruptedException e) {
                Log.e(TAG, "Error iniciando cámara: " + e.getMessage());
                if (eventSink != null) {
                    eventSink.error("CAMERA_ERROR", e.getMessage(), null);
                }
            }
        }, ContextCompat.getMainExecutor(context));
    }
    
    /**
     * Vincula los casos de uso de CameraX
     */
    private static void bindCameraUseCases(Context context) {
        // ImageAnalysis use case
        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build();
        
        imageAnalysis.setAnalyzer(executorService, imageProxy -> {
            analyzeImage(imageProxy);
        });
        
        // Camera selector (cámara frontal para selfie)
        CameraSelector cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA;
        
        try {
            // Desvincular casos de uso anteriores
            cameraProvider.unbindAll();
            
            // Vincular casos de uso
            cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    imageAnalysis
            );
            
            Log.d(TAG, "Cámara iniciada correctamente");
            
        } catch (Exception e) {
            Log.e(TAG, "Error vinculando cámara: " + e.getMessage());
            if (eventSink != null) {
                eventSink.error("CAMERA_BIND_ERROR", e.getMessage(), null);
            }
        }
    }
    
    /**
     * Analiza cada frame de la cámara
     */
    private static void analyzeImage(@NonNull ImageProxy imageProxy) {
        // Evitar procesamiento paralelo
        if (isProcessing) {
            imageProxy.close();
            return;
        }
        
        isProcessing = true;
        
        try {
            // Convertir ImageProxy a Bitmap
            Bitmap bitmap = imageProxyToBitmap(imageProxy);
            
            // Rotar bitmap según orientación
            bitmap = rotateBitmap(bitmap, imageProxy.getImageInfo().getRotationDegrees());
            
            // Convertir a MPImage
            MPImage mpImage = new BitmapImageBuilder(bitmap).build();
            
            // Detectar landmarks de forma asíncrona
            long frameTime = System.currentTimeMillis();
            handLandmarker.detectAsync(mpImage, frameTime);
            
        } catch (Exception e) {
            Log.e(TAG, "Error analizando imagen: " + e.getMessage());
        } finally {
            isProcessing = false;
            imageProxy.close();
        }
    }
    
    /**
     * Convierte ImageProxy (RGBA_8888) a Bitmap
     */
    private static Bitmap imageProxyToBitmap(ImageProxy imageProxy) {
        ImageProxy.PlaneProxy plane = imageProxy.getPlanes()[0];
        ByteBuffer buffer = plane.getBuffer();
        
        int width = imageProxy.getWidth();
        int height = imageProxy.getHeight();
        int pixelStride = plane.getPixelStride();
        int rowStride = plane.getRowStride();
        int rowPadding = rowStride - pixelStride * width;
        
        Bitmap bitmap = Bitmap.createBitmap(
                width + rowPadding / pixelStride,
                height,
                Bitmap.Config.ARGB_8888
        );
        bitmap.copyPixelsFromBuffer(buffer);
        
        // Recortar el padding si existe
        if (rowPadding > 0) {
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height);
        }
        
        return bitmap;
    }
    
    /**
     * Rota el bitmap según los grados especificados
     */
    private static Bitmap rotateBitmap(Bitmap bitmap, int rotationDegrees) {
        if (rotationDegrees == 0) return bitmap;
        
        Matrix matrix = new Matrix();
        matrix.postRotate(rotationDegrees);
        return Bitmap.createBitmap(bitmap, 0, 0,
                bitmap.getWidth(), bitmap.getHeight(), matrix, true);
    }
    
    /**
     * Detiene la cámara y libera recursos
     */
    public static void stop() {
        if (cameraProvider != null) {
            cameraProvider.unbindAll();
        }
        
        if (handLandmarker != null) {
            handLandmarker.close();
            handLandmarker = null;
        }
        
        if (executorService != null) {
            executorService.shutdown();
            executorService = null;
        }
        
        eventSink = null;
        
        Log.d(TAG, "Detección detenida y recursos liberados");
    }
}
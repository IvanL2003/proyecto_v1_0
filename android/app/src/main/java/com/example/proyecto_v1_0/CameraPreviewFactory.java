package com.example.proyecto_v1_0;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * Factory que crea instancias de CameraPreviewView.
 * Se registra en MainActivity_copia con el viewType "com.example.proyecto_v1_0/camera_preview".
 *
 * Cuando Flutter crea un AndroidView con ese viewType, esta factory
 * instancia un CameraPreviewView y configura su PreviewView en
 * HandLandmarkPlugin_copia para que CameraX muestre el preview.
 */
public class CameraPreviewFactory extends PlatformViewFactory {

    private final Activity activity;

    public CameraPreviewFactory(Activity activity) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull Context context, int viewId, @Nullable Object args) {
        CameraPreviewView cameraPreviewView = new CameraPreviewView(activity);

        // Registrar el PreviewView en el plugin para que CameraX lo use
        HandLandmarkPlugin_copia.setPreviewView(cameraPreviewView.getPreviewView());

        return cameraPreviewView;
    }
}

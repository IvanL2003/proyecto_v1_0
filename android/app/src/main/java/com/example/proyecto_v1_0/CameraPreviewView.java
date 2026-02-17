package com.example.proyecto_v1_0;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.camera.view.PreviewView;

import io.flutter.plugin.platform.PlatformView;

/**
 * PlatformView que contiene un PreviewView de CameraX.
 * Se usa desde Flutter mediante AndroidView para mostrar el preview de la camara
 * mientras HandLandmarkPlugin procesa los frames con MediaPipe.
 */
public class CameraPreviewView implements PlatformView {

    private final PreviewView previewView;

    CameraPreviewView(@NonNull Context context) {
        previewView = new PreviewView(context);
        previewView.setImplementationMode(PreviewView.ImplementationMode.COMPATIBLE);
        previewView.setScaleType(PreviewView.ScaleType.FILL_CENTER);
    }

    /**
     * Devuelve el PreviewView para que HandLandmarkPlugin lo use
     * como surface provider del Preview use case de CameraX.
     */
    public PreviewView getPreviewView() {
        return previewView;
    }

    @NonNull
    @Override
    public View getView() {
        return previewView;
    }

    @Override
    public void dispose() {
        // El PreviewView se limpia automaticamente cuando CameraX se desvincula
    }
}

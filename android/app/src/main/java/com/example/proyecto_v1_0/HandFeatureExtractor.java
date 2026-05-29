package com.example.proyecto_v1_0;

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark;

import java.util.List;

/**
 * Extrae el vector de 73 features a partir de los 21 landmarks de MediaPipe.
 *
 * Estructura: [x0,y0,z0, ..., x20,y20,z20, angle0, ..., angle9]
 *              63 coordenadas normalizadas  +  10 angulos
 *
 * Normalización (igual que cargar_csv.py):
 *   1. Centrar respecto a la muñeca (landmark 0)
 *   2. Escalar dividiendo por la maxima distancia al origen
 */
public class HandFeatureExtractor {

    public static final int NUM_LANDMARKS = 21;
    public static final int NUM_COORDS = 63;   // 21 * 3
    public static final int NUM_ANGLES = 10;
    public static final int FEATURE_SIZE = 73;  // 63 + 10

    // Indices de los dedos segun MediaPipe Hands
    private static final int[][] FINGER_INDICES = {
            {1, 2, 3, 4},      // Pulgar
            {5, 6, 7, 8},      // Indice
            {9, 10, 11, 12},   // Medio
            {13, 14, 15, 16},  // Anular
            {17, 18, 19, 20}   // Menique
    };

    /**
     * Extrae 73 features desde los NormalizedLandmark de MediaPipe.
     *
     * @param landmarks Lista de 21 NormalizedLandmark
     * @return float[73] o null si los landmarks son invalidos
     */
    public static float[] extract(List<NormalizedLandmark> landmarks) {
        if (landmarks == null || landmarks.size() != NUM_LANDMARKS) {
            return null;
        }

        // Convertir a array [21][3]
        float[][] lm = new float[NUM_LANDMARKS][3];
        for (int i = 0; i < NUM_LANDMARKS; i++) {
            lm[i][0] = landmarks.get(i).x();
            lm[i][1] = landmarks.get(i).y();
            lm[i][2] = landmarks.get(i).z();
        }

        // Calcular angulos ANTES de normalizar (igual que cargar_csv.py)
        float[] angles = computeAngles(lm);

        // Normalizar landmarks
        float[][] normalized = normalizeLandmarks(lm);

        // Construir vector de 73 features
        float[] features = new float[FEATURE_SIZE];

        // 63 coordenadas normalizadas
        for (int i = 0; i < NUM_LANDMARKS; i++) {
            features[i * 3]     = normalized[i][0];
            features[i * 3 + 1] = normalized[i][1];
            features[i * 3 + 2] = normalized[i][2];
        }

        // 10 angulos
        for (int i = 0; i < NUM_ANGLES; i++) {
            features[NUM_COORDS + i] = angles[i];
        }

        return features;
    }

    /**
     * Normaliza: centrar en muñeca + escalar por distancia maxima.
     */
    private static float[][] normalizeLandmarks(float[][] lm) {
        float wx = lm[0][0], wy = lm[0][1], wz = lm[0][2];

        float[][] centered = new float[NUM_LANDMARKS][3];
        for (int i = 0; i < NUM_LANDMARKS; i++) {
            centered[i][0] = lm[i][0] - wx;
            centered[i][1] = lm[i][1] - wy;
            centered[i][2] = lm[i][2] - wz;
        }

        // Distancia maxima al origen
        float maxDist = 0f;
        for (float[] p : centered) {
            float dist = (float) Math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
            if (dist > maxDist) maxDist = dist;
        }

        // Escalar
        if (maxDist > 0f) {
            for (float[] p : centered) {
                p[0] /= maxDist;
                p[1] /= maxDist;
                p[2] /= maxDist;
            }
        }

        return centered;
    }

    /**
     * Calcula 10 angulos articulares (2 por cada dedo).
     */
    private static float[] computeAngles(float[][] lm) {
        float[] angles = new float[NUM_ANGLES];
        int idx = 0;

        for (int[] finger : FINGER_INDICES) {
            // Angulo proximal: finger[0]-finger[1]-finger[2]
            angles[idx++] = angleBetween(lm[finger[0]], lm[finger[1]], lm[finger[2]]);
            // Angulo distal: finger[1]-finger[2]-finger[3]
            angles[idx++] = angleBetween(lm[finger[1]], lm[finger[2]], lm[finger[3]]);
        }

        return angles;
    }

    /**
     * Angulo en grados entre tres puntos 3D (vertice en B).
     */
    private static float angleBetween(float[] a, float[] b, float[] c) {
        float[] ba = {a[0] - b[0], a[1] - b[1], a[2] - b[2]};
        float[] bc = {c[0] - b[0], c[1] - b[1], c[2] - b[2]};

        float dot = ba[0] * bc[0] + ba[1] * bc[1] + ba[2] * bc[2];
        float magBA = (float) Math.sqrt(ba[0] * ba[0] + ba[1] * ba[1] + ba[2] * ba[2]);
        float magBC = (float) Math.sqrt(bc[0] * bc[0] + bc[1] * bc[1] + bc[2] * bc[2]);

        if (magBA == 0f || magBC == 0f) return 0f;

        float cosAngle = Math.max(-1f, Math.min(1f, dot / (magBA * magBC)));
        return (float) Math.toDegrees(Math.acos(cosAngle));
    }
}

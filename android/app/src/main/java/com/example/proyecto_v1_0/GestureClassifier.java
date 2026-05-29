package com.example.proyecto_v1_0;

import android.content.Context;
import android.util.Log;

import org.json.JSONObject;
import org.tensorflow.lite.Interpreter;

import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Clasificador de gestos usando TensorFlow Lite.
 *
 * Archivos necesarios en assets/:
 *   - hand_gesture_model.tflite
 *   - label_map.json
 */
public class GestureClassifier {

    private static final String TAG = "GestureClassifier";
    private static final String MODEL_FILE = "hand_gesture_model.tflite";
    private static final String LABEL_MAP_FILE = "label_map.json";

    private Interpreter interpreter;
    private Map<Integer, String> labelMap;
    private int numClasses;
    private float confidenceThreshold = 0.5f;

    /**
     * Inicializa el clasificador cargando el modelo y el mapa de labels.
     */
    public GestureClassifier(Context context) {
        try {
            MappedByteBuffer model = loadModelFile(context);
            Interpreter.Options options = new Interpreter.Options();
            options.setNumThreads(4);
            interpreter = new Interpreter(model, options);

            labelMap = loadLabelMap(context);
            numClasses = labelMap.size();

            Log.d(TAG, "GestureClassifier inicializado con " + numClasses + " clases");
        } catch (Exception e) {
            Log.e(TAG, "Error inicializando GestureClassifier: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }

    public void setConfidenceThreshold(float threshold) {
        this.confidenceThreshold = threshold;
    }

    /**
     * Clasifica un vector de 73 features.
     *
     * @param features float[73] (63 coords + 10 angulos)
     * @return Map con "label", "confidence" y "allProbabilities", o null si no supera el umbral
     */
    public Map<String, Object> classify(float[] features) {
        if (interpreter == null || features == null ||
                features.length != HandFeatureExtractor.FEATURE_SIZE) {
            return null;
        }

        // Preparar input [1, 73]
        ByteBuffer inputBuffer = ByteBuffer.allocateDirect(4 * features.length);
        inputBuffer.order(ByteOrder.nativeOrder());
        for (float f : features) {
            inputBuffer.putFloat(f);
        }
        inputBuffer.rewind();

        // Preparar output [1, numClasses]
        float[][] output = new float[1][numClasses];

        // Ejecutar inferencia
        interpreter.run(inputBuffer, output);

        // Encontrar clase con mayor probabilidad
        float[] probabilities = output[0];
        int maxIdx = 0;
        float maxProb = probabilities[0];
        for (int i = 1; i < numClasses; i++) {
            if (probabilities[i] > maxProb) {
                maxProb = probabilities[i];
                maxIdx = i;
            }
        }

        // Verificar umbral
        if (maxProb < confidenceThreshold) {
            return null;
        }

        // Construir resultado
        Map<String, Object> result = new HashMap<>();
        result.put("label", labelMap.getOrDefault(maxIdx, "?"));
        result.put("confidence", maxProb);

        return result;
    }

    /**
     * Libera recursos del interprete TFLite.
     */
    public void close() {
        if (interpreter != null) {
            interpreter.close();
            interpreter = null;
        }
    }

    private MappedByteBuffer loadModelFile(Context context) throws Exception {
        android.content.res.AssetFileDescriptor assetFileDescriptor = context.getAssets().openFd(MODEL_FILE);
        FileInputStream inputStream = new FileInputStream(assetFileDescriptor.getFileDescriptor());
        FileChannel fileChannel = inputStream.getChannel();
        long startOffset = assetFileDescriptor.getStartOffset();
        long declaredLength = assetFileDescriptor.getDeclaredLength();
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
    }

    private Map<Integer, String> loadLabelMap(Context context) throws Exception {
        InputStream is = context.getAssets().open(LABEL_MAP_FILE);
        byte[] buffer = new byte[is.available()];
        is.read(buffer);
        is.close();

        String jsonString = new String(buffer);
        JSONObject jsonObject = new JSONObject(jsonString);

        Map<Integer, String> map = new HashMap<>();
        Iterator<String> keys = jsonObject.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            map.put(Integer.parseInt(key), jsonObject.getString(key));
        }

        return map;
    }
}

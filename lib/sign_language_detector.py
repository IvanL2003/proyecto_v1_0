"""
Script de detección de lenguaje de signos usando MediaPipe y TensorFlow Lite
Este script puede ser llamado desde Flutter usando Platform Channels o Chaquopy
"""

import cv2
import mediapipe as mp
import numpy as np
from typing import Dict, Tuple, Optional
import json


class SignLanguageDetector:
    """
    Detector de lenguaje de signos usando MediaPipe Hands
    """

    def __init__(self):
        # Inicializar MediaPipe Hands
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        self.mp_drawing = mp.solutions.drawing_utils

        # Diccionario simple de signos básicos (expandible)
        self.signs = {
            'hola': self._detect_hola,
            'gracias': self._detect_gracias,
            'por_favor': self._detect_por_favor,
            'adios': self._detect_adios,
            'si': self._detect_si,
            'no': self._detect_no,
        }

    def process_frame(self, frame: np.ndarray) -> Dict[str, any]:
        """
        Procesa un frame de la cámara y detecta el signo

        Args:
            frame: Frame de la cámara en formato numpy array (BGR)

        Returns:
            Diccionario con el signo detectado y la confianza
        """
        # Convertir BGR a RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Procesar la imagen
        results = self.hands.process(rgb_frame)

        if not results.multi_hand_landmarks:
            return {
                'sign': 'Ninguno',
                'confidence': 0.0,
                'landmarks': None
            }

        # Obtener los landmarks de la mano
        hand_landmarks = results.multi_hand_landmarks[0]

        # Extraer características
        landmarks = self._extract_landmarks(hand_landmarks)

        # Detectar el signo
        detected_sign, confidence = self._classify_sign(landmarks)

        return {
            'sign': detected_sign,
            'confidence': confidence,
            'landmarks': landmarks
        }

    def _extract_landmarks(self, hand_landmarks) -> np.ndarray:
        """
        Extrae las coordenadas de los landmarks de la mano

        Args:
            hand_landmarks: Landmarks detectados por MediaPipe

        Returns:
            Array numpy con las coordenadas [x, y, z] de cada landmark
        """
        landmarks = []
        for landmark in hand_landmarks.landmark:
            landmarks.extend([landmark.x, landmark.y, landmark.z])
        return np.array(landmarks)

    def _classify_sign(self, landmarks: np.ndarray) -> Tuple[str, float]:
        """
        Clasifica el signo basándose en los landmarks

        Args:
            landmarks: Array con las coordenadas de los landmarks

        Returns:
            Tupla con (nombre_del_signo, confianza)
        """
        max_confidence = 0.0
        detected_sign = 'Desconocido'

        # Verificar cada signo conocido
        for sign_name, detector_func in self.signs.items():
            confidence = detector_func(landmarks)
            if confidence > max_confidence:
                max_confidence = confidence
                detected_sign = sign_name.replace('_', ' ').title()

        # Solo retornar si la confianza es suficientemente alta
        if max_confidence < 0.5:
            return 'Desconocido', max_confidence

        return detected_sign, max_confidence

    # Funciones de detección de signos específicos
    # Estas son simplificadas y deberían ser reemplazadas con un modelo ML entrenado

    def _detect_hola(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'Hola' - mano abierta con palma hacia adelante"""
        # Extraer posiciones de los dedos (simplificado)
        thumb_tip = landmarks[12:15]
        index_tip = landmarks[24:27]
        middle_tip = landmarks[36:39]
        ring_tip = landmarks[48:51]
        pinky_tip = landmarks[60:63]

        # Verificar que todos los dedos estén extendidos
        fingers_extended = self._are_fingers_extended(landmarks)

        if sum(fingers_extended) >= 4:
            return 0.8
        return 0.3

    def _detect_gracias(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'Gracias' - mano tocando la barbilla"""
        # Simplificado: verificar posición de la mano cerca de la cara
        hand_center_y = np.mean([landmarks[i*3+1] for i in range(21)])
        if hand_center_y < 0.3:  # Parte superior del frame
            return 0.7
        return 0.2

    def _detect_por_favor(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'Por favor' - mano en círculo en el pecho"""
        return 0.6  # Placeholder

    def _detect_adios(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'Adiós' - mano moviéndose"""
        fingers_extended = self._are_fingers_extended(landmarks)
        if sum(fingers_extended) >= 3:
            return 0.75
        return 0.25

    def _detect_si(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'Sí' - puño cerrado moviéndose"""
        fingers_extended = self._are_fingers_extended(landmarks)
        if sum(fingers_extended) <= 1:
            return 0.7
        return 0.2

    def _detect_no(self, landmarks: np.ndarray) -> float:
        """Detecta el signo de 'No' - dedo índice moviéndose"""
        fingers_extended = self._are_fingers_extended(landmarks)
        if fingers_extended[1] and sum(fingers_extended) <= 2:
            return 0.75
        return 0.25

    def _are_fingers_extended(self, landmarks: np.ndarray) -> list:
        """
        Determina qué dedos están extendidos

        Returns:
            Lista de 5 booleanos [pulgar, índice, medio, anular, meñique]
        """
        # Índices de las puntas y articulaciones de cada dedo
        finger_tips = [4, 8, 12, 16, 20]  # Puntas
        finger_pips = [2, 6, 10, 14, 18]  # Articulaciones

        extended = []

        for tip_idx, pip_idx in zip(finger_tips, finger_pips):
            tip_y = landmarks[tip_idx * 3 + 1]
            pip_y = landmarks[pip_idx * 3 + 1]

            # Un dedo está extendido si la punta está más arriba que la articulación
            extended.append(tip_y < pip_y)

        return extended

    def close(self):
        """Libera los recursos"""
        self.hands.close()


def main():
    """
    Función principal para probar el detector con la cámara
    """
    detector = SignLanguageDetector()
    cap = cv2.VideoCapture(0)  # Cámara frontal

    print("Presiona 'q' para salir")

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Voltear horizontalmente para efecto espejo
        frame = cv2.flip(frame, 1)

        # Procesar el frame
        result = detector.process_frame(frame)

        # Mostrar resultados en el frame
        text = f"Signo: {result['sign']} ({result['confidence']:.2f})"
        cv2.putText(frame, text, (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        cv2.imshow('Sign Language Detector', frame)

        # Salir con 'q'
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    detector.close()


def process_image_from_flutter(image_data: dict) -> str:
    """
    Función que puede ser llamada desde Flutter

    Args:
        image_data: Diccionario con los datos de la imagen

    Returns:
        JSON string con el resultado
    """
    detector = SignLanguageDetector()

    # Reconstruir la imagen desde los datos de Flutter
    # (Este código dependerá de cómo Flutter envíe los datos)
    # Por ahora, retornamos un resultado de ejemplo

    result = {
        'sign': 'Hola',
        'confidence': 0.85
    }

    return json.dumps(result)


if __name__ == '__main__':
    main()

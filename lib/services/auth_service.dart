// =============================================================================
// Servicio de Autenticación Firebase (compartido con app SIMBA)
// =============================================================================
//
// Centraliza la lógica de Firebase Auth y el acceso a Firestore.
// Los datos (usuarios, IPs de servidor) son los mismos que usa la app SIMBA,
// ya que ambas apuntan al mismo proyecto Firebase (simba-cd72c).
//
// Operaciones:
//   - Registro con email y contraseña
//   - Inicio de sesión con email y contraseña
//   - Cierre de sesión
//   - Guardar / leer la IP del servidor en Firestore
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Getters de estado ────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Registro ─────────────────────────────────────────────────────────────

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'email': email.trim(),
        'serverIp': '',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Si Firestore falla, el usuario queda creado en Auth igualmente.
    }

    return credential;
  }

  // ── Login ────────────────────────────────────────────────────────────────

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Datos del usuario en Firestore ───────────────────────────────────────

  Future<void> saveServerIp(String ip) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .set(
            {'serverIp': ip.trim()},
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Fallo silencioso: la IP se mantiene en memoria local.
    }
  }

  Future<String> getServerIp() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.data()?['serverIp'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Utilidades ───────────────────────────────────────────────────────────

  static String translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este email ya está registrado.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Inténtalo más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../data/models/rule_model.dart';
import '../data/models/log_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth State ────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  // ── Google Sign In ────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        return await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── GitHub Sign In ────────────────────────────────────────
  Future<UserCredential?> signInWithGitHub() async {
    try {
      final provider = GithubAuthProvider();
      provider.addScope('user:email');
      if (kIsWeb) {
        return await _auth.signInWithPopup(provider);
      } else {
        return await _auth.signInWithProvider(provider);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Email/Password ────────────────────────────────────────
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email, password: password);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email, password: password);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) {});
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // ── Database Refs ─────────────────────────────────────────
  DatabaseReference get _rulesRef =>
    _db.ref('users/$uid/rules');

  DatabaseReference get _logsRef =>
    _db.ref('users/$uid/logs');

  DatabaseReference get _profileRef =>
    _db.ref('users/$uid/profile');

  // ── Rules ─────────────────────────────────────────────────
  Stream<List<RuleModel>> rulesStream() {
    return _rulesRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values.map((v) {
        return RuleModel.fromJson(Map<String, dynamic>.from(v as Map));
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> saveRule(RuleModel rule) async {
    await _rulesRef.child(rule.id).set(rule.toJson());
  }

  Future<void> deleteRule(String id) async {
    await _rulesRef.child(id).remove();
  }

  Future<void> toggleRule(String id, bool currentValue) async {
    await _rulesRef.child(id).update({'isEnabled': !currentValue});
  }

  Future<void> clearAllRules() async {
    await _rulesRef.remove();
  }

  // ── Logs ──────────────────────────────────────────────────
  Stream<List<LogModel>> logsStream() {
    return _logsRef.orderByChild('executedAt').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      return map.values.map((v) {
        return LogModel.fromJson(Map<String, dynamic>.from(v as Map));
      }).toList()
        ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
    });
  }

  Future<void> saveLog(LogModel log) async {
    await _logsRef.child(log.id).set(log.toJson());
  }

  Future<void> clearLogs() async {
    await _logsRef.remove();
  }

  // ── Profile ───────────────────────────────────────────────
  Future<void> saveProfile(Map<String, dynamic> data) async {
    await _profileRef.update(data);
  }

  Stream<Map<String, dynamic>> profileStream() {
    return _profileRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  // ── Save user info on first login ─────────────────────────
  Future<void> initUserProfile() async {
    final user = currentUser;
    if (user == null) return;
    final snap = await _profileRef.get();
    if (!snap.exists) {
      await _profileRef.set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'avatar': '🧑\u200d💻',
        'bio': 'Building smart automations',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }
}
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/shared/models/user_model.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class AuthProvider extends ChangeNotifier {
  final _db = Injector.instance<AppDB>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  bool _isLinkLoading = false;
  String? _errorMessage;
  String? _linkErrorMessage;
  bool _linkSuccess = false;

  bool get isGoogleLoading => _isGoogleLoading;
  bool get isGuestLoading => _isGuestLoading;
  bool get isLinkLoading => _isLinkLoading;
  String? get errorMessage => _errorMessage;
  String? get linkErrorMessage => _linkErrorMessage;
  bool get linkSuccess => _linkSuccess;

  Future<String> _getDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await info.androidInfo;
        return android.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? 'unknown_ios';
      }
    } catch (e) {
      e.logE;
    }
    return 'unknown_device';
  }

  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.userId)
        .set(user.toMap(), SetOptions(merge: true));
  }

  void _saveUserLocally(UserModel user) {
    _db.userModel = user;
  }

  /// Sign in with Google → Firebase Auth → Firestore → local storage
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;
      final deviceId = await _getDeviceId();

      // Check if user already exists in Firestore
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      UserModel user;
      if (doc.exists) {
        user = UserModel.fromMap(doc.data()!);
      } else {
        user = UserModel(
          userId: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email,
          deviceId: deviceId,
          xp: 0,
          level: 1,
          coin: 0,
          createdAt: DateTime.now(),
          isGuest: false,
          photoUrl: firebaseUser.photoURL,
        );
        await _saveUserToFirestore(user);
      }

      _saveUserLocally(user);
      _isGoogleLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      e.logE;
      _errorMessage = 'Google sign-in failed. Please try again.';
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Link a guest account to Google.
  Future<void> linkGoogleAccount() async {
    _isLinkLoading = true;
    _linkErrorMessage = null;
    _linkSuccess = false;
    notifyListeners();

    try {
      await GoogleSignIn.instance.signOut();

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final existingDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (existingDoc.exists) {
        _linkErrorMessage =
            'An account is already linked with the selected Google account.';
        _isLinkLoading = false;
        notifyListeners();
        return;
      }

      if (firebaseUser.email != null) {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .limit(1)
            .get();
        if (emailQuery.docs.isNotEmpty) {
          _linkErrorMessage =
              'An account is already linked with the selected email address.';
          _isLinkLoading = false;
          notifyListeners();
          return;
        }
      }

      final guestUser = _db.userModel!;
      final oldDocId = guestUser.userId;

      final linkedUser = guestUser.copyWith(
        userId: firebaseUser.uid,
        name: firebaseUser.displayName ?? guestUser.name,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        isGuest: false,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(linkedUser.toMap());

      await _firestore.collection('users').doc(oldDocId).delete();

      _saveUserLocally(linkedUser);
      _linkSuccess = true;
    } catch (e) {
      e.logE;
      _linkErrorMessage = 'Failed to link account. Please try again.';
    } finally {
      _isLinkLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _db.logoutUser();
    notifyListeners();
  }

  /// Continue as Guest
  Future<bool> continueAsGuest() async {
    _isGuestLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await _getDeviceId();

      final docRef = _firestore.collection('users').doc();
      final user = UserModel(
        userId: docRef.id,
        name: 'Guest User',
        deviceId: deviceId,
        xp: 0,
        level: 1,
        coin: 0,
        createdAt: DateTime.now(),
        isGuest: true,
      );

      await docRef.set(user.toMap());
      _saveUserLocally(user);

      _isGuestLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      e.logE;
      _errorMessage = 'Could not continue as guest. Please try again.';
      _isGuestLoading = false;
      notifyListeners();
      return false;
    }
  }
}

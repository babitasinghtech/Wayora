import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/views/auth/otp_screen.dart';

enum OtpMethod { phone, email }

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;

  User? user;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool get isLoggedIn => user != null;

  // ---------- OTP state ----------
  OtpMethod otpMethod = OtpMethod.phone;
  String otpTarget = ''; // phone number (+91...) or email being verified
  bool isVerifying = false;
  String? _verificationId;
  int? _resendToken;

  String get displayName {
    final name = user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Wayora';
  }

  /// Email if the user has one, otherwise the phone number.
  String get contact {
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email;
    return user?.phoneNumber ?? '';
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return displayName[0].toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    user = _auth.currentUser;
    _syncProfile(user);
    _sub = _auth.authStateChanges().listen((u) {
      user = u;
      update();
      _syncProfile(u); // keep users/{uid} up to date (chat + calls need it)
    });
  }

  Future<void> _syncProfile(User? u) async {
    if (u == null) return;
    try {
      await Db.saveProfile(u);
    } catch (e) {
      debugPrint('profile sync failed: $e');
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void togglePassword() {
    obscurePassword = !obscurePassword;
    update();
  }

  void toggleConfirm() {
    obscureConfirm = !obscureConfirm;
    update();
  }

  void _setLoading(bool v) {
    isLoading = v;
    update();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _toast('Welcome back', 'Logged in successfully', ok: true);
    } on FirebaseAuthException catch (e) {
      _toast('Login failed', _friendly(e), ok: false);
    } catch (e) {
      _toast('Error', e.toString(), ok: false);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
      user = _auth.currentUser;
      update();
      _syncProfile(user); // save the real name
      Get.until((route) => route.isFirst);
      _toast('Account created', 'Welcome, $name!', ok: true);
    } on FirebaseAuthException catch (e) {
      _toast('Sign up failed', _friendly(e), ok: false);
    } catch (e) {
      _toast('Error', e.toString(), ok: false);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _toast('Logged out', 'See you soon!', ok: true);
    } catch (e) {
      _toast('Error', e.toString(), ok: false);
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _toast(
        'Enter your email',
        'Type your email above first, then tap "Forgot password?"',
        ok: false,
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _toast('Email sent', 'Check $email for the reset link', ok: true);
    } on FirebaseAuthException catch (e) {
      _toast('Failed', _friendly(e), ok: false);
    }
  }

  // =====================================================
  //                    OTP LOGIN
  // =====================================================

  // ---------- Mobile OTP (Firebase Phone Auth) ----------
  Future<void> sendPhoneOtp(String phone, {bool isResend = false}) async {
    _setLoading(true);
    otpMethod = OtpMethod.phone;
    otpTarget = phone;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        // Android may read the SMS / verify instantly - no typing needed.
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            _finishLogin();
          } on FirebaseAuthException catch (e) {
            _setLoading(false);
            _toast('Login failed', _friendly(e), ok: false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          _toast('Could not send OTP', _friendly(e), ok: false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _setLoading(false);
          _toast('OTP sent', 'We sent a 6-digit code to $phone', ok: true);
          if (!isResend) Get.to(() => const OtpScreen());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _toast('Could not send OTP', _friendly(e), ok: false);
    } catch (e) {
      _setLoading(false);
      _toast('Error', e.toString(), ok: false);
    }
  }

  // ---------- Email OTP (Cloud Functions - see /functions) ----------
  Future<void> sendEmailOtp(String email, {bool isResend = false}) async {
    _setLoading(true);
    otpMethod = OtpMethod.email;
    otpTarget = email.trim().toLowerCase();
    try {
      await FirebaseFunctions.instance.httpsCallable('sendEmailOtp').call({
        'email': otpTarget,
      });
      _toast('OTP sent', 'We emailed a 6-digit code to $otpTarget', ok: true);
      if (!isResend) Get.to(() => const OtpScreen());
    } on FirebaseFunctionsException catch (e) {
      _toast(
        'Could not send OTP',
        e.message ?? 'Server error (${e.code})',
        ok: false,
      );
    } catch (e) {
      _toast('Error', e.toString(), ok: false);
    } finally {
      _setLoading(false);
    }
  }

  // ---------- verify the 6-digit code (phone or email) ----------
  /// Returns true when the user is signed in.
  Future<bool> verifyOtp(String code) async {
    isVerifying = true;
    update();
    try {
      if (otpMethod == OtpMethod.phone) {
        final id = _verificationId;
        if (id == null) {
          _toast('Session expired', 'Please request a new OTP.', ok: false);
          return false;
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: id,
          smsCode: code,
        );
        await _auth.signInWithCredential(credential);
      } else {
        final res = await FirebaseFunctions.instance
            .httpsCallable('verifyEmailOtp')
            .call({'email': otpTarget, 'code': code});
        final token = (res.data as Map)['token'] as String;
        await _auth.signInWithCustomToken(token);
      }
      _finishLogin();
      return true;
    } on FirebaseAuthException catch (e) {
      _toast('Verification failed', _friendly(e), ok: false);
    } on FirebaseFunctionsException catch (e) {
      _toast(
        'Verification failed',
        e.message ?? 'Server error (${e.code})',
        ok: false,
      );
    } catch (e) {
      _toast('Error', e.toString(), ok: false);
    } finally {
      isVerifying = false;
      update();
    }
    return false;
  }

  Future<void> resendOtp() async {
    if (otpMethod == OtpMethod.phone) {
      await sendPhoneOtp(otpTarget, isResend: true);
    } else {
      await sendEmailOtp(otpTarget, isResend: true);
    }
  }

  void _finishLogin() {
    isLoading = false;
    isVerifying = false;
    update();
    // close the OTP page; the root widget already switched to Home
    Get.until((route) => route.isFirst);
    _toast('Welcome', 'Logged in successfully', ok: true);
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      case 'invalid-phone-number':
        return 'Enter a valid mobile number.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please try again.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS limit reached. Try again later or use a test number.';
      case 'captcha-check-failed':
        return 'Verification failed. Please try again.';
      case 'missing-client-identifier':
        return 'App verification failed. Add SHA-1 / SHA-256 in Firebase and enable Phone sign-in.';
      case 'invalid-custom-token':
      case 'custom-token-mismatch':
        return 'Sign-in token rejected. Check the Cloud Functions setup.';
      default:
        return e.message ?? 'Something went wrong (${e.code}).';
    }
  }

  void _toast(String title, String msg, {required bool ok}) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
      colorText: Colors.white,
      icon: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 3),
    );
  }
}

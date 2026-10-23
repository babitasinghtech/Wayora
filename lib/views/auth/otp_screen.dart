import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  static const _resendSeconds = 30;

  final AuthController _auth = Get.find<AuthController>();
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _seconds = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_auth.isVerifying) return;
    if (_code.text.length != _length) {
      Get.snackbar(
        'Enter the code',
        'Please enter the 6-digit OTP.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await _auth.verifyOtp(_code.text);
    if (!ok && mounted) {
      _code.clear();
      setState(() {});
      _focus.requestFocus();
    }
  }

  Future<void> _resend() async {
    _code.clear();
    await _auth.resendOtp();
    if (mounted) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _auth.otpMethod == OtpMethod.phone;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.kDark, AppColor.kPrimary],
              ),
            ),
          ),
          Image.network(
            AppColor.kBgImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColor.kPrimary, Color(0xFF3DDC97)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.kPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPhone
                                  ? Icons.sms_rounded
                                  : Icons.mark_email_read_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Verify OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit code we sent ${isPhone ? 'by SMS' : 'to your email'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _auth.otpTarget,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF5CF2C8),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // glass card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilterCard(
                              child: Column(
                                children: [
                                  _otpBoxes(),
                                  const SizedBox(height: 26),
                                  GetBuilder<AuthController>(
                                    builder: (c) => _gradientButton(
                                      label: 'VERIFY & LOGIN',
                                      loading: c.isVerifying,
                                      onPressed: _verify,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _seconds > 0
                                            ? 'Resend code in 00:${_seconds.toString().padLeft(2, '0')}'
                                            : "Didn't get the code?",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (_seconds <= 0)
                                        GetBuilder<AuthController>(
                                          builder: (c) => TextButton(
                                            onPressed: c.isLoading
                                                ? null
                                                : _resend,
                                            child: const Text(
                                              'Resend OTP',
                                              style: TextStyle(
                                                color: Color(0xFF5CF2C8),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: Get.back,
                                    child: Text(
                                      isPhone
                                          ? 'Change mobile number'
                                          : 'Change email',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Six boxes drawn on top of one invisible TextField that does the typing.
  Widget _otpBoxes() {
    final text = _code.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: List.generate(_length, (i) {
              final filled = i < text.length;
              final active =
                  _focus.hasFocus &&
                  (i == text.length ||
                      (text.length == _length && i == _length - 1));
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: filled ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF5CF2C8)
                          : Colors.white.withValues(alpha: filled ? 0.6 : 0.25),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? text[i] : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _code,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_length),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (v) {
                  setState(() {});
                  if (v.length == _length) _verify(); // auto-submit
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.kPrimary, Color(0xFF2FD3A3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}

/// Frosted-glass container used for the card.
class BackdropFilterCard extends StatelessWidget {
  const BackdropFilterCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: child,
      ),
    );
  }
}

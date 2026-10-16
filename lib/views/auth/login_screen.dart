import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/views/auth/signup_screen.dart';

enum _LoginTab { email, mobile }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _dialCodes = ['+91', '+1', '+44', '+971', '+92', '+880', '+977', '+94', '+61', '+65'];

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  _LoginTab _tab = _LoginTab.email;
  bool _emailOtp = false; // email tab: false = password, true = OTP
  String _dial = '+91';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _buttonLabel {
    if (_tab == _LoginTab.mobile || _emailOtp) return 'SEND OTP';
    return 'LOGIN';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_tab == _LoginTab.mobile) {
      await _auth.sendPhoneOtp('$_dial${_phone.text.trim()}');
    } else if (_emailOtp) {
      await _auth.sendEmailOtp(_email.text.trim());
    } else {
      await _auth.login(_email.text.trim(), _password.text);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix, String? prefixText}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: border(Colors.white24),
      enabledBorder: border(Colors.white.withValues(alpha: 0.25)),
      focusedBorder: border(Colors.white, 1.6),
      errorBorder: border(const Color(0xFFFF8A80)),
      focusedErrorBorder: border(const Color(0xFFFF8A80), 1.6),
      errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
    );
  }

  Widget _tabButton(String label, IconData icon, _LoginTab value) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tab == value) return;
          setState(() => _tab = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColor.kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailField() => TextFormField(
    key: const ValueKey('email-field'),
    controller: _email,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white,
    keyboardType: TextInputType.emailAddress,
    textInputAction: _emailOtp ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: (_) {
      if (_emailOtp) _submit();
    },
    decoration: _decoration('Email', Icons.email_outlined),
    validator: (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return 'Email is required';
      if (!GetUtils.isEmail(t)) return 'Enter a valid email';
      return null;
    },
  );

  Widget _passwordField() => GetBuilder<AuthController>(
    builder: (c) => TextFormField(
      key: const ValueKey('password-field'),
      controller: _password,
      obscureText: c.obscurePassword,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: _decoration(
        'Password',
        Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: c.togglePassword,
          icon: Icon(
            c.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'At least 6 characters';
        return null;
      },
    ),
  );

  Widget _phoneField() => Row(
    key: const ValueKey('phone-row'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _dial,
            dropdownColor: const Color(0xFF1B3A38),
            iconEnabledColor: Colors.white70,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            items: _dialCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _dial = v ?? _dial),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: _phone,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          maxLength: 12,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: _decoration('Mobile number', Icons.phone_android_rounded),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Mobile number is required';
            if (!RegExp(r'^\d+$').hasMatch(t)) return 'Digits only';
            if (_dial == '+91' && !RegExp(r'^[6-9]\d{9}$').hasMatch(t)) {
              return 'Enter a valid 10-digit number';
            }
            if (t.length < 6) return 'Number is too short';
            return null;
          },
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
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
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
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
                              color: AppColor.kPrimary.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Wanderly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discover the world, one trip at a time',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ---- Email | Mobile switcher ----
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        _tabButton('Email', Icons.email_outlined, _LoginTab.email),
                                        _tabButton('Mobile', Icons.phone_android_rounded, _LoginTab.mobile),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  if (_tab == _LoginTab.email) ...[
                                    _emailField(),
                                    if (!_emailOtp) ...[
                                      const SizedBox(height: 16),
                                      _passwordField(),
                                    ],
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          if (_emailOtp) {
                                            setState(() => _emailOtp = false);
                                          } else {
                                            _auth.resetPassword(_email.text.trim());
                                          }
                                        },
                                        child: Text(
                                          _emailOtp ? 'Use password instead' : 'Forgot password?',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    _phoneField(),
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(4, 10, 4, 14),
                                      child: Text(
                                        "We'll text you a 6-digit code to verify your number.",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 4),
                                  GetBuilder<AuthController>(
                                    builder: (c) => Container(
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
                                        onPressed: c.isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          disabledBackgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: c.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.6,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _buttonLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  // email tab: switch between password and OTP
                                  if (_tab == _LoginTab.email && !_emailOtp)
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () => setState(() => _emailOtp = true),
                                        icon: const Icon(Icons.pin_outlined, size: 18, color: Color(0xFF5CF2C8)),
                                        label: const Text(
                                          'Login with email OTP instead',
                                          style: TextStyle(color: Color(0xFF5CF2C8), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account?",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.to(() => const SignUpScreen()),
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color: Color(0xFF5CF2C8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

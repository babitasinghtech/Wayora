import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/appcolor.dart';
import 'auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _auth.signUp(_name.text.trim(), _email.text.trim(), _password.text);
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
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

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
    onPressed: onTap,
    icon: Icon(
      obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: Colors.white70,
    ),
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
            AppColor.kBgImagesign,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.80),
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
                          const SizedBox(height: 24),
                          const Text(
                            'Join Wanderly',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create an account and start exploring',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  26,
                                  22,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        decoration: _decoration(
                                          'Full name',
                                          Icons.person_outline_rounded,
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                            ? 'Name is required'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _email,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        cursorColor: Colors.white,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: _decoration(
                                          'Email',
                                          Icons.email_outlined,
                                        ),
                                        validator: (v) {
                                          final t = v?.trim() ?? '';
                                          if (t.isEmpty)
                                            return 'Email is required';
                                          if (!GetUtils.isEmail(t))
                                            return 'Enter a valid email';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      GetBuilder<AuthController>(
                                        builder: (c) => TextFormField(
                                          controller: _password,
                                          obscureText: c.obscurePassword,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          cursorColor: Colors.white,
                                          textInputAction: TextInputAction.next,
                                          decoration: _decoration(
                                            'Password',
                                            Icons.lock_outline_rounded,
                                            suffix: _eye(
                                              c.obscurePassword,
                                              c.togglePassword,
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Password is required';
                                            if (v.length < 6)
                                              return 'At least 6 characters';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GetBuilder<AuthController>(
                                        builder: (c) => TextFormField(
                                          controller: _confirm,
                                          obscureText: c.obscureConfirm,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          cursorColor: Colors.white,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          decoration: _decoration(
                                            'Confirm password',
                                            Icons.verified_user_outlined,
                                            suffix: _eye(
                                              c.obscureConfirm,
                                              c.toggleConfirm,
                                            ),
                                          ),
                                          validator: (v) => v != _password.text
                                              ? 'Passwords do not match'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      GetBuilder<AuthController>(
                                        builder: (c) => Container(
                                          width: double.infinity,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColor.kPrimary,
                                                Color(0xFF2FD3A3),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColor.kPrimary
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: c.isLoading
                                                ? null
                                                : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              disabledBackgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: c.isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.6,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'CREATE ACCOUNT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Already have an account?',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: Get.back,
                                            child: const Text(
                                              'Login',
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
}

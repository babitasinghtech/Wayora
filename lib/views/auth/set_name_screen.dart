import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

/// Shown right after phone-OTP login when the user has no name yet.
/// The user cannot go past this screen until a name is saved.
class SetNameScreen extends StatefulWidget {
  const SetNameScreen({super.key});

  @override
  State<SetNameScreen> createState() => _SetNameScreenState();
}

class _SetNameScreenState extends State<SetNameScreen> {
  final AuthController _auth = Get.find<AuthController>();
  final TextEditingController _name = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _auth.saveName(_name.text);
    // On success AuthController.update() rebuilds the root and opens Home.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // name is compulsory
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColor.kDark, AppColor.kPrimary],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'What should we call you?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your name will be shown on your posts and comments instead of your mobile number.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          style: const TextStyle(color: AppColor.kInk),
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: AppColor.kPrimary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Name is required';
                            if (t.length < 2) return 'Enter at least 2 letters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        GetBuilder<AuthController>(
                          builder: (c) => SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: c.isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColor.kDark,
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
                                      ),
                                    )
                                  : const Text(
                                      'CONTINUE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _auth.logout,
                          child: const Text(
                            'Use a different number',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

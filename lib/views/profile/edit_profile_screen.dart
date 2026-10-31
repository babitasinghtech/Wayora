import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_learn_new_app/controllers/edit_profile_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/notifications/notifications_screen.dart';
import 'package:login_learn_new_app/views/profile/widgets/profile_widgets.dart';
import 'package:login_learn_new_app/widgets/common.dart' show softShadow;

/// Edit profile. UI only - form logic lives in [EditProfileController].
/// Name, bio and photo are editable; the login phone / email is read-only.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditProfileController>(
      init: EditProfileController(),
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColor.kInk),
          title: const Text(
            'Edit profile',
            style: TextStyle(color: AppColor.kInk, fontWeight: FontWeight.w800),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              _photo(c),
              const SizedBox(height: 24),
              _label('Personal info'),
              _card(
                Column(
                  children: [
                    TextField(
                      controller: c.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Full name', Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: c.bio,
                      maxLines: 2,
                      maxLength: EditProfileController.maxBio,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec('About you (optional)', Icons.edit_note_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _label('Login details'),
              _card(_loginDetails(c)),
              const Padding(
                padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
                child: Text(
                  'Your login mobile number / email cannot be changed here.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
              const SizedBox(height: 18),
              _label('Settings'),
              ProfileMenuTile(
                icon: Icons.credit_card_rounded,
                title: 'Payment methods',
                onTap: () => profileSoon('Payments'),
              ),
              ProfileMenuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => Get.to(() => const NotificationsScreen()),
              ),
              ProfileMenuTile(
                icon: Icons.shield_outlined,
                title: 'Privacy & security',
                onTap: () => profileSoon('Privacy'),
              ),
              const SizedBox(height: 10),
              _saveButton(c),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- parts
  Widget _photo(EditProfileController c) {
    return Center(
      child: Stack(
        children: [
          ProfileAvatar(
            initials: c.auth.initials,
            radius: 52,
            photo: c.photo,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _photoSheet(c),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColor.kPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _photoSheet(EditProfileController c) {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                c.pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Get.back();
                c.pickPhoto(ImageSource.camera);
              },
            ),
            if (c.photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Remove photo', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Get.back();
                  c.deletePhoto();
                },
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Widget _loginDetails(EditProfileController c) {
    final u = c.auth.user;
    final hasEmail = (u?.email ?? '').isNotEmpty;
    return Column(
      children: [
        if (hasEmail) ...[
          ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: u!.email!,
            locked: true,
          ),
          const Divider(height: 22),
          ProfileInfoRow(
            icon: Icons.verified_outlined,
            label: 'Email verified',
            value: (u.emailVerified) ? 'Yes' : 'No',
          ),
        ] else
          ProfileInfoRow(
            icon: Icons.phone_android_rounded,
            label: 'Mobile number',
            value: u?.phoneNumber ?? '-',
            locked: true,
          ),
        const Divider(height: 22),
        ProfileInfoRow(
          icon: Icons.event_available_outlined,
          label: 'Member since',
          value: formatDate(u?.metadata.creationTime),
        ),
      ],
    );
  }

  Widget _saveButton(EditProfileController c) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: c.name,
      builder: (context, v1, child) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: c.bio,
        builder: (context, v2, child) {
          final enabled = c.hasChanges && !c.isSaving;
          return SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: enabled
                  ? () async {
                      FocusScope.of(context).unfocus();
                      if (await c.save()) Get.back();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: c.isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      t,
      style: const TextStyle(
        color: AppColor.kInk,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: softShadow,
    ),
    child: child,
  );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColor.kPrimary),
    filled: true,
    fillColor: const Color(0xFFF2F6F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

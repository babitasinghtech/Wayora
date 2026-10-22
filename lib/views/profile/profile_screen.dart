import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/views/home/home_screen.dart';
import 'package:login_learn_new_app/views/saved/saved_screen.dart';
import 'package:login_learn_new_app/views/profile/widgets/profile_posts_stat.dart';
import 'package:login_learn_new_app/views/post/my_posts_screen.dart';
import 'package:login_learn_new_app/views/profile/edit_profile_screen.dart';
import 'package:login_learn_new_app/views/profile/widgets/profile_widgets.dart';

final AuthController auth = Get.find<AuthController>();
Widget profileTab(HomeController h) {
  return GetBuilder<AuthController>(
    builder: (a) {
          return ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 50),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.kDark, AppColor.kPrimary],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Get.to(() => const EditProfileScreen()),
                  child: ProfileAvatar(
                    initials: a.initials,
                    radius: 46,
                    ring: Colors.white,
                    photo: a.photoBytes,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  a.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (a.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      a.bio,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // stats card overlapping the header
          Transform.translate(
            offset: const Offset(0, -38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _softShadow,
                ),
                child: Row(
                  children: [
                    _stat('12', 'Trips'),
                    _divider(),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: openSaved,
                        child: Row(children: [_stat('${h.saved.length}', 'Saved')]),
                      ),
                    ),
                    _divider(),
                    const ProfilePostsStat(),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ProfileMenuTile(
                  icon: Icons.grid_view_rounded,
                  title: 'My posts',
                  onTap: openMyPosts,
                ),
                ProfileMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  onTap: () => Get.to(() => const EditProfileScreen()),
                ),
                ProfileMenuTile(
                  icon: Icons.favorite_border,
                  title: 'Saved',
                  onTap: openSaved,
                ),
                ProfileMenuTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help center',
                  onTap: () => profileSoon('Help'),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Wanderly v1.0.0',
                  style: TextStyle(color: Colors.black38, fontSize: 12),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      );
    },
  );
}

void _confirmLogout() {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 32),
      title: const Text('Logout?'),
      content: const Text('You will need to sign in again to see your trips.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            Get.back();
            auth.logout();
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];
Widget _divider() => Container(width: 1, height: 34, color: Colors.black12);

Widget _stat(String value, String label) => Expanded(
  child: Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColor.kInk,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
    ],
  ),
);

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:login_learn_new_app/appcolor.dart';
import 'package:login_learn_new_app/auth/auth_controller.dart';
import 'package:login_learn_new_app/home/home_screen.dart';

final HomeController h = Get.put(HomeController());
final AuthController auth = Get.find<AuthController>();
Widget profileTab(HomeController h) {
  return GetBuilder<AuthController>(
    builder: (a) {
      final u = a.user;
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
                _Avatar(initials: a.initials, radius: 46, ring: Colors.white),
                const SizedBox(height: 14),
                Text(
                  a.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.contact,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
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
                    _stat('${h.saved.length}', 'Saved'),
                    _divider(),
                    _stat('8', 'Reviews'),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _menuTile(
                  Icons.person_outline_rounded,
                  'Edit profile',
                  () => _soon('Edit profile'),
                ),
                _menuTile(
                  Icons.credit_card_rounded,
                  'Payment methods',
                  () => _soon('Payments'),
                ),
                _menuTile(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  () => _soon('Notifications'),
                ),
                _menuTile(
                  Icons.shield_outlined,
                  'Privacy & security',
                  () => _soon('Privacy'),
                ),
                _menuTile(
                  Icons.help_outline_rounded,
                  'Help center',
                  () => _soon('Help'),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _softShadow,
                  ),
                  child: Column(
                    children: [
                      (u?.email ?? '').isNotEmpty
                          ? _infoRow(
                              Icons.verified_outlined,
                              'Email verified',
                              (u?.emailVerified ?? false) ? 'Yes' : 'No',
                            )
                          : _infoRow(
                              Icons.phone_android_rounded,
                              'Mobile number',
                              u?.phoneNumber ?? '-',
                            ),
                      const Divider(height: 22),
                      _infoRow(
                        Icons.event_available_outlined,
                        'Member since',
                        _fmtDate(u?.metadata.creationTime),
                      ),
                    ],
                  ),
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

Widget _divider() => Container(width: 1, height: 34, color: Colors.black12);

Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: _softShadow,
    ),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColor.kPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColor.kPrimary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
    ),
  );
}

Widget _infoRow(IconData icon, String label, String value) => Row(
  children: [
    Icon(icon, color: AppColor.kPrimary, size: 22),
    const SizedBox(width: 12),
    Expanded(
      child: Text(label, style: const TextStyle(color: Colors.black54)),
    ),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  ],
);

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final l = d.toLocal();
  return '${l.day} ${m[l.month - 1]} ${l.year}';
}

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.radius, this.ring});
  final String initials;
  final double radius;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring == null
            ? const LinearGradient(
                colors: [AppColor.kPrimary, AppColor.kAccent],
              )
            : null,
        color: ring,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE6F6F3),
        child: Text(
          initials,
          style: TextStyle(
            color: AppColor.kDark,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

void _soon(String what) {
  Get.snackbar(
    what,
    'This feature is coming soon.',
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    backgroundColor: AppColor.kDark,
    colorText: Colors.white,
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

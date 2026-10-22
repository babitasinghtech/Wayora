import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/widgets/common.dart' show softShadow;

/// Round profile picture: the uploaded photo, or the initials as fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    required this.radius,
    this.photo,
    this.ring,
  });
  final String initials;
  final double radius;
  final Uint8List? photo;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring == null
            ? const LinearGradient(colors: [AppColor.kPrimary, AppColor.kAccent])
            : null,
        color: ring,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE6F6F3),
        backgroundImage: photo == null ? null : MemoryImage(photo!),
        child: photo != null
            ? null
            : Text(
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

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow,
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
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.locked = false,
  });
  final IconData icon;
  final String label, value;
  final bool locked; // read-only field (shows a lock)

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColor.kPrimary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (locked) ...[
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black38),
        ],
      ],
    );
  }
}

void profileSoon(String what) {
  Get.snackbar(
    what,
    'This feature is coming soon.',
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    backgroundColor: AppColor.kDark,
    colorText: Colors.white,
  );
}

String formatDate(DateTime? d) {
  if (d == null) return '-';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final l = d.toLocal();
  return '${l.day} ${m[l.month - 1]} ${l.year}';
}

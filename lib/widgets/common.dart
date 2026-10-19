import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.radius = 22});
  final String name;
  final double radius;

  static const _palette = [
    [Color(0xFF12A594), Color(0xFF3DDC97)],
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFFFF8A3D), Color(0xFFFFB86B)],
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
    [Color(0xFFE84393), Color(0xFFFD79A8)],
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '' : trimmed[0].toUpperCase();
    final isLetter = RegExp(r'[A-Za-z]').hasMatch(letter);
    final colors = _palette[trimmed.hashCode.abs() % _palette.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: isLetter
          ? Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(Icons.person_rounded, color: Colors.white, size: radius * 1.1),
    );
  }
}

final List<BoxShadow> softShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${t.day}/${t.month}/${t.year}';
}

String clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

void showToast(String title, String msg, {bool ok = true}) {
  Get.snackbar(
    title,
    msg,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    backgroundColor: ok ? AppColor.kPrimary : const Color(0xFFE74C3C),
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );
}

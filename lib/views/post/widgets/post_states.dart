import 'package:flutter/material.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

/// Placeholder cards shown while the first posts load.
class PostFeedSkeleton extends StatelessWidget {
  const PostFeedSkeleton({super.key});

  Widget _box(double w, double h, {double r = 8}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFE3EEEE),
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 3,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(42, 42, r: 21),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(110, 12), const SizedBox(height: 6), _box(50, 10)],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _box(double.infinity, 12),
            const SizedBox(height: 8),
            _box(200, 12),
            const SizedBox(height: 14),
            _box(double.infinity, 160, r: 18),
          ],
        ),
      ),
    );
  }
}

class PostEmptyView extends StatelessWidget {
  const PostEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.photo_camera_back_rounded, size: 56, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'No posts yet.\nBe the first to share a moment!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class PostErrorView extends StatelessWidget {
  const PostErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              'Could not load posts',
              style: TextStyle(
                color: AppColor.kInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet and that Firestore is created with the rules deployed.\n\n$message',
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColor.kPrimary),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

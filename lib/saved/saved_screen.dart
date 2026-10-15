import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:login_learn_new_app/appcolor.dart';
import 'package:login_learn_new_app/home/home_screen.dart';

Widget savedTab(HomeController h) {
  final list = h.savedList;
  return SafeArea(
    bottom: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Text(
            'Saved places',
            style: TextStyle(
              color: AppColor.kInk,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: AppColor.kPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 52,
                            color: AppColor.kPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Nothing saved yet',
                          style: TextStyle(
                            color: AppColor.kInk,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the heart on any destination to keep it here for later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => h.setTab(1),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.kPrimary,
                          ),
                          child: const Text('Explore places'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _listTile(h, list[i], 'saved'),
                  ),
                ),
        ),
      ],
    ),
  );
}

String _money(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

void _open(Destination d, String tag) {
  Get.to(() => DestinationDetail(destination: d, heroTag: tag));
}

Widget _listTile(HomeController h, Destination d, String prefix) {
  final tag = '$prefix-${d.name}';
  return GestureDetector(
    onTap: () => _open(d, tag),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Hero(tag: tag, child: _NetImg(d.image)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColor.kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      d.country,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFFFB400),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      d.rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      _money(d.price),
                      style: const TextStyle(
                        color: AppColor.kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      ' /person',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => h.toggleSave(d),
            icon: Icon(
              h.isSaved(d)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: h.isSaved(d) ? Colors.redAccent : Colors.black38,
            ),
          ),
        ],
      ),
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

class _NetImg extends StatelessWidget {
  const _NetImg(this.url);
  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFE3EEEE)),
      errorBuilder: (context, error, stack) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColor.kDark, AppColor.kPrimary],
          ),
        ),
        child: const Center(
          child: Icon(Icons.landscape_rounded, color: Colors.white54, size: 40),
        ),
      ),
    );
  }
}

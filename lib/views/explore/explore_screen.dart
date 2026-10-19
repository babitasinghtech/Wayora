import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/home/home_screen.dart';
import 'package:login_learn_new_app/views/saved/saved_screen.dart';

String _img(String id) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=900&q=80';

final List<Destination> _destinations = [
  Destination(
    name: 'Maldives Islands',
    country: 'Maldives',
    category: 'Beach',
    rating: 4.9,
    price: 1299,
    days: 6,
    image: _img('1514282401047-d79a71a590e8'),
    description:
        'Crystal-clear lagoons, overwater villas and white-sand beaches. Perfect for snorkelling, sunset cruises and doing absolutely nothing.',
  ),
  Destination(
    name: 'Swiss Alps',
    country: 'Switzerland',
    category: 'Mountain',
    rating: 4.8,
    price: 1099,
    days: 5,
    image: _img('1531366936337-7c912a4589a7'),
    description:
        'Snow-capped peaks, scenic train rides and cosy mountain villages. Ski in winter, hike alpine trails in summer.',
  ),
  Destination(
    name: 'Santorini',
    country: 'Greece',
    category: 'Beach',
    rating: 4.8,
    price: 999,
    days: 5,
    image: _img('1570077188670-e3a8d69ac5ff'),
    description:
        'White-washed houses, blue domes and the most famous sunsets in the Aegean. Wine tasting and caldera views included.',
  ),
  Destination(
    name: 'Paris',
    country: 'France',
    category: 'City',
    rating: 4.7,
    price: 899,
    days: 4,
    image: _img('1502602898657-3e91760cbb34'),
    description:
        'Museums, cafés and the Eiffel Tower lit up at night. A city made for slow walks and long dinners.',
  ),
  Destination(
    name: 'Tokyo',
    country: 'Japan',
    category: 'City',
    rating: 4.8,
    price: 1199,
    days: 7,
    image: _img('1540959733332-eab4deabeeaf'),
    description:
        'Neon streets, sushi counters, quiet temples and bullet trains. Tradition and the future side by side.',
  ),
  Destination(
    name: 'Banff National Park',
    country: 'Canada',
    category: 'Mountain',
    rating: 4.9,
    price: 1049,
    days: 5,
    image: _img('1501785888041-af3ef285b470'),
    description:
        'Turquoise lakes, glaciers and wildlife in the Canadian Rockies. Ideal for hiking, canoeing and stargazing.',
  ),
  Destination(
    name: 'Ubud, Bali',
    country: 'Indonesia',
    category: 'Forest',
    rating: 4.7,
    price: 799,
    days: 6,
    image: _img('1537996194471-e657df975ab4'),
    description:
        'Rice terraces, jungle waterfalls and wellness retreats in the cultural heart of Bali.',
  ),
  Destination(
    name: 'Redwood Forest',
    country: 'USA',
    category: 'Forest',
    rating: 4.6,
    price: 699,
    days: 3,
    image: _img('1441974231531-c6227db76b6e'),
    description:
        'Walk among the tallest trees on Earth. Misty trails, fresh air and complete silence.',
  ),
];
final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];
Widget exploreTab(HomeController h) {
  return SafeArea(
    bottom: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Explore Places',
                  style: TextStyle(
                    color: AppColor.kInk,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: openSaved,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: _softShadow,
                  ),
                  child: Badge(
                    isLabelVisible: h.saved.isNotEmpty,
                    label: Text('${h.saved.length}'),
                    child: Icon(
                      h.saved.isNotEmpty
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _placesTab(h)),
      ],
    ),
  );
}

Widget _exploreToggle(
  HomeController h,
  int index,
  String label,
  IconData icon,
) {
  final selected = h.exploreView == index;
  return Expanded(
    child: GestureDetector(
      onTap: () => h.setExploreView(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColor.kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _placesTab(HomeController h) {
  return SafeArea(
    bottom: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${_destinations.length} places picked for you',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: _destinations.length,
            itemBuilder: (context, i) {
              final d = _destinations[i];
              final tag = 'grid-${d.name}';
              return GestureDetector(
                onTap: () => _open(d, tag),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: tag, child: _NetImg(d.image)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.5, 1],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _HeartButton(
                          saved: h.isSaved(d),
                          onTap: () => h.toggleSave(d),
                          size: 34,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Color(0xFFFFC857),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${d.rating}  •  ${d.country}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

void _open(Destination d, String tag) {
  Get.to(() => DestinationDetail(destination: d, heroTag: tag));
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({
    required this.saved,
    required this.onTap,
    this.size = 38,
  });
  final bool saved;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: saved ? Colors.redAccent : AppColor.kInk,
          size: size * 0.52,
        ),
      ),
    );
  }
}

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

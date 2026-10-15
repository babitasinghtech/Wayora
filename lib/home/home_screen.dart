import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/appcolor.dart';
import 'package:login_learn_new_app/explore/explore_screen.dart';
import 'package:login_learn_new_app/profile/profileScreen.dart';
import 'package:login_learn_new_app/saved/saved_screen.dart';

import '../auth/auth_controller.dart';

class Destination {
  const Destination({
    required this.name,
    required this.country,
    required this.category,
    required this.rating,
    required this.price,
    required this.days,
    required this.image,
    required this.description,
  });

  final String name;
  final String country;
  final String category;
  final double rating;
  final int price;
  final int days;
  final String image;
  final String description;
}

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

const _categories = ['All', 'Beach', 'Mountain', 'City', 'Forest'];

IconData _categoryIcon(String c) {
  switch (c) {
    case 'Beach':
      return Icons.beach_access_rounded;
    case 'Mountain':
      return Icons.terrain_rounded;
    case 'City':
      return Icons.location_city_rounded;
    case 'Forest':
      return Icons.park_rounded;
    default:
      return Icons.apps_rounded;
  }
}

String _money(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

// ============================================================
// CONTROLLER (GetX)
// ============================================================
class HomeController extends GetxController {
  int tab = 0;
  String category = 'All';
  String query = '';
  final Set<String> saved = {};

  void setTab(int i) {
    tab = i;
    update();
  }

  void setCategory(String c) {
    category = c;
    update();
  }

  void setQuery(String q) {
    query = q.trim().toLowerCase();
    update();
  }

  bool isSaved(Destination d) => saved.contains(d.name);

  void toggleSave(Destination d) {
    if (!saved.remove(d.name)) saved.add(d.name);
    update();
  }

  List<Destination> get filtered => _destinations.where((d) {
    final okCat = category == 'All' || d.category == category;
    final okQuery =
        query.isEmpty ||
        d.name.toLowerCase().contains(query) ||
        d.country.toLowerCase().contains(query);
    return okCat && okQuery;
  }).toList();

  List<Destination> get popular {
    final list = [..._destinations]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(4).toList();
  }

  List<Destination> get savedList =>
      _destinations.where((d) => saved.contains(d.name)).toList();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController h = Get.put(HomeController());
  final AuthController auth = Get.find<AuthController>();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    Get.delete<HomeController>();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
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

  void _open(Destination d, String tag) {
    Get.to(() => DestinationDetail(destination: d, heroTag: tag));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (h) {
        return Scaffold(
          body: IndexedStack(
            index: h.tab,
            children: [_homeTab(h), exploreTab(h), savedTab(h), profileTab(h)],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: h.tab,
            onDestinationSelected: h.setTab,
            backgroundColor: Colors.white,
            indicatorColor: AppColor.kPrimary.withValues(alpha: 0.15),
            height: 68,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppColor.kPrimary,
                ),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(
                  Icons.explore_rounded,
                  color: AppColor.kPrimary,
                ),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: h.saved.isNotEmpty,
                  label: Text('${h.saved.length}'),
                  child: const Icon(Icons.favorite_border_rounded),
                ),
                selectedIcon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColor.kPrimary,
                ),
                label: 'Saved',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppColor.kPrimary,
                ),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _homeTab(HomeController h) {
    final featured = h.filtered;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: GetBuilder<AuthController>(
              builder: (a) => Row(
                children: [
                  _Avatar(initials: a.initials, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          a.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColor.kInk,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _soon('Notifications'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: _softShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColor.kInk,
                          ),
                          Positioned(
                            top: 12,
                            right: 13,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColor.kAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => _soon('Chat'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: _softShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.chat, color: AppColor.kInk),
                          Positioned(
                            top: 12,
                            right: 13,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColor.kAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Where do you\nwant to go?',
              style: TextStyle(
                color: AppColor.kInk,
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _softShadow,
              ),
              child: TextField(
                controller: _search,
                onChanged: h.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search destinations or countries',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.black45,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // categories
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final selected = h.category == c;
                return GestureDetector(
                  onTap: () => h.setCategory(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColor.kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColor.kPrimary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : _softShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcon(c),
                          size: 18,
                          color: selected ? Colors.white : AppColor.kPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColor.kInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // featured
          _sectionTitle('Featured destinations', onSeeAll: () => h.setTab(1)),
          if (featured.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No destinations found',
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: featured.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, i) => _featuredCard(h, featured[i]),
              ),
            ),

          // promo banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _NetImg(_img('1507525428034-b723cf961d3e')),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColor.kDark.withValues(alpha: 0.92),
                            AppColor.kDark.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Summer escape sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Up to 30% off beach holidays',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _soon('Offer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.kAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Claim offer'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // popular
          _sectionTitle('Top rated this month'),
          ...h.popular.map(
            (d) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _listTile(h, d, 'pop'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(HomeController h, Destination d) {
    final tag = 'feat-${d.name}';
    return GestureDetector(
      onTap: () => _open(d, tag),
      child: SizedBox(
        width: 235,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(tag: tag, child: _NetImg(d.image)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: _glassChip(
                  Icons.star_rounded,
                  d.rating.toString(),
                  iconColor: const Color(0xFFFFC857),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _HeartButton(
                  saved: h.isSaved(d),
                  onTap: () => h.toggleSave(d),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            d.country,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          _money(d.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
      ),
    );
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

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColor.kInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassChip(
    IconData icon,
    String text, {
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DestinationDetail extends StatelessWidget {
  const DestinationDetail({
    super.key,
    required this.destination,
    required this.heroTag,
  });

  final Destination destination;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final size = MediaQuery.of(context).size;
    final h = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.56,
            child: Hero(tag: heroTag, child: _NetImg(d.image)),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIcon(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: Get.back,
                ),
                GetBuilder<HomeController>(
                  builder: (_) => _HeartButton(
                    saved: h.isSaved(d),
                    onTap: () => h.toggleSave(d),
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: size.height * 0.48,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: const TextStyle(
                                    color: AppColor.kInk,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB400),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                d.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: AppColor.kPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d.country,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _fact(Icons.schedule_rounded, '${d.days} days'),
                              const SizedBox(width: 10),
                              _fact(_categoryIcon(d.category), d.category),
                              const SizedBox(width: 10),
                              _fact(Icons.flight_takeoff_rounded, 'Flights'),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'About',
                            style: TextStyle(
                              color: AppColor.kInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.description,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      MediaQuery.of(context).padding.bottom + 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _money(d.price),
                              style: const TextStyle(
                                color: AppColor.kInk,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Get.snackbar(
                                'Booking request sent',
                                'We will confirm your trip to ${d.name} shortly.',
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                                borderRadius: 14,
                                backgroundColor: AppColor.kPrimary,
                                colorText: Colors.white,
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Book now',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(IconData icon, String text) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.kPrimary),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColor.kInk, size: 20),
      ),
    );
  }
}

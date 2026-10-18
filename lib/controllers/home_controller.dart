import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:login_learn_new_app/models/connected_user.dart';
import 'package:login_learn_new_app/views/home/home_screen.dart';

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

class HomeController extends GetxController {
  int tab = 0;
  int exploreView = 0;
  String category = 'All';
  String query = '';

  final Set<String> saved = {};

  // Connected users must be inside HomeController
  List<ConnectedUser> connectedUsers = [];

  void setConnectedUsers(List<ConnectedUser> users) {
    connectedUsers = users;
    update();
  }

  void setTab(int i) {
    tab = i;
    update();
  }

  void setExploreView(int v) {
    exploreView = v;
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
    if (!saved.remove(d.name)) {
      saved.add(d.name);
    }
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

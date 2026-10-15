import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/restaurant_favorites_repository.dart';

class RestaurantFavoritesPage extends StatefulWidget {
  final bool selectForToday;

  const RestaurantFavoritesPage({super.key, this.selectForToday = false});

  @override
  State<RestaurantFavoritesPage> createState() => _RestaurantFavoritesPageState();
}

class _RestaurantFavoritesPageState extends State<RestaurantFavoritesPage> {
  final _repository = RestaurantFavoritesRepository();
  List<Map<String, dynamic>> _favorites = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favorites = await _repository.all();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _remove(Map<String, dynamic> restaurant) async {
    await _repository.remove(restaurant);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      appBar: TogetherAppBar(
        title: Text(widget.selectForToday ? 'Meine Restaurantfavoriten' : 'Restaurant'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Restaurantfavoriten konnten nicht geladen werden.'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Erneut versuchen')),
                      ],
                    ),
                  ),
                )
              : _favorites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppDesign.softSurface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppDesign.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_border_rounded, size: 48, color: AppDesign.primaryDark),
                              const SizedBox(height: 12),
                              Text(
                                'Noch keine Restaurantfavoriten',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Importiere ein Restaurant mit ChatGPT und speichere es beim Abschließen als Favorit.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppDesign.text,
                                      height: 1.4,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final restaurant = _favorites[index];
                          final name = restaurant['name'].toString();
                          final cuisine = restaurant['cuisine']?.toString().trim() ?? '';
                          final address = restaurant['address']?.toString().trim() ?? '';
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.restaurant_rounded)),
                              title: Text(name),
                              subtitle: Text([
                                if (cuisine.isNotEmpty) cuisine,
                                if (address.isNotEmpty) address,
                              ].join(' · ')),
                              isThreeLine: address.isNotEmpty && cuisine.isNotEmpty,
                              trailing: widget.selectForToday
                                  ? const Icon(Icons.chevron_right_rounded)
                                  : IconButton(
                                      tooltip: 'Favorit entfernen',
                                      icon: const Icon(Icons.favorite, color: AppDesign.primaryDark),
                                      onPressed: () => _remove(restaurant),
                                    ),
                              onTap: widget.selectForToday
                                  ? () => Navigator.pop(context, restaurant)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

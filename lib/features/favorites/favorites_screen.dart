import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../shops/shop_details_screen.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesController()..initialize(),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatefulWidget {
  const _FavoritesView();

  @override
  State<_FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<_FavoritesView> {
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name' or 'city'

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesController>(
      builder: (context, controller, _) {
        // Filter and sort favorites locally based on enhanced user input
        var displayedFavorites = controller.favorites.where((shop) {
          if (_searchQuery.trim().isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return shop.shopName.toLowerCase().contains(query) ||
              shop.city.toLowerCase().contains(query);
        }).toList();

        displayedFavorites.sort((a, b) {
          if (_sortBy == 'city') {
            return a.city.compareTo(b.city);
          }
          return a.shopName.compareTo(b.shopName);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '🌸 My Favorite Salons',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Refresh Favorites',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: controller.isLoading ? null : controller.loadFavorites,
              ),
            ],
          ),
          body: Column(
            children: [
              // Advanced Interactive Search & Sort Bar Header
              if (controller.favorites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search saved salons...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Sort Options',
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.sort_rounded, size: 20),
                        ),
                        onSelected: (value) => setState(() => _sortBy = value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? Colors.pinkAccent : null),
                                const SizedBox(width: 8),
                                Text('Sort by Name', style: TextStyle(fontWeight: _sortBy == 'name' ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'city',
                            child: Row(
                              children: [
                                Icon(Icons.location_city, size: 18, color: _sortBy == 'city' ? Colors.pinkAccent : null),
                                const SizedBox(width: 8),
                                Text('Sort by City', style: TextStyle(fontWeight: _sortBy == 'city' ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _Body(
                  controller: controller,
                  displayedFavorites: displayedFavorites,
                  searchQuery: _searchQuery,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.displayedFavorites,
    required this.searchQuery,
  });

  final FavoritesController controller;
  final List<ShopModel> displayedFavorites;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.favorites.isEmpty) {
      return const LoadingWidget(message: 'Loading your favorite salons...');
    }

    if (controller.errorMessage != null && controller.favorites.isEmpty) {
      return _ErrorState(
        message: controller.errorMessage!,
        onRetry: controller.loadFavorites,
      );
    }

    if (controller.favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadFavorites,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favorite salons yet',
              message: 'Tap the heart icon on any salon to save it here for quick access! ✨',
            ),
          ],
        ),
      );
    }

    if (displayedFavorites.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No matches found for "$searchQuery"',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text('Try searching with a different keyword or city name.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadFavorites,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: displayedFavorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final shop = displayedFavorites[index];
          return _FavoriteCard(
            shop: shop,
            busy: controller.isActionLoading,
            onRemove: () async {
              // Confirmation Dialog before removal event handling
              final shouldRemove = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Remove from favorites?'),
                  content: Text('Are you sure you want to remove ${shop.shopName} from your saved list?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.pinkAccent),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (shouldRemove != true) return;
              if (!context.mounted) return;

              final ok = await controller.toggleFavorite(shop.id);
              if (!context.mounted) return;
              
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(controller.errorMessage ?? 'Unable to update favorite status.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${shop.shopName} from favorites.'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => controller.toggleFavorite(shop.id),
                    ),
                  ),
                );
              }
            },
            onOpen: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopDetailsScreen(shop: shop)),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.shop,
    required this.busy,
    required this.onRemove,
    required this.onOpen,
  });

  final ShopModel shop;
  final bool busy;
  final Future<void> Function() onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hasImage = shop.imageUrl != null && shop.imageUrl!.trim().isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: hasImage
                        ? Image.network(
                            shop.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.storefront_outlined, size: 32),
                            ),
                          )
                        : ColoredBox(
                            color: primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.storefront_outlined, size: 32),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.shopName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Colors.pinkAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.city.trim().isEmpty ? 'Location not set' : shop.city,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⭐ Verified Salon',
                          style: TextStyle(fontSize: 10, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove from favorites',
                  onPressed: busy ? null : onRemove,
                  icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.pinkAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load favorites',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
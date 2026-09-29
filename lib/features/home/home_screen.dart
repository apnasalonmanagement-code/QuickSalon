import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../features/shops/shop_details_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/shop_card.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<HomeController>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _HomeHeader(
                        name: controller.profile?.name,
                        selectedCity: controller.selectedCity,
                        selectedAudience: controller.selectedAudience,
                        onAudienceSelected: controller.selectAudience,
                        cities: HomeController.availableCities,
                        onCitySelected: controller.selectCity,
                        onSearch: controller.search,
                      ),
                    ),
                  ),
                  if (controller.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadingWidget(message: 'Finding nearby salons...'),
                    )
                  else if (controller.errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        message: controller.errorMessage!,
                        onRetry: controller.load,
                      ),
                    )
                  else if (controller.shops.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No ${controller.selectedAudience == 'male' ? 'salons' : 'parlours'} found',
                        message: 'Try switching your city or category to discover more places.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: controller.shops.length,
                        itemBuilder: (context, index) {
                          final shop = controller.shops[index];
                          return ShopCard(
                            shop: shop,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailsScreen(shop: shop),
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.selectedCity,
    required this.selectedAudience,
    required this.cities,
    required this.onCitySelected,
    required this.onAudienceSelected,
    required this.onSearch,
  });

  final String? name;
  final String selectedCity;
  final String selectedAudience;
  final List<String> cities;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String> onAudienceSelected;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.trim().isEmpty)
        ? 'there'
        : name!.trim();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $displayName 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find your next look nearby ✨',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ActionChip(
                elevation: 1,
                avatar: Icon(Icons.location_on, size: 16, color: primaryColor),
                label: Text(selectedCity, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showCityPicker(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search salon or parlour in $selectedCity...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: AppTheme.isSalonTheme,
          builder: (context, isSalon, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.face, size: 20),
                    label: const Text('Salon', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: isSalon,
                    onSelected: (selected) {
                      if (selected) {
                        AppTheme.isSalonTheme.value = true;
                        onAudienceSelected('male');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.spa, size: 20),
                    label: const Text('Parlor', style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: !isSalon,
                    onSelected: (selected) {
                      if (selected) {
                        AppTheme.isSalonTheme.value = false;
                        onAudienceSelected('female');
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured in $selectedCity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            TextButton(
              onPressed: () => _showCityPicker(context),
              child: const Text('Change City 🏙️'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCityPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your City',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                const Text('Select a location to update available venues.'),
                const SizedBox(height: 16),
                ...cities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: city == selectedCity ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : null,
                      leading: Icon(
                        city == selectedCity
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: city == selectedCity ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      title: Text(city, style: TextStyle(fontWeight: city == selectedCity ? FontWeight.bold : FontWeight.normal)),
                      onTap: () => Navigator.of(sheetContext).pop(city),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) onCitySelected(selected);
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.pinkAccent),
            const SizedBox(height: 12),
            Text(
              'Unable to load salons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
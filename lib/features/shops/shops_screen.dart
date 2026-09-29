import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/shop_card.dart';
import 'shop_details_screen.dart';
import 'shops_controller.dart';

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopsController()..loadActiveShops(),
      child: const _ShopsView(),
    );
  }
}

class _ShopsView extends StatelessWidget {
  const _ShopsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Salon')),
      body: SafeArea(
        top: false,
        child: Consumer<ShopsController>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: controller.loadActiveShops,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _Filters(controller: controller),
                    ),
                  ),
                  if (controller.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadingWidget(message: 'Loading active salons...'),
                    )
                  else if (controller.errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        message: controller.errorMessage!,
                        onRetry: controller.loadActiveShops,
                      ),
                    )
                  else if (controller.shops.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No salons found',
                        message: 'Try changing your search or city filter.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: controller.shops.length,
                        itemBuilder: (context, index) {
                          final shop = controller.shops[index];
                          return ShopCard(
                            shop: shop,
                            showHours: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailsScreen(shop: shop),
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
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

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final ShopsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search by salon name or city',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (controller.cities.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Filter by city',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: controller.selectedCity == null,
                  onSelected: (_) => controller.selectCity(null),
                ),
                const SizedBox(width: 8),
                ...controller.cities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(city),
                      selected: controller.selectedCity == city,
                      onSelected: (selected) =>
                          controller.selectCity(selected ? city : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'Active salons',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 12),
            Text(
              'Unable to load salons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

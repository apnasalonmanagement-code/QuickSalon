import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_model.dart';
import '../../models/shop_model.dart';
import '../../models/staff_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../booking/booking_flow_screen.dart';
import 'shop_details_controller.dart';

class ShopDetailsScreen extends StatelessWidget {
  const ShopDetailsScreen({super.key, required this.shop});

  final ShopModel shop;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopDetailsController()..load(shop.id),
      child: _ShopDetailsView(shop: shop),
    );
  }
}

class _ShopDetailsView extends StatelessWidget {
  const _ShopDetailsView({required this.shop});

  final ShopModel shop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.shopName),
        actions: [
          Consumer<ShopDetailsController>(
            builder: (context, controller, _) => IconButton(
              tooltip: controller.isFavorite ? 'Remove favorite' : 'Add to favorites',
              onPressed: controller.isFavoriteActionLoading
                  ? null
                  : () async {
                      final ok = await controller.toggleFavorite(shop.id);
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.favoriteErrorMessage ??
                                'Unable to update favorite.',
                          ),
                        ),
                      );
                    },
              icon: controller.isFavoriteActionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      controller.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
            ),
          ),
        ],
      ),
      body: Consumer<ShopDetailsController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Loading shop details...');
          }

          if (controller.errorMessage != null) {
            return _ErrorState(
              message: controller.errorMessage!,
              onRetry: () => controller.load(shop.id),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 760
                  ? 720.0
                  : double.infinity;

              return SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ShopHero(shop: shop),
                                const SizedBox(height: 20),
                                _ShopInformation(shop: shop),
                                const SizedBox(height: 24),
                                if (shop.description != null &&
                                    shop.description!.trim().isNotEmpty) ...[
                                  _AboutSection(description: shop.description!.trim()),
                                  const SizedBox(height: 28),
                                ],
                                // Requested order: About -> Barbers -> Menu Card -> Menu.
                                _StaffSection(staff: controller.staff),
                                const SizedBox(height: 28),
                                const _MenuCardHeader(),
                                const SizedBox(height: 12),
                                _ServicesSection(
                                  groupedServices: controller.servicesByCategory,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingFlowScreen(initialShop: shop),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('BOOK NOW'),
          ),
        ),
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop});

  final ShopModel shop;

  @override
  Widget build(BuildContext context) {
    final hasImage = shop.imageUrl != null && shop.imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasImage
            ? Image.network(
                shop.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.content_cut,
        size: 72,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ShopInformation extends StatelessWidget {
  const _ShopInformation({required this.shop});

  final ShopModel shop;

  @override
  Widget build(BuildContext context) {
    final phone = shop.phone?.trim();
    final location = shop.locationUrl?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                shop.shopName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: Icon(
                shop.status ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 17,
              ),
              label: Text(shop.status ? 'Active' : 'Inactive'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.location_on_outlined, text: shop.city),
        if (shop.rating > 0) ...[
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.star_outline,
            text: 'Rating: ${shop.rating.toStringAsFixed(1)} / 5',
          ),
        ],
        if (shop.openingTime != null || shop.closingTime != null) ...[
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.access_time,
            text: '${_formatTime(shop.openingTime)} - ${_formatTime(shop.closingTime)}',
          ),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _callShop(context, phone),
              icon: const Icon(Icons.call_outlined),
              label: const Text('CALL NOW'),
            ),
          ),
        ],
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openLocation(context, location),
              icon: const Icon(Icons.map_outlined),
              label: const Text('FIND LOCATION'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _callShop(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the phone dialer.')),
    );
  }

  Future<void> _openLocation(BuildContext context, String locationUrl) async {
    final uri = Uri.tryParse(locationUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This shop has an invalid map location.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open Google Maps.')),
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '--';
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $suffix';
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(description),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _MenuCardHeader extends StatelessWidget {
  const _MenuCardHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'MENU CARD',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              'Services & Prices',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.groupedServices});

  final Map<String, List<ServiceModel>> groupedServices;

  @override
  Widget build(BuildContext context) {
    if (groupedServices.isEmpty) {
      return const _SectionEmpty(
        icon: Icons.content_cut_outlined,
        title: 'No active services',
        message: 'This salon has not added any active services yet.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedServices.entries.expand((entry) {
        return [
          Text(
            entry.key,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...entry.value.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceCard(service: service),
            ),
          ),
          const SizedBox(height: 10),
        ];
      }).toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text('${service.durationMinutes} min'),
                  const SizedBox(height: 10),
                  Chip(
                    avatar: Icon(
                      service.request
                          ? Icons.pending_actions_outlined
                          : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      service.request
                          ? 'Request approval required'
                          : 'Instant confirmation eligible',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '₹${service.price.toStringAsFixed(service.price.truncateToDouble() == service.price ? 0 : 2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffSection extends StatelessWidget {
  const _StaffSection({required this.staff});

  final List<StaffModel> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return const _SectionEmpty(
        icon: Icons.people_outline,
        title: 'No active staff',
        message: 'This salon has not added active staff yet.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barbers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _StaffCard(staff: staff[index]),
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff});

  final StaffModel staff;

  @override
  Widget build(BuildContext context) {
    final hasImage = staff.imageUrl != null && staff.imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 72,
              child: hasImage
                  ? Image.network(
                      staff.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(context),
                    )
                  : _fallback(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            staff.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (staff.role != null && staff.role!.trim().isNotEmpty)
            Text(
              staff.role!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              'Unable to load shop',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/shop_card.dart';
import '../shops/shops_controller.dart';
import 'booking_controller.dart';
import 'date/booking_date_screen.dart';
import 'review/booking_review_screen.dart';
import 'services/booking_services_screen.dart';
import 'staff/booking_staff_screen.dart';
import 'time/booking_time_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    this.initialShop,
    this.onBookingCompleted,
  });

  final ShopModel? initialShop;
  final VoidCallback? onBookingCompleted;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late final BookingController _controller;
  late int _step;

  @override
  void initState() {
    super.initState();
    _controller = BookingController(initialShop: widget.initialShop);
    _step = widget.initialShop == null ? 0 : 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final controller = _controller;
    if (_step == 0 && controller.selectedShop == null) {
      _showMessage('Please select a salon first.');
      return;
    }
    if (_step == 1 && controller.selectedDate == null) {
      _showMessage('Please select a booking date.');
      return;
    }
    if (_step == 2 && controller.selectedServices.isEmpty) {
      _showMessage('Please select at least one service.');
      return;
    }
    if (_step == 3 && controller.selectedStaff == null) {
      _showMessage('Please select a staff member.');
      return;
    }

    if (_step < 4) {
      setState(() => _step++);
      return;
    }

    if (controller.selectedTime == null) {
      _showMessage('Please select an available time.');
      return;
    }

    setState(() => _step = 5);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBookingSuccess() {
    _controller.reset();
    final callback = widget.onBookingCompleted;
    if (callback != null) {
      callback();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<BookingController>(
        builder: (context, controller, _) {
          final compact = MediaQuery.sizeOf(context).width < 520;
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: Navigator.of(context).canPop(),
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              title: const Text('🌸 Book an Appointment 🌸', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 12 : 20,
                          12,
                          compact ? 12 : 20,
                          8,
                        ),
                        child: _BookingProgress(step: _step),
                      ),
                      Expanded(child: _buildStep()),
                      _BookingSummary(
                        controller: controller,
                        compact: compact,
                      ),
                      if (_step <= 3)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 12 : 20,
                            8,
                            compact ? 12 : 20,
                            16,
                          ),
                          child: Row(
                            children: [
                              if (_step > 0)
                                Expanded(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: OutlinedButton(
                                      onPressed: _back,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: primaryColor),
                                      ),
                                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              if (_step > 0) const SizedBox(width: 12),
                              Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: FilledButton(
                                    onPressed: _next,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Continue 🌸', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_step >= 4)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 12 : 20,
                            8,
                            compact ? 12 : 20,
                            16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: OutlinedButton(
                                onPressed: _back,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: primaryColor),
                                ),
                                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return const _BookingShopSelection();
      case 1:
        return const BookingDateScreen();
      case 2:
        return const BookingServicesScreen();
      case 3:
        return const BookingStaffScreen();
      case 4:
        return BookingTimeScreen(
          onTimeSelected: () {
            if (_step < 5) {
              setState(() => _step++);
            }
          },
        );
      case 5:
        final shop = _controller.selectedShop;
        final date = _controller.selectedDate;
        final staff = _controller.selectedStaff;
        final time = _controller.selectedTime;
        if (shop == null || date == null || staff == null || time == null) {
          return const Center(child: Text('Booking information is incomplete.'));
        }
        return BookingReviewScreen(
          shop: shop,
          bookingDate: date,
          selectedServices: _controller.selectedServices,
          selectedStaff: staff,
          selectedTime: time,
          onBookingSuccess: _handleBookingSuccess,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Shop', 'Date', 'Services', 'Staff', 'Time', 'Review'];
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == step;
          final complete = index < step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Chip(
              backgroundColor: active
                  ? primaryColor.withOpacity(0.15)
                  : complete
                      ? Colors.green.withOpacity(0.1)
                      : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: active ? primaryColor : Colors.grey.withOpacity(0.3),
                  width: active ? 2 : 1,
                ),
              ),
              avatar: Icon(
                complete
                    ? Icons.check_circle
                    : active
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                size: 18,
                color: active ? primaryColor : (complete ? Colors.green : Colors.grey),
              ),
              label: Text(
                labels[index],
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? primaryColor : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingShopSelection extends StatelessWidget {
  const _BookingShopSelection();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopsController()..loadActiveShops(),
      child: Consumer2<ShopsController, BookingController>(
        builder: (context, shopsController, bookingController, _) {
          if (shopsController.isLoading) {
            return const LoadingWidget(message: 'Loading active salons...');
          }
          if (shopsController.errorMessage != null) {
            return _RetryState(
              message: shopsController.errorMessage!,
              onRetry: shopsController.loadActiveShops,
            );
          }
          if (shopsController.shops.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No active salons found',
              message: 'Please try again later.',
            );
          }

          return RefreshIndicator(
            onRefresh: shopsController.loadActiveShops,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: shopsController.shops.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return TextField(
                    onChanged: shopsController.search,
                    decoration: const InputDecoration(
                      hintText: 'Search salon by name or city',
                      prefixIcon: Icon(Icons.search),
                    ),
                  );
                }
                final shop = shopsController.shops[index - 1];
                final selected = bookingController.selectedShop?.id == shop.id;
                return Stack(
                  children: [
                    ShopCard(
                      shop: shop,
                      showHours: true,
                      onTap: () => bookingController.selectShop(shop),
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 38,
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.controller, required this.compact});
  final BookingController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (controller.selectedShop == null && controller.selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }
    final date = controller.selectedDate;
    final dateText = date == null
        ? 'Not selected'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.04),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          if (controller.selectedShop != null)
            Text('🌸 Salon: ${controller.selectedShop!.shopName}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('📅 Date: $dateText'),
          Text('🛍️ Services: ${controller.selectedServices.length}'),
          if (controller.selectedStaff != null)
            Text('👤 Staff: ${controller.selectedStaff!.name}'),
          Text('⏱️ Duration: ${controller.totalDurationMinutes} min'),
          Text('💰 Total: ₹${controller.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          if (controller.selectedServices.isNotEmpty)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                controller.requiresRequestApproval
                    ? 'Request approval required'
                    : 'Direct booking eligible',
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});
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
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
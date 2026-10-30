import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../time/urgent_time_screen.dart';
import 'urgent_staff_controller.dart';

class UrgentStaffScreen extends StatelessWidget {
  const UrgentStaffScreen({
    super.key,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.totalDuration,
    required this.totalPrice,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final int totalDuration;
  final double totalPrice;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UrgentStaffController(shopId: shopId),
      child: _UrgentStaffView(
        shopId: shopId,
        customerName: customerName,
        customerPhone: customerPhone,
        bookingDate: bookingDate,
        selectedServices: selectedServices,
        totalDuration: totalDuration,
        totalPrice: totalPrice,
      ),
    );
  }
}

class _UrgentStaffView extends StatelessWidget {
  const _UrgentStaffView({
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.selectedServices,
    required this.totalDuration,
    required this.totalPrice,
  });

  final String shopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final List<Map<String, dynamic>> selectedServices;
  final int totalDuration;
  final double totalPrice;

  void _continue(BuildContext context, UrgentStaffController controller) {
    final staff = controller.selectedStaff;
    if (staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Please select a staff member.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrgentTimeScreen(
          shopId: shopId,
          customerName: customerName,
          customerPhone: customerPhone,
          bookingDate: bookingDate,
          selectedServices: selectedServices,
          selectedStaff: staff,
          totalDuration: totalDuration,
          totalPrice: totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Staff', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<UrgentStaffController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: controller.loadStaff,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.staff.isEmpty) {
            return const Center(child: Text('No active staff members found for this shop.', style: TextStyle(fontWeight: FontWeight.bold)));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final staff = controller.staff[index];
                    final id = staff['id'].toString();
                    final selected = controller.selectedStaffId == id;
                    
                    return Card(
                      elevation: selected ? 2 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: selected ? primaryColor : Colors.transparent, width: 2),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: selected ? primaryColor : Colors.grey.shade200,
                          foregroundColor: selected ? Colors.white : Colors.black87,
                          child: Text(
                            (staff['name']?.toString().isNotEmpty == true)
                                ? staff['name'].toString().substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(staff['name']?.toString() ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            [
                              staff['role']?.toString() ?? '',
                              staff['phone']?.toString() ?? '',
                            ].where((v) => v.isNotEmpty).join(' • '),
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                        trailing: Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? primaryColor : Colors.grey,
                        ),
                        onTap: () => controller.selectStaff(id),
                      ),
                    );
                  },
                ),
              ),
              Material(
                elevation: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.selectedStaffId == null
                            ? null
                            : () => _continue(context, controller),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

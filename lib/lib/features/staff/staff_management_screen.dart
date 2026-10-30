import 'package:flutter/material.dart';

import 'package:quick_salon_management/features/staff/staff_controller.dart';
import 'package:quick_salon_management/features/staff/add_staff_screen.dart';
import 'package:quick_salon_management/features/staff/edit_staff_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  late final StaffController controller;

  @override
  void initState() {
    super.initState();
    controller = StaffController()..addListener(_refresh)..load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStaffScreen()),
    );
    await controller.load();
  }

  Future<void> _edit(Map<String, dynamic> staff) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditStaffScreen(initial: staff)),
    );
    await controller.load();
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final current = item['status'] == true;
    final name = item['name']?.toString() ?? 'staff member';
    final action = current ? 'deactivate' : 'activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${current ? 'Deactivate' : 'Activate'} staff?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Do you want to $action $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(current ? 'Deactivate' : 'Activate')),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await controller.setStatus(item['id'].toString(), !current);
    if (!ok && mounted) _message(controller.errorMessage ?? 'Unable to update staff status.');
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = item['name']?.toString() ?? 'this staff member';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete staff?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete $name permanently? This is allowed only when there are no appointments linked to this staff member.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await controller.delete(item['id'].toString());
    if (!ok && mounted) _message(controller.errorMessage ?? 'Unable to delete staff.');
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.isLoading ? null : controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: controller.isLoading && controller.staff.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : controller.staff.isEmpty
              ? _empty(primaryColor)
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: controller.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: controller.staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _card(controller.staff[index], primaryColor),
                  ),
                ),
    );
  }

  Widget _empty(Color primaryColor) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_outlined, size: 70, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No staff members yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage ?? 'Add your first staff member to start managing staff.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                onPressed: _add,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );

  Widget _card(Map<String, dynamic> item, Color primaryColor) {
    final active = item['status'] == true;
    final image = item['image_url']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Unnamed';
    final phone = item['phone']?.toString() ?? '';
    final role = item['role']?.toString() ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(0.12),
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              child: image.isEmpty ? Icon(Icons.person, size: 30, color: primaryColor) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  if (role.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(role, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (active ? Colors.green : Colors.red).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') _edit(item);
                if (value == 'toggle') _toggle(item);
                if (value == 'delete') _delete(item);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontWeight: FontWeight.w600))),
                PopupMenuItem(value: 'toggle', child: Text(active ? 'Deactivate' : 'Activate', style: const TextStyle(fontWeight: FontWeight.w600))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

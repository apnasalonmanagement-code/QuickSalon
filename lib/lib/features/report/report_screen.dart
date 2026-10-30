import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final AuthService _auth = AuthService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Your session has expired. Please log in again.');

      final profile = await _auth.getProfile(user.id);
      if (profile == null) throw Exception('Management profile not found.');

      final role = profile['role']?.toString();
      if (role != 'owner' && role != 'manager') {
        throw Exception('You are not authorized to view reports.');
      }

      final shopId = profile['shop_id']?.toString();
      if (shopId == null || shopId.isEmpty || shopId == 'null') {
        throw Exception('No shop is assigned to this account.');
      }

      final appointments = await _auth.client
          .from('appointments')
          .select('id, staff_id, status, total_price, booking_date, start_time, end_time')
          .eq('shop_id', shopId);

      final staff = await _auth.client
          .from('staff')
          .select('id, name, role, status')
          .eq('shop_id', shopId)
          .order('name');

      _appointments = List<Map<String, dynamic>>.from(appointments);
      _staff = List<Map<String, dynamic>>.from(staff);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _count(String status) => _appointments
      .where((a) => a['status']?.toString().toLowerCase() == status)
      .length;

  double _revenue(Iterable<Map<String, dynamic>> items) {
    return items
        .where((a) => a['status']?.toString().toLowerCase() == 'completed')
        .fold<double>(0, (sum, a) {
      final value = a['total_price'];
      return sum + (value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0);
    });
  }

  double _amountByStatus(String targetStatus) {
    return _appointments
        .where((a) => a['status']?.toString().toLowerCase() == targetStatus)
        .fold<double>(0, (sum, a) {
          final value = a['total_price'];
          return sum + (value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0);
        });
  }

  Color _getStatusColor(String key, Color primaryColor) {
    switch (key.toLowerCase()) {
      case 'completed':
        return Colors.green.shade600;
      case 'confirmed':
        return primaryColor;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
      case 'rejected':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: primaryColor),
                          onPressed: _load,
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_outlined, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Overall Shop Dashboard',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _MetricCard(
                            label: 'Total Bookings',
                            value: '${_appointments.length}',
                            icon: Icons.calendar_month,
                            color: primaryColor,
                          ),
                          _MetricCard(
                            label: 'Completed',
                            value: '${_count('completed')}',
                            icon: Icons.check_circle_outline,
                            color: Colors.green.shade600,
                          ),
                          _MetricCard(
                            label: 'Pending',
                            value: '${_count('pending')}',
                            icon: Icons.pending_actions,
                            color: Colors.orange.shade700,
                          ),
                          _MetricCard(
                            label: 'Cancelled / Rejected',
                            value: '${_count('cancelled') + _count('rejected')}',
                            icon: Icons.cancel_outlined,
                            color: Colors.red.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.currency_rupee, color: Colors.amber.shade800),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Completed Revenue', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
                                    SizedBox(height: 2),
                                    Text('Earnings from settled services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${_revenue(_appointments).toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Cancelled Amount',
                              value: '₹${_amountByStatus('cancelled').toStringAsFixed(0)}',
                              icon: Icons.event_busy_outlined,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: 'Rejected Amount',
                              value: '₹${_amountByStatus('rejected').toStringAsFixed(0)}',
                              icon: Icons.block_outlined,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ChartCard(
                        title: 'Appointments Breakdown by Status',
                        values: {
                          'Completed': _count('completed').toDouble(),
                          'Confirmed': _count('confirmed').toDouble(),
                          'Pending': _count('pending').toDouble(),
                          'Cancelled': _count('cancelled').toDouble(),
                          'Rejected': _count('rejected').toDouble(),
                        },
                        getStatusColor: (key) => _getStatusColor(key, primaryColor),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Icon(Icons.groups_outlined, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Employee-wise Performance',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_staff.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No staff members found.', style: TextStyle(fontWeight: FontWeight.w600))),
                          ),
                        )
                      else
                        ..._staff.map((staff) {
                          final id = staff['id']?.toString();
                          final items = _appointments.where((a) => a['staff_id']?.toString() == id).toList();
                          final completed = items.where((a) => a['status']?.toString().toLowerCase() == 'completed').length;
                          final confirmed = items.where((a) => a['status']?.toString().toLowerCase() == 'confirmed').length;
                          final pending = items.where((a) => a['status']?.toString().toLowerCase() == 'pending').length;
                          final staffRevenue = _revenue(items);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: primaryColor.withOpacity(0.15),
                                          child: Text(
                                            (staff['name']?.toString().trim().isNotEmpty == true)
                                                ? staff['name'].toString().trim()[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                staff['name']?.toString() ?? 'Staff',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                staff['role']?.toString().toUpperCase() ?? 'STAFF MEMBER',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '₹${staffRevenue.toStringAsFixed(0)}',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _ChartCard(
                                      title: 'Status Distribution',
                                      values: {
                                        'Completed': completed.toDouble(),
                                        'Confirmed': confirmed.toDouble(),
                                        'Pending': pending.toDouble(),
                                        'Cancelled': items.where((a) => a['status']?.toString().toLowerCase() == 'cancelled').length.toDouble(),
                                        'Rejected': items.where((a) => a['status']?.toString().toLowerCase() == 'rejected').length.toDouble(),
                                      },
                                      getStatusColor: (key) => _getStatusColor(key, primaryColor),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _miniStat('Total', '${items.length}', Colors.black87),
                                          _miniStat('Completed', '$completed', Colors.green.shade700),
                                          _miniStat('Pending', '$pending', Colors.orange.shade800),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.values, required this.getStatusColor});
  final String title;
  final Map<String, double> values;
  final Color Function(String) getStatusColor;

  @override
  Widget build(BuildContext context) {
    final max = values.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 12),
          ...values.entries.map((entry) {
            final ratio = max <= 0 ? 0.0 : entry.value / max;
            final barColor = getStatusColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 24,
                    child: Text(
                      entry.value.toInt().toString(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

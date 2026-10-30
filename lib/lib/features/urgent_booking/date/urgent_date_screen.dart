import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/urgent_services_screen.dart';
import 'urgent_date_controller.dart';

class UrgentDateScreen extends StatelessWidget {
  const UrgentDateScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => UrgentDateController()..initialize(), child: const _UrgentDateView());
}

class _UrgentDateView extends StatefulWidget { const _UrgentDateView(); @override State<_UrgentDateView> createState()=>_UrgentDateViewState(); }
class _UrgentDateViewState extends State<_UrgentDateView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override void initState(){ super.initState(); _nameController=TextEditingController(); _phoneController=TextEditingController(); }
  @override void dispose(){ _nameController.dispose(); _phoneController.dispose(); super.dispose(); }

  Future<void> _pickDate(BuildContext context, UrgentDateController c) async {
    final now=DateTime.now();
    final selected=await showDatePicker(
      context: context,
      initialDate: c.selectedDate.isBefore(DateTime(now.year, now.month, now.day)) ? DateTime(now.year, now.month, now.day) : c.selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if(selected!=null) c.selectDate(selected);
  }

  void _continue(BuildContext context, UrgentDateController c){
    final name=_nameController.text.trim(); 
    final phone=_phoneController.text.trim();
    c.setCustomerName(name); 
    c.setCustomerPhone(phone);
    if(name.isEmpty || c.shopId==null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Customer name is required.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder:(_)=>UrgentServicesScreen(shopId:c.shopId!, customerName:name, customerPhone:phone, bookingDate:c.selectedDate)));
  }

  @override Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Urgent Booking', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<UrgentDateController>(builder: (context, c, _) {
        if(c.isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));
        if(c.errorMessage!=null) return _ErrorView(message: c.errorMessage!, onRetry: c.initialize);
        
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StepHeader(step: 1, title: 'Customer & Date', subtitle: 'Enter walk-in customer details and select the booking date.'),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                onChanged: c.setCustomerName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Customer Name *',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                onChanged: c.setCustomerPhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              _DateOption(label: 'Today', selected: c.isToday(c.selectedDate), onTap: () => c.selectDate(DateTime.now()), primaryColor: primaryColor),
              const SizedBox(height: 12),
              _DateOption(label: 'Tomorrow', selected: c.isTomorrow(c.selectedDate), onTap: () => c.selectDate(DateTime.now().add(const Duration(days: 1))), primaryColor: primaryColor),
              const SizedBox(height: 12),
              _DateOption(label: 'Day After Tomorrow', selected: c.isDayAfterTomorrow(c.selectedDate), onTap: () => c.selectDate(DateTime.now().add(const Duration(days: 2))), primaryColor: primaryColor),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _pickDate(context, c),
                icon: Icon(Icons.calendar_month_outlined, color: primaryColor),
                label: Text(c.dateLabel(c.selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: c.shopId == null ? null : () => _continue(context, c),
                child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepHeader extends StatelessWidget{
  const _StepHeader({required this.step, required this.title, required this.subtitle});
  final int step;
  final String title, subtitle;

  @override Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          child: Text('$step', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateOption extends StatelessWidget{
  const _DateOption({required this.label, required this.selected, required this.onTap, required this.primaryColor});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? primaryColor.withOpacity(0.08) : Colors.transparent,
        border: Border.all(color: selected ? primaryColor : Colors.grey.shade300, width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? primaryColor : Colors.black87)),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget{
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    ),
  );
}
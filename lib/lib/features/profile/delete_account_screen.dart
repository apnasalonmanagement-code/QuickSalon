import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirm = false;
  bool _loading = false;
  String? _error;

  Future<void> _delete() async {
    if (!_confirm) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = AuthService();
      final response = await service.client.functions.invoke('delete-account');
      if (response.status < 200 || response.status >= 300) throw Exception('Unable to delete account.');
      await service.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delete Account')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Permanently delete your account?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('This signs you out and permanently removes your authentication account. This action cannot be undone. Existing bookings, shop records, invoices or other records may be subject to retention requirements and need separate handling by the service administrator.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          CheckboxListTile(value: _confirm, onChanged: (value) => setState(() => _confirm = value ?? false), title: const Text('I understand this action is permanent.'), controlAffinity: ListTileControlAffinity.leading),
          if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _loading || !_confirm ? null : _delete, style: FilledButton.styleFrom(backgroundColor: Colors.red), icon: const Icon(Icons.delete_forever), label: _loading ? const Text('Deleting...') : const Text('Delete my account')),
        ]),
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ForgotPasswordController(),
        child: const _ForgotPasswordView(),
      );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();
  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _showPassword = false;

  @override
  void dispose() { _email.dispose(); _otp.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _sendCode(ForgotPasswordController c) async {
    if (AppValidators.email(_email.text) != null) { _formKey.currentState?.validate(); return; }
    final ok = await c.sendResetEmail(_email.text);
    if (!mounted) return;
    if (ok) setState(() => _codeSent = true);
    _showMessage(ok ? (c.successMessage ?? 'Recovery code sent.') : (c.errorMessage ?? 'Unable to send code.'));
  }

  Future<void> _verifyCode(ForgotPasswordController c) async {
    if (_otp.text.trim().length < 6) { _showMessage('Enter the recovery code from your email.'); return; }
    final ok = await c.verifyOtp(_otp.text.trim());
    if (mounted) _showMessage(ok ? (c.successMessage ?? 'Code verified.') : (c.errorMessage ?? 'Invalid code.'));
    if (ok && mounted) setState(() {});
  }

  Future<void> _updatePassword(ForgotPasswordController c) async {
    final passwordError = AppValidators.password(_password.text);
    if (passwordError != null) { _showMessage(passwordError); return; }
    if (_password.text != _confirm.text) { _showMessage('Passwords do not match.'); return; }
    final ok = await c.setNewPassword(_password.text);
    if (!mounted) return;
    _showMessage(ok ? (c.successMessage ?? 'Password updated.') : (c.errorMessage ?? 'Unable to update password.'));
    if (ok) Navigator.of(context).pop();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Consumer<ForgotPasswordController>(
        builder: (context, controller, _) => Scaffold(
          appBar: AppBar(title: const Text('Forgot Password')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_reset, size: 64),
                        const SizedBox(height: 16),
                        const Text('Reset your password', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Request a recovery code, verify it, then set a new password.', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          enabled: !_codeSent,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Registered email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 12),
                        if (!_codeSent)
                          FilledButton(onPressed: controller.isLoading ? null : () => _sendCode(controller), child: controller.isLoading ? const CircularProgressIndicator() : const Text('SEND RECOVERY CODE')),
                        if (_codeSent && !controller.otpVerified) ...[
                          TextFormField(controller: _otp, keyboardType: TextInputType.number, maxLength: 8, decoration: const InputDecoration(labelText: 'Email recovery code', prefixIcon: Icon(Icons.password), border: OutlineInputBorder())),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: controller.isLoading ? null : () => _verifyCode(controller), child: controller.isLoading ? const CircularProgressIndicator() : const Text('VERIFY CODE')),
                          TextButton(onPressed: controller.isLoading ? null : () => _sendCode(controller), child: const Text('Resend code')),
                        ],
                        if (controller.otpVerified) ...[
                          TextFormField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'New password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility)), border: const OutlineInputBorder()), onChanged: (_) => setState(() {})),
                          const SizedBox(height: 8),
                          const Text('Password requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
                          _requirement('At least 8 characters', _password.text.length >= 8),
                          _requirement('One uppercase letter (A–Z)', RegExp(r'[A-Z]').hasMatch(_password.text)),
                          _requirement('One lowercase letter (a–z)', RegExp(r'[a-z]').hasMatch(_password.text)),
                          _requirement('One number (0–9)', RegExp(r'[0-9]').hasMatch(_password.text)),
                          _requirement('One special character (!@# etc.)', RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text)),
                          const SizedBox(height: 12),
                          TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: controller.isLoading ? null : () => _updatePassword(controller), child: controller.isLoading ? const CircularProgressIndicator() : const Text('UPDATE PASSWORD')),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _requirement(String label, bool met) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Icon(met ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: met ? Colors.green : Colors.grey), const SizedBox(width: 8), Expanded(child: Text(label))]),
      );
}

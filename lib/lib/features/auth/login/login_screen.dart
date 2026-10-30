import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  late final LoginController _controller;

  final _formKey = GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _controller = LoginController();

    _controller.addListener(
      _controllerListener,
    );
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(
      _controllerListener,
    );

    _controller.dispose();

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success =
        await _controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            _controller.errorMessage ??
                'Login failed.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isBoy = themeNotifier.currentTheme == SalonGenderTheme.boy;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isBoy
                ? [const Color(0xFFE3F2FD), const Color(0xFFF0F8FF), Colors.white]
                : [const Color(0xFFFCE4EC), const Color(0xFFFFF0F5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Card(
                  elevation: 8,
                  shadowColor: primaryColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          // ============================================
                          // GENDER / THEME SELECTOR & FLORAL ACCENT
                          // ============================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_florist, color: Colors.pinkAccent, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Theme Style:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              // Boy Button (Blue)
                              Tooltip(
                                message: 'Boy Theme (Blue)',
                                child: InkWell(
                                  onHover: (hovering) {},
                                  onTap: () => themeNotifier.setTheme(SalonGenderTheme.boy),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isBoy ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isBoy ? Colors.blue : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(Icons.boy, color: Colors.blue, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Girl Button (Pink)
                              Tooltip(
                                message: 'Girl Theme (Pink)',
                                child: InkWell(
                                  onTap: () => themeNotifier.setTheme(SalonGenderTheme.girl),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: !isBoy ? Colors.pink.withOpacity(0.2) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !isBoy ? Colors.pink : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(Icons.girl, color: Colors.pink, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.spa, color: Colors.teal, size: 22),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Logo / Icon Badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.content_cut,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'QuickSalon Management',
                            textAlign:
                                TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: primaryColor,
                                ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Management Login',
                            textAlign:
                                TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.grey.shade600),
                          ),

                          const SizedBox(height: 32),

                          TextFormField(
                            controller:
                                _emailController,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                            textInputAction:
                                TextInputAction.next,
                            decoration:
                                InputDecoration(
                              labelText: 'Email',
                              prefixIcon:
                                  Icon(
                                Icons.email_outlined,
                                color: primaryColor,
                              ),
                              border:
                                  const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email =
                                  value?.trim() ?? '';

                              if (email.isEmpty) {
                                return 'Enter your email.';
                              }

                              if (!email.contains('@')) {
                                return 'Enter a valid email.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller:
                                _passwordController,
                            obscureText:
                                _obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_controller.isLoading) {
                                _login();
                              }
                            },
                            decoration:
                                InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  Icon(
                                Icons.lock_outline,
                                color: primaryColor,
                              ),
                              suffixIcon:
                                  IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  color: primaryColor,
                                ),
                              ),
                              border:
                                  const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Enter your password.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _controller.isLoading
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                            context,
                                            '/forgot-password',
                                          );
                                        },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed:
                                  _controller.isLoading
                                      ? null
                                      : _login,
                              child: _controller.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'New salon owner?',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed:
                                _controller.isLoading
                                    ? null
                                    : () {
                                        Navigator.pushNamed(
                                          context,
                                          '/register',
                                        );
                                      },
                            child: Text(
                              'Create Owner Account',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

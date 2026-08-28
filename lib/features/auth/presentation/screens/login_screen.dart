import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 16,
              child: IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark || isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () => ref.read(themeNotifierProvider.notifier).toggle(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.build_circle_rounded,
                              size: 38,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Field Service',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to manage your jobs and sync updates',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => isLoading ? null : _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      context.go(AppRoutes.dashboard);
    }
  }
}

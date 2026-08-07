import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../domain/usecases/sign_in_with_password.dart';
import '../providers/auth_providers.dart';

/// Login screen — email/password sign in for a returning user.
///
/// Built pixel-faithfully from the frozen Stitch Light Theme (glass panel,
/// pets logo, floating-label fields, emerald pill CTA, social options). The
/// same widget tree renders Light and Dark: every color resolves through
/// [ColorScheme]; only the emerald "Sign In" accent is a fixed brand color
/// (Pet Owner identity), read from [PortalPalette.accent] — never hardcoded.
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(signInWithPasswordProvider)(
      SignInParams(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => context.showErrorSnack(failure.message),
      (_) => context.go(RoutePaths.ownerHome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadius.brSection,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Logo(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      'Sign in to continue to PetConnect AI',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _emailController,
                            labelText: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.mail_outline,
                            size: AppTextFieldSize.large,
                            validator: _validateEmail,
                          ),
                          AppSpacing.vGapLg,
                          AppTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onSuffixIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            size: AppTextFieldSize.large,
                            validator: _validatePassword,
                            onSubmitted: (_) => _submit(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.go(RoutePaths.forgotPassword),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          AppSpacing.vGapXs,
                          _EmeraldCta(
                            child: AppButton.filled(
                              label: 'Sign In',
                              isFullWidth: true,
                              size: AppButtonSize.large,
                              isLoading: _isSubmitting,
                              borderRadius: AppRadius.brPill,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _OrDivider(label: 'or continue with'),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.outlined(
                      label: 'Continue with Face ID',
                      icon: Icons.face,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      borderRadius: AppRadius.brPill,
                      onPressed: () => context.showSnackbar(
                        'Biometric sign in is coming soon.',
                      ),
                    ),
                    AppSpacing.vGapMd,
                    AppButton.outlined(
                      label: 'Continue with Google',
                      icon: Icons.account_circle_outlined,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      borderRadius: AppRadius.brPill,
                      onPressed: () => context.showSnackbar(
                        'Google sign in is coming soon.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SignUpPrompt(onTap: () => context.go(RoutePaths.register)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recolors a descendant filled button to the Pet Owner emerald brand accent.
///
/// The frozen Login design paints the primary CTA emerald (Pet Owner identity)
/// rather than the shared purple primary. Rather than fork [AppButton], we
/// scope a [FilledButtonTheme] override here so the shared widget stays
/// canonical and the accent is sourced from [PortalPalette.accent] — never a
/// literal hex. The accent is a fixed brand color, constant across Light/Dark.
class _EmeraldCta extends StatelessWidget {
  const _EmeraldCta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final emerald = PortalPalettes.of(AppPortal.petOwner).accent;
    final baseStyle =
        Theme.of(context).filledButtonTheme.style ?? const ButtonStyle();
    return FilledButtonTheme(
      data: FilledButtonThemeData(
        style: baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return emerald.withValues(alpha: 0.5);
            }
            return emerald;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      child: child,
    );
  }
}

/// Circular brand mark: a filled `pets` glyph on the primary container.
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.pets, size: 40, color: scheme.onPrimaryContainer),
    );
  }
}

/// A centered label flanked by hairline rules.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = Expanded(
      child: Divider(color: scheme.outlineVariant, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// "Don't have an account? Create Account" footer.
class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Create Account',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

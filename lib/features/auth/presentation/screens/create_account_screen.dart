import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/create_account.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Create Account screen — new-user registration.
///
/// Pixel-faithful to the frozen Stitch Light Theme: ambient background glow,
/// a subtle back affordance, floating-label fields (name, email, optional
/// phone, password + confirm), a terms checkbox, and the primary pill CTA.
/// One theme-adaptive tree — every color resolves through [ColorScheme].
///
/// On success the account is registered with Supabase and the flow advances
/// to OTP verification, carrying the email via
/// [pendingVerificationEmailProvider].
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go(RoutePaths.roleSelection);
    }
  }

  String? _validateName(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Full name is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedTerms) setState(() => _termsError = true);
    if (!formValid || !_acceptedTerms) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final role = ref.read(selectedPortalProvider);
    final result = await ref.read(createAccountProvider)(
      CreateAccountParams(
        email: email,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: role,
        phone: _phoneController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => context.showErrorSnack(failure.message), (_) {
      ref.read(pendingVerificationEmailProvider.notifier).state = email;
      context.go(RoutePaths.otpVerification);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const _AmbientGlow(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      color: scheme.onSurfaceVariant,
                      tooltip: 'Go back',
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          children: [
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AppSpacing.vGapXs,
                            Text(
                              "Join PetConnect AI to manage your pet's life "
                              'with ease.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildForm(scheme, textTheme),
                            const SizedBox(height: AppSpacing.xl),
                            _SignInPrompt(
                              onTap: () => context.go(RoutePaths.login),
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
        ],
      ),
    );
  }

  Widget _buildForm(ColorScheme scheme, TextTheme textTheme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            labelText: 'Full Name',
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline,
            size: AppTextFieldSize.large,
            validator: _validateName,
          ),
          AppSpacing.vGapMd,
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.mail_outline,
            size: AppTextFieldSize.large,
            validator: _validateEmail,
          ),
          AppSpacing.vGapMd,
          AppTextField(
            controller: _phoneController,
            labelText: 'Phone Number (optional)',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.phone_outlined,
            size: AppTextFieldSize.large,
          ),
          AppSpacing.vGapMd,
          AppTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            suffixIcon: _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixIconTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            size: AppTextFieldSize.large,
            validator: _validatePassword,
          ),
          AppSpacing.vGapMd,
          AppTextField(
            controller: _confirmController,
            labelText: 'Confirm Password',
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            suffixIcon: _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixIconTap: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            size: AppTextFieldSize.large,
            validator: _validateConfirm,
            onSubmitted: (_) => _submit(),
          ),
          AppSpacing.vGapMd,
          _TermsCheckbox(
            value: _acceptedTerms,
            hasError: _termsError,
            onChanged: (v) => setState(() {
              _acceptedTerms = v ?? false;
              if (_acceptedTerms) _termsError = false;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.filled(
            label: 'Create Account',
            isFullWidth: true,
            size: AppButtonSize.large,
            isLoading: _isSubmitting,
            borderRadius: AppRadius.brPill,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Two soft, blurred brand-tinted orbs behind the form — the design's ambient
/// background decor. Purely decorative; colors resolve from [ColorScheme].
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -120,
              child: _Orb(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -140,
              child: _Orb(
                color: scheme.secondaryContainer.withValues(alpha: 0.2),
                size: 360,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, this.size = 300});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Terms & Conditions acceptance row. Turns its label error-colored when the
/// user tries to submit without accepting.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final bool value;
  final bool hasError;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final baseColor = hasError ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            isError: hasError,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.base),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: context.textTheme.bodySmall?.copyWith(color: baseColor),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Already have an account? Sign In →" footer.
class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign In',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Icon(Icons.arrow_forward, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

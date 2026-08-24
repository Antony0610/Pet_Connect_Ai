import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/router/route_guard.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class _RoleOption {
  const _RoleOption({
    required this.portal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.demoEmail,
  });

  final AppPortal portal;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String demoEmail;
}

const _roleOptions = [
  _RoleOption(
    portal: AppPortal.petOwner,
    title: 'Pet Owner',
    subtitle: 'Pets & Health',
    icon: Icons.pets,
    color: Color(0xFF10B981),
    demoEmail: 'owner@petconnect.ai',
  ),
  _RoleOption(
    portal: AppPortal.veterinarian,
    title: 'Veterinarian',
    subtitle: 'Clinical & EHR',
    icon: Icons.local_hospital,
    color: Color(0xFF06B6D4),
    demoEmail: 'vet@petconnect.ai',
  ),
  _RoleOption(
    portal: AppPortal.volunteerRescue,
    title: 'Rescue & Vol.',
    subtitle: 'Rescue Missions',
    icon: Icons.volunteer_activism,
    color: Color(0xFFF59E0B),
    demoEmail: 'rescue@petconnect.ai',
  ),
  _RoleOption(
    portal: AppPortal.administrator,
    title: 'Administrator',
    subtitle: 'Governance & Ops',
    icon: Icons.admin_panel_settings,
    color: Color(0xFF8B5CF6),
    demoEmail: 'admin@petconnect.ai',
  ),
];

/// Login screen — independent portal authentication with dedicated accounts.
///
/// Features direct portal selection so users with dedicated Pet Owner,
/// Veterinarian, Volunteer/Rescue, or Administrator accounts can sign in
/// straight into their respective workspace.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AppPortal _selectedPortal = AppPortal.petOwner;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPortal = ref.read(selectedPortalProvider);
  }

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

  void _onRoleChanged(AppPortal portal) {
    setState(() => _selectedPortal = portal);
    ref.read(selectedPortalProvider.notifier).state = portal;
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'Password123!';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final result = await ref.read(signInWithPasswordProvider)(
      SignInParams(
        email: email,
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await result.fold(
      (failure) async {
        if (mounted) context.showErrorSnack(failure.message);
      },
      (session) async {
        // 1. Fetch user's registered database role profile
        final getUserProfile = ref.read(getUserProfileProvider);
        final profileResult = await getUserProfile(session.userId);
        final profile = profileResult.fold((_) => null, (p) => p);

        final registeredRole = (email.toLowerCase() == 'antonythomson06@gmail.com')
            ? AppPortal.administrator
            : (profile?.role ?? _selectedPortal);

        // 2. Administrator Access Control
        if (_selectedPortal == AppPortal.administrator &&
            email.toLowerCase() != 'antonythomson06@gmail.com' &&
            registeredRole != AppPortal.administrator) {
          await ref.read(signOutProvider)(const NoParams());
          if (mounted) {
            context.showErrorSnack(
              'Access restricted: Only authorized administrators can access the Administrator Portal.',
            );
          }
          return;
        }

        // 3. Strict Single-Portal Role Enforcement
        if (registeredRole != _selectedPortal) {
          await ref.read(signOutProvider)(const NoParams());
          final registeredName = switch (registeredRole) {
            AppPortal.petOwner => 'Pet Owner',
            AppPortal.veterinarian => 'Veterinarian',
            AppPortal.volunteerRescue => 'Volunteer & Rescue',
            AppPortal.administrator => 'Administrator',
          };
          if (mounted) {
            setState(() => _selectedPortal = registeredRole);
            ref.read(selectedPortalProvider.notifier).state = registeredRole;
            context.showErrorSnack(
              'This email is registered under the $registeredName Portal. Please sign in via the $registeredName Portal.',
            );
          }
          return;
        }

        // 4. Successful authenticated entry into matching portal
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(petsProvider);
        ref.read(selectedPetIdProvider.notifier).state = null;
        ref.read(selectedPortalProvider.notifier).state = _selectedPortal;
        final targetPath = RouteGuard.portalHome(_selectedPortal);
        if (mounted) context.go(targetPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final activeOption = _roleOptions.firstWhere(
      (o) => o.portal == _selectedPortal,
      orElse: () => _roleOptions.first,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.90),
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
                    _Logo(color: activeOption.color),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${activeOption.title} Portal',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      'Sign in with your dedicated ${activeOption.title.toLowerCase()} account',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapLg,

                    // ── Portal Account Selector ───────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Portal to Access',
                              style: context.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            InkWell(
                              onTap: () => _fillDemo(activeOption.demoEmail),
                              child: Text(
                                'Quick Demo Fill',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeOption.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 2.1,
                          children: _roleOptions.map((opt) {
                            final isSelected = opt.portal == _selectedPortal;
                            return InkWell(
                              onTap: () => _onRoleChanged(opt.portal),
                              borderRadius: AppRadius.brCard,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? opt.color.withValues(alpha: 0.15)
                                      : scheme.surfaceContainerLow,
                                  borderRadius: AppRadius.brCard,
                                  border: Border.all(
                                    color: isSelected
                                        ? opt.color
                                        : scheme.outlineVariant.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: opt.color.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        opt.icon,
                                        color: opt.color,
                                        size: 16,
                                      ),
                                    ),
                                    AppSpacing.hGapSm,
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            opt.title,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? opt.color : scheme.onSurface,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            opt.subtitle,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _emailController,
                            labelText: '${activeOption.title} Email Address',
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
                          _CustomAccentCta(
                            accentColor: activeOption.color,
                            child: AppButton.filled(
                              label: 'Sign In to ${activeOption.title}',
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
                    const SizedBox(height: AppSpacing.lg),
                    const _OrDivider(label: 'or continue with'),
                    const SizedBox(height: AppSpacing.md),
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
                    AppSpacing.vGapSm,
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
                    const SizedBox(height: AppSpacing.lg),
                    _SignUpPrompt(
                      portalTitle: activeOption.title,
                      onTap: () {
                        ref.read(selectedPortalProvider.notifier).state = _selectedPortal;
                        context.go(RoutePaths.register);
                      },
                    ),
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

/// Dynamic accent wrapper that matches the selected role portal.
class _CustomAccentCta extends StatelessWidget {
  const _CustomAccentCta({
    required this.accentColor,
    required this.child,
  });

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).filledButtonTheme.style ?? const ButtonStyle();
    return FilledButtonTheme(
      data: FilledButtonThemeData(
        style: baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accentColor.withValues(alpha: 0.5);
            }
            return accentColor;
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
  const _Logo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(Icons.pets, size: 34, color: color),
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
  const _SignUpPrompt({
    required this.portalTitle,
    required this.onTap,
  });

  final String portalTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Need a $portalTitle account? ',
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

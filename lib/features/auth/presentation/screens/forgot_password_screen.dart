import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Password recovery and reset request screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      context.showErrorSnack('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(resetPasswordForEmailProvider)(email);
    if (!mounted) return;

    setState(() => _isLoading = false);

    result.fold(
      (failure) => context.showErrorSnack(failure.message),
      (_) => setState(() => _isSubmitted = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Recovery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _isSubmitted
                ? _buildSuccessView(theme, colorScheme)
                : _buildFormView(theme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSpacing.vGapLg,
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset_outlined,
            color: colorScheme.primary,
            size: 48,
          ),
        ),
        AppSpacing.vGapLg,
        Text(
          'Reset Your Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapSm,
        Text(
          'Enter your account email address below to receive password reset instructions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXl,
        AppTextField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'user@example.com',
          prefixIcon: const Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.vGapLg,
        AppButton(
          text: _isLoading ? 'Sending Request...' : 'Send Reset Link',
          icon: Icons.send_outlined,
          isFullWidth: true,
          onPressed: _isLoading ? null : _handleResetRequest,
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          height: 48,
        ),
        AppSpacing.vGapLg,
        TextButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Sign In'),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSpacing.vGapLg,
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 48,
          ),
        ),
        AppSpacing.vGapLg,
        Text(
          'Reset Link Sent!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: AppTypography.bold,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapSm,
        Text(
          'We have dispatched reset instructions to:\n${_emailController.text}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapLg,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Check your inbox and spam folder. Click the link inside to verify and enter a new password.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXl,
        AppButton(
          text: 'Return to Sign In',
          icon: Icons.login,
          isFullWidth: true,
          onPressed: () => GoRouter.of(context).pop(),
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          height: 48,
        ),
        AppSpacing.vGapMd,
        TextButton(
          onPressed: () {
            setState(() => _isSubmitted = false);
          },
          child: const Text("Didn't receive email? Try again"),
        ),
      ],
    );
  }
}

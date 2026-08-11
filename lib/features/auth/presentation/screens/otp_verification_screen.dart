import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../domain/usecases/verify_email_otp.dart';
import '../providers/auth_providers.dart';

/// Email confirmation screen shown immediately after account creation.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _codeLength = 6;
  static const int _resendDelaySeconds = 30;
  static const String _illustrationUrl =
      'https://lh3.googleusercontent.com/aida-public/'
      'AB6AXuB79BMuXy3t-94BVRsLXVLCKVL5x69bySMn-UmIxvUVV2tWvmXX8KlSA1Jkmzqn7FoQIsfOG5wkKGFFaSB_HzrfaRrwyZXqF0Q573eFACEpmMvB-F1xEy1t0TnjOkY8x2GobjtxoSYOLQk5oiWIA10d51wJKvn06dMUsuXafxmTVMtAusOmSSBYXQXoPy9kc3wZn_JFVh5wIyoLLa5Lf4DLN004_InrySy1HY0L6z63B1WB8yb4sQjf1A';

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  int _secondsRemaining = _resendDelaySeconds;
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendDelaySeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _handleChanged(int index, String value) {
    // A multi-character value means the code was pasted or autofilled into a
    // single box — spread the digits across the fields instead of truncating.
    if (value.length > 1) {
      _distribute(value, from: index);
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  /// Fills the boxes from [from] with the digits in [value], then parks focus
  /// on the next empty box (or blurs when the code is complete). Pasting a full
  /// code into the first box fills every field.
  void _distribute(String value, {required int from}) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _controllers[from].clear();
      setState(() {});
      return;
    }
    var lastFilled = from;
    for (var i = 0; from + i < _codeLength && i < digits.length; i++) {
      final target = from + i;
      _controllers[target].value = TextEditingValue(
        text: digits[i],
        selection: const TextSelection.collapsed(offset: 1),
      );
      lastFilled = target;
    }
    if (lastFilled >= _codeLength - 1) {
      _focusNodes[lastFilled].unfocus();
    } else {
      _focusNodes[lastFilled + 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (_isVerifying || _isVerified) return;
    final token = _controllers.map((controller) => controller.text).join();
    if (token.length != _codeLength) {
      context.showErrorSnack('Enter the complete verification code');
      return;
    }

    final email = ref.read(pendingVerificationEmailProvider);
    if (email == null || email.isEmpty) {
      context.showErrorSnack('Your verification email is missing');
      return;
    }

    setState(() => _isVerifying = true);
    final result = await ref.read(verifyEmailOtpProvider)(
      VerifyEmailOtpParams(email: email, token: token),
    );
    if (!mounted) return;

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() => _isVerifying = false);
      context.showErrorSnack(failure.message);
      return;
    }

    _timer?.cancel();
    setState(() {
      _isVerifying = false;
      _isVerified = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    ref.read(pendingVerificationEmailProvider.notifier).state = null;
    context.go(RoutePaths.welcomeSuccess);
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) return;
    final email = ref.read(pendingVerificationEmailProvider);
    if (email == null || email.isEmpty) {
      context.showErrorSnack('Your verification email is missing');
      return;
    }

    setState(() => _isResending = true);
    final result = await ref.read(resendEmailOtpProvider)(email);
    if (!mounted) return;
    setState(() => _isResending = false);
    result.fold((failure) => context.showErrorSnack(failure.message), (_) {
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
      _startCountdown();
      context.showSnackbar('A new code was sent to $email');
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final email = ref.watch(pendingVerificationEmailProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop()
              ? GoRouter.of(context).pop()
              : context.go(RoutePaths.register),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
        ),
        title: Text(
          'PetConnect AI',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.88),
                  borderRadius: AppRadius.brSection,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.08),
                      blurRadius: AppSpacing.xl,
                      offset: const Offset(0, AppSpacing.xs),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const _MailIllustration(url: _illustrationUrl),
                    AppSpacing.vGapLg,
                    Text(
                      'Check Your Email',
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Text.rich(
                      TextSpan(
                        text: "We've sent a 6-digit code to\n",
                        children: [
                          TextSpan(
                            text: email ?? 'your email address',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapXl,
                    _OtpFields(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      onChanged: _handleChanged,
                      onKeyEvent: _handleKey,
                    ),
                    AppSpacing.vGapLg,
                    _ResendRow(
                      secondsRemaining: _secondsRemaining,
                      isResending: _isResending,
                      onResend: _resend,
                    ),
                    AppSpacing.vGapXl,
                    AppButton.filled(
                      label: _isVerified ? 'Verified' : 'Verify Code',
                      icon: _isVerified
                          ? Icons.check_circle
                          : Icons.arrow_forward,
                      iconAlignment: IconAlignment.end,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      isLoading: _isVerifying,
                      borderRadius: AppRadius.brPill,
                      onPressed: _verify,
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

class _MailIllustration extends StatelessWidget {
  const _MailIllustration({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ClipOval(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -AppSpacing.xs,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.18),
                    blurRadius: AppSpacing.sm,
                    offset: const Offset(0, AppSpacing.base),
                  ),
                ],
              ),
              child: Icon(
                Icons.mark_email_read,
                size: 20,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpFields extends StatelessWidget {
  const _OtpFields({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final KeyEventResult Function(int index, KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      children: List.generate(controllers.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == controllers.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: SizedBox(
              height: 80,
              child: Focus(
                onKeyEvent: (_, event) => onKeyEvent(index, event),
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  autofocus: index == 0,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: index == controllers.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(controllers.length),
                  ],
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surfaceContainer,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.brLg,
                      borderSide: BorderSide(
                        width: 2,
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.brLg,
                      borderSide: BorderSide(
                        width: 2,
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.brLg,
                      borderSide: BorderSide(width: 2, color: scheme.primary),
                    ),
                  ),
                  onChanged: (value) => onChanged(index, value),
                  onSubmitted: index == controllers.length - 1
                      ? (_) => FocusScope.of(context).unfocus()
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final canResend = secondsRemaining == 0 && !isResending;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAxisAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text(
          "Didn't receive the code?",
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: canResend ? onResend : null,
          child: isResending
              ? const SizedBox.square(
                  dimension: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  canResend
                      ? 'Resend Now'
                      : 'Resend in 00:${secondsRemaining.toString().padLeft(2, '0')}',
                ),
        ),
      ],
    );
  }
}

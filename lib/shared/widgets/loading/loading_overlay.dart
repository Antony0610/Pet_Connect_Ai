import 'package:flutter/material.dart';

/// A full-screen loading overlay with a spinner and optional message.
///
/// Displayed by calling the static [show] method. Dismissed with `pop`.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({this.message, super.key});

  final String? message;

  /// Shows the overlay over the current route. Call `Navigator.pop(context)`
  /// to dismiss it.
  static void show(BuildContext context, {String? message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LoadingOverlay(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

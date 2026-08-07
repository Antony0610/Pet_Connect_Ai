import 'package:flutter/material.dart';

import '../../../core/theme/component_tokens/input_tokens.dart';

/// Size options for [AppTextField].
enum AppTextFieldSize { small, medium, large }

/// The canonical text input for PetConnect AI.
///
/// A themed text field consuming [InputDecorationTheme] from [AppTheme], with
/// optional prefix/suffix icons, a clearable state, and sizing. Colors are
/// inherited from the active [ColorScheme].
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.isClearable = false,
    this.size = AppTextFieldSize.medium,
    super.key,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool isClearable;
  final AppTextFieldSize size;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onChanged?.call(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final height = switch (widget.size) {
      AppTextFieldSize.small => InputTokens.heightSmall,
      AppTextFieldSize.medium => InputTokens.heightMedium,
      AppTextFieldSize.large => InputTokens.heightLarge,
    };

    Widget? suffixIcon;
    if (widget.isClearable && _hasText && widget.enabled && !widget.readOnly) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.clear, size: InputTokens.iconSize),
        onPressed: _clear,
      );
    } else if (widget.suffixIcon != null) {
      suffixIcon = Icon(widget.suffixIcon, size: InputTokens.iconSize);
    }

    return SizedBox(
      height: widget.maxLines == 1 ? height : null,
      child: TextFormField(
        controller: _controller,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: InputTokens.iconSize)
              : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

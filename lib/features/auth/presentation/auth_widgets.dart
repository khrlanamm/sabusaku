import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/labels.dart';

/// Email input with the hints that let Android offer and save credentials.
class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    readOnly: readOnly,
    autofocus: autofocus,
    decoration: const InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.alternate_email),
    ),
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: const [AutofillHints.email, AutofillHints.username],
    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
    validator: (value) {
      final email = normalizeEmail(value ?? '');
      if (email.isEmpty) return 'Wajib diisi';
      if (!isValidEmail(email)) return 'Format email belum benar';
      return null;
    },
  );
}

/// "Password baru" + "Ulangi password" with the new-password autofill hint,
/// so Android offers to save the pair after the form is committed.
class NewPasswordFields extends StatefulWidget {
  const NewPasswordFields({
    super.key,
    required this.password,
    required this.confirm,
    this.onSubmitted,
    this.label = 'Password baru',
  });

  final TextEditingController password;
  final TextEditingController confirm;
  final VoidCallback? onSubmitted;
  final String label;

  @override
  State<NewPasswordFields> createState() => _NewPasswordFieldsState();
}

class _NewPasswordFieldsState extends State<NewPasswordFields> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final toggle = ObscureToggle(
      obscure: _obscure,
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('password-new'),
          controller: widget.password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: 'Minimal $minPasswordLength karakter',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: toggle,
          ),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: validateNewPassword,
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('password-confirm'),
          controller: widget.confirm,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Ulangi password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: toggle,
          ),
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          validator: (value) =>
              value != widget.password.text ? 'Password tidak sama' : null,
        ),
      ],
    );
  }
}

class ObscureToggle extends StatelessWidget {
  const ObscureToggle({
    super.key,
    required this.obscure,
    required this.onPressed,
  });

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
    onPressed: onPressed,
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short explanation on a tinted card.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onPrimaryContainer),
        child: child,
      ),
    );
  }
}

class ButtonProgress extends StatelessWidget {
  const ButtonProgress({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2.5),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'atau',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

/// A plain "G" in Google's blue, without shipping the trademarked logo.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xFF4285F4),
      fontWeight: FontWeight.w800,
      fontSize: 18,
    ),
  );
}

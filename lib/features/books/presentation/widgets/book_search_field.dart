import 'package:flutter/material.dart';

/// Search box for the book catalog, with a clear button once text is typed.
class BookSearchField extends StatelessWidget {
  const BookSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Cari judul atau penulis',
    this.autofocus = false,
    this.fieldKey,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool autofocus;

  /// Key of the inner text field (tests type into it).
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: fieldKey,
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
    );
  }
}

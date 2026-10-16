import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/user_avatar.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import 'auth_widgets.dart';
import 'label_pickers.dart';
import 'photo_actions.dart';

/// "Lengkapi akun": full name, class and extracurriculars (students), and a
/// password for accounts that only sign in with Google. The router keeps the
/// user here until all of it is done.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _classId;
  late List<String> _extracurriculars;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(currentSessionProvider);
    final profile = session.profile;
    final account = ref.read(authRepositoryProvider).currentUser;
    _name = TextEditingController(
      text: profile.name.isNotEmpty
          ? profile.name
          : (account?.displayName ?? ''),
    );
    _email = TextEditingController(
      text: profile.email.isNotEmpty ? profile.email : (account?.email ?? ''),
    );
    _classId = profile.classId;
    _extracurriculars = [...profile.extracurriculars];
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = ref.read(currentSessionProvider);
    final profile = session.profile;
    final isStudent = session.role == UserRole.siswa;
    final auth = ref.read(authRepositoryProvider);
    try {
      final name = _name.text.trim();
      final sameLabels =
          _extracurriculars.length == profile.extracurriculars.length &&
          _extracurriculars.every(profile.extracurriculars.contains);
      await auth.updateProfile(
        session,
        name: name == profile.name ? null : name,
        classId: isStudent && _classId != profile.classId ? _classId : null,
        extracurriculars: isStudent && !sameLabels ? _extracurriculars : null,
      );
      if (!session.hasPassword) {
        await auth.setPassword(_password.text);
        // Offers to save the email and the new password.
        TextInput.finishAutofillContext();
      }
      // The router leaves once the session is complete.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapError(error).userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final profile = session.profile;
    final isStudent = session.role == UserRole.siswa;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi akun'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Keluar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const InfoBanner(
                        child: Text(
                          'Selamat datang di Sabu Saku! Lengkapi data akunmu '
                          'sebelum mulai.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            UserAvatar(
                              photoUrl: profile.photoUrl,
                              name: _name.text,
                              radius: 44,
                            ),
                            TextButton.icon(
                              key: const Key('complete-photo'),
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        showPhotoActions(context, ref, session),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                profile.photoUrl == null
                                    ? 'Tambah foto (opsional)'
                                    : 'Ganti foto',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('complete-name'),
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.length < 2) return 'Nama minimal 2 huruf';
                          if (name.length > 80) return 'Nama maksimal 80 huruf';
                          return null;
                        },
                      ),
                      if (isStudent) ...[
                        const SizedBox(height: 14),
                        ClassLabelField(
                          value: _classId,
                          onChanged: (value) =>
                              setState(() => _classId = value),
                        ),
                        const SizedBox(height: 18),
                        ExtracurricularChips(
                          value: _extracurriculars,
                          onChanged: (value) =>
                              setState(() => _extracurriculars = value),
                        ),
                      ],
                      if (!session.hasPassword) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Buat password',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dengan password, kamu juga bisa masuk memakai email '
                          'ini tanpa Google.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Read-only, but its hint lets Android save the pair.
                        EmailField(controller: _email, readOnly: true),
                        const SizedBox(height: 14),
                        NewPasswordFields(
                          password: _password,
                          confirm: _confirm,
                          onSubmitted: _submit,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('complete-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const ButtonProgress()
                            : const Text('Simpan dan lanjutkan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

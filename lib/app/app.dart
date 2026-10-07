import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/notifications/notification_service.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

class SabuSakuApp extends ConsumerStatefulWidget {
  const SabuSakuApp({super.key});

  @override
  ConsumerState<SabuSakuApp> createState() => _SabuSakuAppState();
}

class _SabuSakuAppState extends ConsumerState<SabuSakuApp> {
  @override
  void initState() {
    super.initState();
    final notifications = ref.read(notificationServiceProvider)..start();
    // Re-register the device token whenever a different account signs in.
    ref.listenManual(sessionProvider, (previous, next) {
      if (previous?.uid != next?.uid) notifications.onSession(next);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sabu Saku',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildAppTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

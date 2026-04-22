import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';
import 'services/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await NotificationsService.instance.init();
  final state = await AppState.load();
  // Best-effort: re-plan every in-future reminder on launch so a fresh
  // install or a device reboot doesn't silently drop pending notifications.
  // Does NOT request permission — that happens lazily on the first schedule
  // triggered by a user action.
  unawaited(state.replayScheduledNotifications());

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const OnlyMeApp(),
    ),
  );
}

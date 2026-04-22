import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final state = await AppState.load();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const OnlyMeApp(),
    ),
  );
}

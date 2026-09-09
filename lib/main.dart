import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: HiFiApp(),
    ),
  );
}

class HiFiApp extends ConsumerWidget {
  const HiFiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicColorScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicColorScheme: darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}

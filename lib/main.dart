import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/map_screen.dart';
import 'services/native_location_service.dart';
import 'theme/maps_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final navigationProvider = NavigationProvider();
  NativeLocationService.setNavigationStoppedCallback(
    () => navigationProvider.stopFromNotification(),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: navigationProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, provider, _) {
        MapsTheme.applySystemOverlay(provider.isDarkMode);
        return MaterialApp(
          title: 'Lancarkan',
          debugShowCheckedModeBanner: false,
          theme: MapsTheme.light,
          darkTheme: MapsTheme.dark,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MapScreen(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/screens/splash_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/app_theme.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: KinovaColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final api = ApiClient();

  runApp(KinovaApp(api: api));
}

class KinovaApp extends StatelessWidget {
  const KinovaApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => CatalogController(api)),
        ChangeNotifierProvider(create: (_) => AuthController(api)),
        ChangeNotifierProvider(create: (_) => CartController(api)),
        ChangeNotifierProvider(create: (_) => FavoritesController(api)),
      ],
      child: MaterialApp(
        title: 'KINOVA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}

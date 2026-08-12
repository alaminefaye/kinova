import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/screens/splash_screen.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/app_theme.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

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
  runApp(const KinovaApp());
}

class KinovaApp extends StatelessWidget {
  const KinovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/screens/main_shell.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/animated_logo_badge.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _glowPulse;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _lineWidth;

  @override
  void initState() {
    super.initState();

    // Mode sombre élégant pour la barre de statut pendant le splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF140C07),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.2, end: 0.65).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.75, curve: Curves.easeInOut),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _lineWidth = Tween<double>(begin: 0.0, end: 140.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.9, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();
    // Attendre la fin du premier build pour éviter notifyListeners pendant build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAndNavigate();
    });
  }

  Future<void> _bootstrapAndNavigate() async {
    if (!mounted) return;
    final started = DateTime.now();
    final catalog = context.read<CatalogController>();
    final auth = context.read<AuthController>();
    final favorites = context.read<FavoritesController>();

    await Future.wait([
      catalog.load(),
      auth.bootstrap(),
    ]);

    if (auth.isLoggedIn) {
      try {
        await favorites.loadFromApi();
      } catch (_) {}
    }

    final elapsed = DateTime.now().difference(started);
    // Affiche le splash au moins 3 secondes pour laisser voir l'animation
    // et s'assurer que le chargement initial est bien visible.
    const minSplash = Duration(seconds: 5);
    if (elapsed < minSplash) {
      await Future<void>.delayed(minSplash - elapsed);
    }

    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;

    // Rétablir la barre d'état claire pour l'application
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KinovaColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond dégradé sombre luxe style Haute Parfumerie (Chocolat profond & Or)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.15,
                colors: [
                  Color(0xFF2C1E14),
                  Color(0xFF1B110B),
                  Color(0xFF0F0A06),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Aura dorée pulsante derrière le logo
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(_glowPulse.value * 0.35),
                        const Color(0xFFC5A080).withOpacity(_glowPulse.value * 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Logo et Typographie animés
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo officiel KINOVA (assets/images/logo.png) sans encadrement artificiel
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Hero(
                      tag: 'brand-logo-splash',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const AnimatedLogoBadge(size: 170),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Textes de marque
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        const Text(
                          'K I N O V A',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            color: Color(0xFFF7E7CE),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 10,
                            shadows: [
                              Shadow(
                                color: Color(0x66D4AF37),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HAUTE BEAUTÉ & ART DE VIVRE',
                          style: TextStyle(
                            color: Color(0xFFC5A080),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Ligne lumineuse dorée
                AnimatedBuilder(
                  animation: _lineWidth,
                  builder: (context, child) {
                    return Container(
                      width: _lineWidth.value,
                      height: 1.2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFD4AF37),
                            Color(0xFFF7E7CE),
                            Color(0xFFD4AF37),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // Signature bas de page
                FadeTransition(
                  opacity: _textFade,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'ÉDITION PRIVILÈGE 2026',
                      style: TextStyle(
                        color: Color(0x99C5A080),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

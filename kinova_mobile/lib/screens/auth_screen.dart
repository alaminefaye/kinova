import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/animated_logo_badge.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late final AnimationController _intro;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.9, curve: Curves.easeOut),
    );
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _switchMode(bool register) {
    if (_registerMode == register || _loading) return;
    setState(() {
      _registerMode = register;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthController>();
    try {
      if (_registerMode) {
        await auth.register(
          name: _name.text,
          phone: _phone.text,
          password: _password.text,
          email: _email.text,
        );
      } else {
        // Email ou téléphone
        await auth.login(_email.text, _password.text);
      }
      if (!mounted) return;
      // Déjà connecté (token reçu) — sync favoris sans bloquer la session.
      try {
        await context.read<FavoritesController>().loadFromApi();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Connexion impossible. Vérifiez votre réseau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B110B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond luxe chocolat profond
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.3,
                colors: [
                  Color(0xFF2C1E14),
                  Color(0xFF1B110B),
                  Color(0xFF0F0A06),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Halo doré derrière le logo
          FadeTransition(
            opacity: _headerFade,
            child: Align(
              alignment: const Alignment(0, -0.78),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.28),
                      const Color(0xFFC5A080).withOpacity(0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Bouton retour discret
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: KinovaColors.sand,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // En-tête marque
                FadeTransition(
                  opacity: _headerFade,
                  child: Column(
                    children: const [
                      AnimatedLogoBadge(size: 84),
                      SizedBox(height: 16),
                      Text(
                        'K I N O V A',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Color(0xFFF7E7CE),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(color: Color(0x66D4AF37), blurRadius: 14),
                          ],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ESPACE PRIVILÈGE',
                        style: TextStyle(
                          color: Color(0xFFC5A080),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Carte formulaire
                Expanded(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: KinovaColors.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: KinovaColors.gold.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ModeToggle(
                                  registerMode: _registerMode,
                                  onChanged: _switchMode,
                                ),
                                const SizedBox(height: 24),

                                // Titre animé
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                  child: Column(
                                    key: ValueKey(_registerMode),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _registerMode
                                            ? 'Rejoignez la Maison'
                                            : 'Bon retour parmi nous',
                                        style: const TextStyle(
                                          fontFamily: 'PlayfairDisplay',
                                          color: KinovaColors.brown,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _registerMode
                                            ? 'Créez votre compte et cumulez vos points VIP.'
                                            : 'Retrouvez vos favoris, commandes et avantages.',
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: KinovaColors.mutedBrown,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Champs inscription (animés)
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: _registerMode
                                      ? Column(
                                          children: [
                                            _LuxField(
                                              controller: _name,
                                              hint: 'Nom complet',
                                              icon: Icons.person_outline_rounded,
                                              validator: (v) => (v == null ||
                                                      v.trim().isEmpty)
                                                  ? 'Votre nom est requis'
                                                  : null,
                                            ),
                                            const SizedBox(height: 14),
                                            _LuxField(
                                              controller: _phone,
                                              hint: 'Numéro de téléphone',
                                              icon: Icons.phone_iphone_rounded,
                                              keyboardType: TextInputType.phone,
                                              validator: (v) => (v == null ||
                                                      v.trim().length < 8)
                                                  ? 'Numéro de téléphone requis'
                                                  : null,
                                            ),
                                            const SizedBox(height: 14),
                                            _LuxField(
                                              controller: _email,
                                              hint: 'Email (optionnel)',
                                              icon: Icons.mail_outline_rounded,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              validator: (v) {
                                                final t = v?.trim() ?? '';
                                                if (t.isEmpty) return null;
                                                if (!t.contains('@')) {
                                                  return 'Email invalide';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // Connexion : email OU téléphone
                                if (!_registerMode) ...[
                                  _LuxField(
                                    controller: _email,
                                    hint: 'Email ou numéro de téléphone',
                                    icon: Icons.person_outline_rounded,
                                    keyboardType: TextInputType.text,
                                    validator: (v) => (v == null ||
                                            v.trim().isEmpty)
                                        ? 'Email ou téléphone requis'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _LuxField(
                                  controller: _password,
                                  hint: 'Mot de passe',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscure,
                                  suffix: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: KinovaColors.sand,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? '6 caractères minimum'
                                      : null,
                                ),

                                // Erreur
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  child: _error == null
                                      ? const SizedBox.shrink()
                                      : Container(
                                          margin:
                                              const EdgeInsets.only(top: 16),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDECEA),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE57373)
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: Color(0xFFC62828),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _error!,
                                                  style: const TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    color: Color(0xFFC62828),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 24),

                                // Bouton principal doré
                                _GoldButton(
                                  loading: _loading,
                                  label: _registerMode
                                      ? 'CRÉER MON COMPTE'
                                      : 'SE CONNECTER',
                                  onPressed: _submit,
                                ),

                                const SizedBox(height: 18),

                                // Séparateur
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color:
                                            KinovaColors.sand.withOpacity(0.4),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'EVERYTHING YOU LOVE',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: KinovaColors.sand,
                                          fontSize: 8.5,
                                          letterSpacing: 2.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color:
                                            KinovaColors.sand.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Lien bascule
                                Center(
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => _switchMode(!_registerMode),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12.5,
                                          color: KinovaColors.mutedBrown,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: _registerMode
                                                ? 'Déjà membre ?  '
                                                : 'Nouveau chez KINOVA ?  ',
                                          ),
                                          TextSpan(
                                            text: _registerMode
                                                ? 'Connexion'
                                                : 'Créer un compte',
                                            style: const TextStyle(
                                              color: KinovaColors.brown,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  KinovaColors.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

/// Toggle animé Connexion / Inscription
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.registerMode,
    required this.onChanged,
  });

  final bool registerMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KinovaColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KinovaColors.gold.withOpacity(0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: registerMode ? segmentWidth : 0,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: KinovaColors.darkLuxuryGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: KinovaColors.brown.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _segment('CONNEXION', !registerMode, () => onChanged(false)),
                  _segment('INSCRIPTION', registerMode, () => onChanged(true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? KinovaColors.goldLight : KinovaColors.mutedBrown,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Champ texte stylé boutique
class _LuxField extends StatelessWidget {
  const _LuxField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.brown,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: KinovaColors.sand, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Bouton doré dégradé avec état chargement
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 54,
      decoration: BoxDecoration(
        gradient: KinovaColors.darkLuxuryGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: KinovaColors.gold.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: KinovaColors.brown.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: loading ? null : onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KinovaColors.goldLight,
                      ),
                    )
                  : Text(
                      label,
                      key: ValueKey(label),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: KinovaColors.goldLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

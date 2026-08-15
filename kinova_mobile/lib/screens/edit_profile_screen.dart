import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_avatar.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _address = TextEditingController(text: user?.address ?? '');
    _city = TextEditingController(text: user?.city ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().uploadAvatar(File(picked.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Impossible d’envoyer la photo');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final newPass = _password.text.trim();
      await context.read<AuthController>().updateProfile(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
            address: _address.text,
            city: _city.text,
            password: newPass.isEmpty ? null : newPass,
            currentPassword: _currentPassword.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Enregistrement impossible');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: KinovaColors.background,
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: KinovaColors.background,
                surfaceTintColor: Colors.transparent,
                title: const Text(
                  'Modifier mon profil',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    color: KinovaColors.brown,
                    fontSize: 20,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // ===== Carte avatar =====
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                      decoration: BoxDecoration(
                        gradient: KinovaColors.darkLuxuryGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: KinovaColors.gold.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KinovaColors.brown.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              KinovaAvatar(
                                name: user?.name ?? 'K',
                                imageUrl: user?.avatarUrl,
                                radius: 52,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap:
                                      _uploadingAvatar ? null : _pickAvatar,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: KinovaColors.goldGradient,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1B110B),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: KinovaColors.goldRich
                                              .withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: _uploadingAvatar
                                        ? const Padding(
                                            padding: EdgeInsets.all(9),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: KinovaColors.brown,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 18,
                                            color: KinovaColors.brown,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user?.name ?? 'Profil KINOVA',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              color: KinovaColors.cream,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Touchez l’appareil photo pour changer',
                            style: TextStyle(
                              color: KinovaColors.sand.withValues(alpha: 0.9),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Informations',
                      subtitle: 'Vos coordonnées personnelles',
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      children: [
                        _LuxProfileField(
                          controller: _name,
                          label: 'Nom complet',
                          hint: 'Votre nom',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nom requis'
                              : null,
                        ),
                        _LuxProfileField(
                          controller: _phone,
                          label: 'Téléphone',
                          hint: '+225 …',
                          icon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.trim().length < 8)
                                  ? 'Téléphone requis'
                                  : null,
                        ),
                        _LuxProfileField(
                          controller: _email,
                          label: 'Email',
                          hint: 'optionnel',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return null;
                            if (!t.contains('@')) return 'Email invalide';
                            return null;
                          },
                        ),
                        _LuxProfileField(
                          controller: _address,
                          label: 'Adresse',
                          hint: 'optionnel',
                          icon: Icons.home_outlined,
                        ),
                        _LuxProfileField(
                          controller: _city,
                          label: 'Ville',
                          hint: 'optionnel',
                          icon: Icons.location_city_outlined,
                          isLast: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Sécurité',
                      subtitle: 'Laissez vide pour ne pas changer',
                    ),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      children: [
                        _LuxProfileField(
                          controller: _currentPassword,
                          label: 'Mot de passe actuel',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                        ),
                        _LuxProfileField(
                          controller: _password,
                          label: 'Nouveau mot de passe',
                          hint: '6 caractères minimum',
                          icon: Icons.lock_rounded,
                          obscure: _obscure,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return null;
                            if (t.length < 6) return '6 caractères minimum';
                            return null;
                          },
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
                        ),
                        _LuxProfileField(
                          controller: _passwordConfirm,
                          label: 'Confirmation',
                          hint: 'Répétez le mot de passe',
                          icon: Icons.verified_user_outlined,
                          obscure: _obscure,
                          isLast: true,
                          validator: (v) {
                            if (_password.text.isEmpty) return null;
                            if (v != _password.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE57373).withValues(alpha: 0.5),
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
                                  color: Color(0xFFC62828),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 26),
                    PressableScale(
                      onTap: _saving ? null : _save,
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: KinovaColors.darkLuxuryGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: KinovaColors.gold.withValues(alpha: 0.55),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KinovaColors.brown.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: KinovaColors.gold,
                                ),
                              )
                            : const Text(
                                'ENREGISTRER LES MODIFICATIONS',
                                style: TextStyle(
                                  color: KinovaColors.goldLight,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              decoration: BoxDecoration(
                gradient: KinovaColors.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: KinovaColors.mutedBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KinovaColors.brown.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KinovaColors.gold.withValues(alpha: 0.18)),
        boxShadow: KinovaColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _LuxProfileField extends StatelessWidget {
  const _LuxProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.suffix,
    this.isLast = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: isLast ? 10 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 7),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: KinovaColors.mutedBrown.withValues(alpha: 0.95),
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            validator: validator,
            cursorColor: KinovaColors.goldRich,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: KinovaColors.brown,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: KinovaColors.mutedBrown.withValues(alpha: 0.55),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 10, right: 6),
                child: Icon(icon, color: KinovaColors.gold, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: KinovaColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: KinovaColors.gold.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: KinovaColors.gold,
                  width: 1.4,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE57373)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
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

    return Scaffold(
      backgroundColor: KinovaColors.background,
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: KinovaColors.gold, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: KinovaColors.brown,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              (user?.name.isNotEmpty == true
                                      ? user!.name[0]
                                      : 'K')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                color: KinovaColors.gold,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: KinovaColors.goldGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KinovaColors.cream,
                            width: 2,
                          ),
                        ),
                        child: _uploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(8),
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
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Changer la photo',
                style: TextStyle(
                  color: KinovaColors.mutedBrown,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _field(
              controller: _name,
              label: 'Nom complet',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            _field(
              controller: _phone,
              label: 'Téléphone',
              icon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Téléphone requis'
                  : null,
            ),
            _field(
              controller: _email,
              label: 'Email (optionnel)',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                if (!t.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            _field(
              controller: _address,
              label: 'Adresse (optionnel)',
              icon: Icons.home_outlined,
            ),
            _field(
              controller: _city,
              label: 'Ville (optionnel)',
              icon: Icons.location_city_outlined,
            ),

            const SizedBox(height: 10),
            const Text(
              'Mot de passe',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: KinovaColors.brown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Laissez vide pour ne pas changer',
              style: TextStyle(
                fontSize: 11.5,
                color: KinovaColors.mutedBrown.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _currentPassword,
              label: 'Mot de passe actuel',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
            ),
            _field(
              controller: _password,
              label: 'Nouveau mot de passe',
              icon: Icons.lock_rounded,
              obscure: _obscure,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                if (t.length < 6) return '6 caractères minimum';
                return null;
              },
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: KinovaColors.mutedBrown,
                  size: 20,
                ),
              ),
            ),
            _field(
              controller: _passwordConfirm,
              label: 'Confirmer le nouveau mot de passe',
              icon: Icons.lock_rounded,
              obscure: _obscure,
              validator: (v) {
                if (_password.text.isEmpty) return null;
                if (v != _password.text) return 'Les mots de passe ne correspondent pas';
                return null;
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: 22),
            PressableScale(
              onTap: _saving ? null : _save,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: KinovaColors.goldGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: KinovaColors.goldRich.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: KinovaColors.brown,
                        ),
                      )
                    : const Text(
                        'ENREGISTRER',
                        style: TextStyle(
                          color: KinovaColors.brown,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: KinovaColors.gold, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: KinovaColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: KinovaColors.gold.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: KinovaColors.gold.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KinovaColors.gold, width: 1.4),
          ),
        ),
      ),
    );
  }
}

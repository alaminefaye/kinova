import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  Map<String, dynamic>? _help;
  bool _loading = true;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().user;
      if (user != null) {
        _name.text = user.name;
        _email.text = user.email ?? '';
      }
      _load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<ApiClient>().get('/help');
      final data = res is Map && res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};
      setState(() => _help = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<ApiClient>().post('/contact', body: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = (_help?['faqs'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Aide & Contact')),
      body: _loading
          ? const KinovaLoader(message: 'Chargement')
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                Text('Nous contacter', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Email: ${_help?['email'] ?? '—'}'),
                Text('Tél: ${_help?['phone'] ?? '—'}'),
                Text('Horaires: ${_help?['hours'] ?? '—'}'),
                const SizedBox(height: 20),
                Text('FAQ', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...faqs.whereType<Map>().map((f) {
                  return ExpansionTile(
                    title: Text('${f['q'] ?? ''}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text('${f['a'] ?? ''}'),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Text('Écrire au service client',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Nom'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subject,
                  decoration: const InputDecoration(hintText: 'Sujet'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _message,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Message'),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KinovaColors.cream,
                          ),
                        )
                      : const Text('ENVOYER'),
                ),
              ],
            ),
    );
  }
}

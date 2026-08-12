import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/screens/edit_profile_screen.dart';
import 'package:kinova_mobile/screens/favorites_screen.dart';
import 'package:kinova_mobile/screens/help_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadingOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) return;
    setState(() => _loadingOrders = true);
    try {
      final orders = await auth.fetchOrders();
      if (!mounted) return;
      context.read<CartController>().setOrders(orders);
      await auth.refreshProfile();
    } catch (_) {
      // keep existing local orders
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  String _tierLabel(String tier) {
    return switch (tier.toLowerCase()) {
      'vip' => 'VIP',
      'gold' => 'OR',
      'silver' => 'ARGENT',
      _ => 'STANDARD',
    };
  }

  Future<void> _openAuth() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (ok == true && mounted) {
      await _loadOrders();
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    final favorites = context.read<FavoritesController>();
    final cart = context.read<CartController>();
    await auth.logout();
    favorites.clearLocal();
    cart.setOrders(const []);
  }

  Future<void> _openEditProfile() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (ok == true && mounted) {
      await context.read<AuthController>().refreshProfile();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
    );

    if (deleted != true || !mounted) return;

    context.read<FavoritesController>().clearLocal();
    context.read<CartController>().setOrders(const []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compte supprimé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final orders = context.watch<CartController>().orders;
    final user = auth.user;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte Privilège'),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: KinovaColors.darkLuxuryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: KinovaColors.brown.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: KinovaColors.gold.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KinovaColors.gold,
                            width: 1.8,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user != null ? user.name : 'Invité KINOVA',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: KinovaColors.cream,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KinovaColors.gold,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    user != null
                                        ? _tierLabel(user.vipTier)
                                        : 'GUEST',
                                    style: const TextStyle(
                                      color: KinovaColors.brown,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user == null
                                  ? 'Connectez-vous pour vos avantages'
                                  : (user.email?.isNotEmpty == true
                                      ? user.email!
                                      : (user.phone ?? 'Compte KINOVA')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: KinovaColors.sand,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Color(0x33C5A080),
                      height: 1,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FIDÉLITÉ KINOVA',
                            style: TextStyle(
                              color: KinovaColors.gold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null
                                ? '${user.loyaltyPoints} Points'
                                : '— Points',
                            style: const TextStyle(
                              color: KinovaColors.cream,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: auth.isLoggedIn ? _loadOrders : _openAuth,
                        style: TextButton.styleFrom(
                          foregroundColor: KinovaColors.cream,
                          backgroundColor: KinovaColors.gold.withOpacity(0.2),
                        ),
                        child: Text(
                          auth.isLoggedIn ? 'Actualiser' : 'Se connecter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique de Commandes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  _loadingOrders
                      ? '…'
                      : '${orders.length} commande${orders.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: KinovaColors.mutedBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!auth.isLoggedIn)
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _EmptyCard(
                title: 'Connectez-vous',
                subtitle: 'Retrouvez vos commandes et votre suivi livraison.',
                icon: Icons.lock_outline,
              ),
            )
          else if (_loadingOrders && orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: KinovaLoader(
                size: 58,
                compact: true,
                message: 'Chargement des commandes',
              ),
            )
          else if (orders.isEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: const _EmptyCard(
                title: 'Aucune commande active',
                subtitle: 'Vos futurs achats apparaîtront ici.',
                icon: Icons.shopping_bag_outlined,
              ),
            )
          else
            ...orders.asMap().entries.map((entry) {
              final i = entry.key;
              final order = entry.value;
              return FadeSlideIn(
                delay: Duration(milliseconds: 80 + i * 40),
                child: _OrderCard(order: order, dateFormat: dateFormat),
              );
            }),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: KinovaColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: KinovaColors.cardShadow,
                border: Border.all(
                  color: KinovaColors.gold.withOpacity(0.16),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  if (auth.isLoggedIn) ...[
                    _Tile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Modifier mon profil',
                      onTap: _openEditProfile,
                    ),
                    const Divider(
                      height: 1,
                      indent: 48,
                      color: KinovaColors.surfaceMuted,
                    ),
                  ],
                  _Tile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Suivi de ma livraison',
                    onTap: () {
                      if (orders.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aucune commande à suivre'),
                          ),
                        );
                        return;
                      }
                      final o = orders.first;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(o.id),
                          content: Text(
                            'Statut: ${o.status}\n'
                            'Transporteur: ${o.carrier ?? '—'}\n'
                            'Suivi: ${o.trackingNumber ?? '—'}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 48,
                    color: KinovaColors.surfaceMuted,
                  ),
                  _Tile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Mes pièces enregistrées',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 48,
                    color: KinovaColors.surfaceMuted,
                  ),
                  _Tile(
                    icon: Icons.help_outline_rounded,
                    title: 'Service Client & Assistance',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                  ),
                  if (auth.isLoggedIn) ...[
                    const Divider(
                      height: 1,
                      indent: 48,
                      color: KinovaColors.surfaceMuted,
                    ),
                    _Tile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Supprimer mon compte',
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: KinovaColors.cardShadow,
        border: Border.all(
          color: KinovaColors.gold.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: KinovaColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KinovaColors.sand, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.dateFormat});

  final Order order;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: KinovaColors.cardShadow,
        border: Border.all(
          color: KinovaColors.gold.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KinovaColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: KinovaColors.brown,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.id,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${dateFormat.format(order.createdAt)} · ${order.items.length} article${order.items.length > 1 ? 's' : ''}'
                        '${order.trackingNumber != null ? ' · ${order.trackingNumber}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatMoney(order.total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: KinovaColors.brown,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: KinovaColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: KinovaColors.brown, size: 18),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: KinovaColors.sand,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

/// Dialogue sécurisé : la suppression se fait ici (loading + validation),
/// pour éviter les crashs liés au controller / au clavier.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.toLowerCase() != 'kinovaci') {
      setState(() => _error = 'Code incorrect. Tapez « kinovaci ».');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthController>().deleteAccount(code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Suppression impossible. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette action est définitive. Pour confirmer, tapez le code :',
            style: TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'kinovaci',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: KinovaColors.brown,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            enabled: !_loading,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loading ? null : _submit(),
            decoration: InputDecoration(
              hintText: 'Code de confirmation',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Supprimer'),
        ),
      ],
    );
  }
}

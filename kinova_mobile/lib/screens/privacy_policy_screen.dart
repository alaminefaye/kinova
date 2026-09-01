import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _updatedAt = '1er septembre 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinovaColors.background,
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Text(
            'Dernière mise à jour : $_updatedAt',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KinovaColors.mutedBrown,
                ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '1. Introduction',
            body:
                'KINOVA exploite kinovaci.com et l’application mobile KINOVA. '
                'Cette politique explique quelles données nous collectons, pourquoi '
                'nous les utilisons et quels sont vos droits.\n\n'
                'En créant un compte, vous acceptez cette politique.',
          ),
          _Section(
            title: '2. Données collectées',
            body:
                '• Nom et prénom\n'
                '• Téléphone (obligatoire) et e-mail (optionnel)\n'
                '• Mot de passe (chiffré) et photo de profil\n'
                '• Commandes, adresses, historique d’achats\n'
                '• Favoris et avis produits\n'
                '• Notifications in-app et token push (Firebase)\n'
                '• Messages envoyés au service client',
          ),
          _Section(
            title: '3. Finalités',
            body:
                '• Gérer votre compte et vos commandes\n'
                '• Suivi livraison et programme VIP\n'
                '• Notifications (statut commande, promotions)\n'
                '• Assistance client\n'
                '• Sécurité et amélioration du service',
          ),
          _Section(
            title: '4. Partage',
            body:
                'Nous ne vendons pas vos données. Elles peuvent être partagées avec '
                'nos prestataires (hébergement, Firebase pour les push), les transporteurs '
                'et les autorités si la loi l’exige.',
          ),
          _Section(
            title: '5. Vos droits',
            body:
                '• Modifier votre profil dans l’app\n'
                '• Supprimer votre compte (Profil → Supprimer mon compte, code kinovaci)\n'
                '• Désactiver les notifications push dans les réglages du téléphone\n'
                '• Nous contacter via Aide & Contact',
          ),
          _Section(
            title: '6. Sécurité',
            body:
                'Connexions HTTPS, mots de passe hashés, accès restreints. '
                'Nous appliquons des mesures raisonnables pour protéger vos informations.',
          ),
          _Section(
            title: '7. Contact',
            body:
                'E-mail : contact@kinovaci.com\n'
                'Site : https://kinovaci.com\n'
                'Politique en ligne : https://kinovaci.com/politique-confidentialite',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KinovaColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KinovaColors.surfaceMuted),
          boxShadow: KinovaColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'PlayfairDisplay',
                    color: KinovaColors.brown,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KinovaColors.mutedBrown,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

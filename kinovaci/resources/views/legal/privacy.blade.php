@extends('layouts.legal')

@section('title', 'Politique de confidentialité')
@section('heading', 'Politique de confidentialité')

@section('content')
    <p class="updated">Dernière mise à jour : 3 octobre 2026</p>

    <section class="card">
        <h2>1. Introduction</h2>
        <p>
            KINOVA (« nous », « notre ») exploite la boutique en ligne
            <strong>kinovaci.com</strong> et l’application mobile KINOVA. La présente politique
            explique quelles données nous collectons, pourquoi nous les utilisons et quels sont vos
            droits.
        </p>
        <p>
            En créant un compte ou en utilisant nos services, vous acceptez cette politique. Si vous
            n’êtes pas d’accord, veuillez ne pas utiliser nos services.
        </p>
    </section>

    <section class="card">
        <h2>2. Données que nous collectons</h2>
        <ul>
            <li><strong>Identité :</strong> nom, prénom</li>
            <li><strong>Contact :</strong> numéro de téléphone (obligatoire), adresse e-mail (optionnelle)</li>
            <li><strong>Compte :</strong> mot de passe (stocké de manière chiffrée), photo de profil</li>
            <li><strong>Commandes :</strong> articles, montants, adresse de livraison, historique</li>
            <li><strong>Localisation :</strong> position GPS de livraison, uniquement si vous choisissez de la partager lors d’une commande (jamais en arrière-plan)</li>
            <li><strong>Favoris &amp; avis :</strong> produits enregistrés, notes laissées</li>
            <li><strong>Notifications :</strong> messages in-app et token push (Firebase) pour vous alerter</li>
            <li><strong>Panier :</strong> contenu du panier conservé sur votre appareil, avec un rappel local si une commande n’est pas finalisée</li>
            <li><strong>Support :</strong> messages envoyés via le formulaire de contact</li>
            <li><strong>Technique :</strong> type d’appareil, système (via les services Firebase pour les push)</li>
        </ul>
    </section>

    <section class="card">
        <h2>3. Finalités</h2>
        <ul>
            <li>Créer et gérer votre compte client</li>
            <li>Traiter vos commandes et assurer le suivi livraison</li>
            <li>Vous informer du statut de commande et des promotions (notifications)</li>
            <li>Gérer le programme de fidélité VIP</li>
            <li>Répondre à vos demandes d’assistance</li>
            <li>Améliorer nos services et prévenir la fraude</li>
        </ul>
    </section>

    <section class="card">
        <h2>4. Partage des données</h2>
        <p>
            Nous <strong>ne vendons pas</strong> vos données personnelles. Nous pouvons les partager
            uniquement avec nos prestataires techniques (hébergement, Firebase/Google pour les push),
            les transporteurs pour la livraison, et les autorités si la loi l’exige.
        </p>
    </section>

    <section class="card">
        <h2>5. Conservation</h2>
        <p>
            Vos données sont conservées tant que votre compte est actif, puis archivées ou supprimées
            conformément aux obligations légales. Les messages de contact sont conservés le temps
            nécessaire au traitement de votre demande.
        </p>
    </section>

    <section class="card">
        <h2>6. Vos droits</h2>
        <ul>
            <li>Consulter et modifier votre profil dans l’app ou sur le site</li>
            <li>Demander la suppression de votre compte (Compte → Supprimer mon compte, code <code>kinovaci</code> — détails sur <a href="{{ url('/suppression-compte') }}">kinovaci.com/suppression-compte</a>)</li>
            <li>Refuser les notifications push via les réglages de votre téléphone</li>
            <li>Nous contacter via <a href="{{ url('/aide') }}">Aide &amp; contact</a></li>
        </ul>
    </section>

    <section class="card">
        <h2>7. Sécurité</h2>
        <p>
            Nous utilisons le chiffrement HTTPS, des mots de passe hashés et des accès restreints.
            Nous mettons en œuvre des mesures raisonnables pour protéger vos informations.
        </p>
    </section>

    <section class="card">
        <h2>8. Mineurs</h2>
        <p>
            KINOVA s’adresse aux personnes de 16 ans et plus. Nous ne collectons pas sciemment de
            données d’enfants sans consentement parental.
        </p>
    </section>

    <section class="card">
        <h2>9. Modifications</h2>
        <p>
            Nous pouvons mettre à jour cette politique. La date en tête de page sera modifiée. En cas
            de changement important, nous vous en informerons via l’application ou par notification.
        </p>
    </section>

    <section class="card">
        <h2>10. Nous contacter</h2>
        <p>Pour toute question relative à vos données personnelles :</p>
        <p><strong>E-mail :</strong> <a href="mailto:{{ config('kinova.support_email') }}">{{ config('kinova.support_email') }}</a></p>
        <p><strong>Formulaire :</strong> <a href="{{ url('/aide') }}">Aide &amp; contact</a></p>
        <p><strong>Site :</strong> <a href="{{ url('/') }}">kinovaci.com</a></p>
    </section>
@endsection

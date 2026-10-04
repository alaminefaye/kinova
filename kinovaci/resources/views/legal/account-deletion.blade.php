@extends('layouts.legal')

@section('title', 'Suppression de compte')
@section('heading', 'Supprimer votre compte KINOVA')

@section('content')
    <section class="card">
        <p>
            Cette page concerne l’application mobile <strong>KINOVA</strong> et la boutique
            <strong>kinovaci.com</strong>, éditées par KINOVA. Vous pouvez supprimer votre compte
            à tout moment, gratuitement.
        </p>
    </section>

    <section class="card">
        <h2>1. Depuis l’application KINOVA (immédiat)</h2>
        <ol>
            <li>Ouvrez l’application et connectez-vous.</li>
            <li>Allez dans l’onglet <strong>Compte</strong>.</li>
            <li>Touchez <strong>Supprimer mon compte</strong>.</li>
            <li>Tapez le code de confirmation <code>kinovaci</code> puis touchez <strong>Supprimer</strong>.</li>
        </ol>
        <p>Votre compte est supprimé immédiatement et vous êtes déconnecté de tous vos appareils.</p>
    </section>

    <section class="card">
        <h2>2. Depuis le site web (immédiat)</h2>
        <ol>
            <li>Rendez-vous sur <a href="{{ url('/connexion') }}">kinovaci.com/connexion</a> et connectez-vous.</li>
            <li>Ouvrez <strong>Compte</strong> puis cliquez sur <strong>Supprimer mon compte</strong>.</li>
            <li>Confirmez avec le code <code>kinovaci</code>.</li>
        </ol>
    </section>

    <section class="card">
        <h2>3. Sans accès à votre compte</h2>
        <p>
            Écrivez-nous depuis le numéro de téléphone ou l’adresse e-mail liés à votre compte, en
            indiquant « Suppression de compte » :
        </p>
        <p><strong>E-mail :</strong> <a href="mailto:{{ config('kinova.support_email') }}?subject=Suppression%20de%20compte">{{ config('kinova.support_email') }}</a></p>
        <p><strong>Téléphone :</strong> <a href="tel:{{ preg_replace('/\s+/', '', config('kinova.support_phone')) }}">{{ config('kinova.support_phone') }}</a></p>
        <p>Nous vérifions que la demande vient bien du titulaire du compte, puis la traitons sous 7 jours.</p>
    </section>

    <section class="card">
        <h2>Données supprimées</h2>
        <ul>
            <li>Informations du compte : nom, téléphone, e-mail, mot de passe, photo de profil</li>
            <li>Favoris et notes laissées sur les produits</li>
            <li>Notifications reçues et jetons de notifications push</li>
            <li>Points et historique du programme de fidélité</li>
            <li>Sessions de connexion sur tous les appareils</li>
        </ul>
    </section>

    <section class="card">
        <h2>Données conservées</h2>
        <ul>
            <li>
                <strong>Commandes passées</strong> (référence, articles, montants, nom, téléphone et
                adresse de livraison) : détachées de votre compte et conservées pendant la durée légale
                de conservation des documents comptables (10 ans), puis supprimées.
            </li>
            <li>
                <strong>Messages envoyés au service client</strong> : détachés de votre compte et
                conservés pour le suivi de vos demandes ; vous pouvez demander leur suppression à
                l’adresse ci-dessus.
            </li>
        </ul>
        <p>
            Les données présentes sur votre téléphone (panier, préférences) sont effacées en
            désinstallant l’application.
        </p>
        <p><a href="{{ url('/politique-confidentialite') }}">Politique de confidentialité</a></p>
    </section>
@endsection

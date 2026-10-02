@extends('layouts.legal')

@section('title', 'Aide & contact')
@section('heading', 'Aide & contact')

@section('content')
    <section class="card">
        <h2>Nous joindre</h2>
        <p><strong>E-mail :</strong> <a href="mailto:{{ config('kinova.support_email') }}">{{ config('kinova.support_email') }}</a></p>
        <p><strong>Téléphone :</strong> <a href="tel:{{ preg_replace('/\s+/', '', config('kinova.support_phone')) }}">{{ config('kinova.support_phone') }}</a></p>
        <p><strong>Horaires :</strong> {{ config('kinova.support_hours') }}</p>
    </section>

    <section class="card">
        <h2>Questions fréquentes</h2>
        <p><strong>Délais de livraison ?</strong><br>2 à 5 jours ouvrés selon votre ville.</p>
        <p><strong>Suivre ma commande ?</strong><br>Utilisez votre référence KV-… ou consultez « Mes commandes » dans l’application.</p>
        <p><strong>Points VIP ?</strong><br>{{ \App\Services\AppSettings::render('{montant} dépensés = {points}.') }} Les paliers débloquent Silver, Gold puis VIP.</p>
        <p><strong>Retour d’article ?</strong><br>Oui, sous 14 jours si l’article est non utilisé, dans son emballage.</p>
    </section>

    <section class="card">
        <h2>Application KINOVA</h2>
        <p>
            Pour nous écrire depuis l’app : ouvrez <strong>Compte → Service Client &amp; Assistance</strong>
            et remplissez le formulaire de contact.
        </p>
        <p><a href="{{ url('/') }}">Retour à la boutique KINOVA</a></p>
        <p><a href="{{ url('/politique-confidentialite') }}">Politique de confidentialité</a></p>
    </section>
@endsection

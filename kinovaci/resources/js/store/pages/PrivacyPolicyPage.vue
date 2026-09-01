<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
const updatedAt = '1er septembre 2026'
</script>

<template>
  <div class="page">
    <header class="head">
      <div class="kv-container row">
        <button class="round" type="button" @click="router.back()">←</button>
        <h1 class="kv-display">Politique de confidentialité</h1>
      </div>
    </header>

    <div class="kv-container body">
      <p class="updated">Dernière mise à jour : {{ updatedAt }}</p>

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
          <li><strong>Favoris &amp; avis :</strong> produits enregistrés, notes laissées</li>
          <li><strong>Notifications :</strong> messages in-app et token push (Firebase) pour vous alerter</li>
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
          uniquement avec :
        </p>
        <ul>
          <li>Nos prestataires techniques (hébergement, Firebase/Google pour les notifications push)</li>
          <li>Les transporteurs pour la livraison de vos commandes</li>
          <li>Les autorités si la loi l’exige</li>
        </ul>
      </section>

      <section class="card">
        <h2>5. Conservation</h2>
        <p>
          Vos données sont conservées tant que votre compte est actif, puis archivées ou supprimées
          conformément aux obligations légales (facturation, comptabilité). Les messages de contact
          sont conservés le temps nécessaire au traitement de votre demande.
        </p>
      </section>

      <section class="card">
        <h2>6. Vos droits</h2>
        <p>Vous pouvez à tout moment :</p>
        <ul>
          <li>Consulter et modifier votre profil dans l’app ou sur le site</li>
          <li>Demander la suppression de votre compte (Profil → Supprimer mon compte, code <code>kinovaci</code>)</li>
          <li>Refuser les notifications push via les réglages de votre téléphone</li>
          <li>Nous contacter pour toute question : <router-link to="/aide">Service client</router-link></li>
        </ul>
      </section>

      <section class="card">
        <h2>7. Sécurité</h2>
        <p>
          Nous utilisons le chiffrement HTTPS, des mots de passe hashés et des accès restreints.
          Aucune transmission sur Internet n’est totalement infaillible ; nous mettons en œuvre des
          mesures raisonnables pour protéger vos informations.
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

      <section class="card contact">
        <h2>10. Nous contacter</h2>
        <p>Pour toute question relative à vos données personnelles :</p>
        <p>
          <strong>E-mail :</strong>
          <a href="mailto:contact@kinovaci.com">contact@kinovaci.com</a>
        </p>
        <p>
          <strong>Formulaire :</strong>
          <router-link to="/aide">Aide &amp; contact</router-link>
        </p>
        <p><strong>Site :</strong> <a href="https://kinovaci.com">kinovaci.com</a></p>
      </section>
    </div>
  </div>
</template>

<style scoped>
.page {
  min-height: 100vh;
  background: var(--kv-bg);
}
.head {
  background: linear-gradient(135deg, #3e2723, #251614);
  border-radius: 0 0 28px 28px;
  padding: 1rem 0 1.25rem;
  color: var(--kv-cream);
}
.row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.round {
  width: 42px;
  height: 42px;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: rgba(255, 255, 255, 0.1);
  color: var(--kv-cream);
  cursor: pointer;
}
h1 {
  margin: 0;
  font-size: 1.1rem;
  color: #f7e7ce;
}
.body {
  padding: 1rem 0 2.5rem;
}
.updated {
  color: var(--kv-muted);
  font-size: 0.82rem;
  margin: 0 0 1rem;
}
.card {
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1rem 1.1rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
  margin-bottom: 0.85rem;
  box-shadow: var(--kv-shadow);
}
.card h2 {
  margin: 0 0 0.55rem;
  font-size: 0.95rem;
  font-family: var(--kv-font-display);
  color: var(--kv-brown);
}
.card p,
.card li {
  margin: 0.35rem 0;
  color: var(--kv-muted);
  font-size: 0.86rem;
  line-height: 1.55;
}
.card ul {
  margin: 0.4rem 0 0;
  padding-left: 1.1rem;
}
.card a,
.card :deep(a) {
  color: var(--kv-brown);
  font-weight: 700;
}
code {
  background: rgba(197, 160, 128, 0.15);
  padding: 0.1rem 0.35rem;
  border-radius: 4px;
  font-size: 0.82rem;
}
</style>

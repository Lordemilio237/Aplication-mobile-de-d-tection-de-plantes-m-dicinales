# 🌿 Application de Détection des Plantes Médicinales

Une application mobile intelligente et intuitive conçue pour la reconnaissance instantanée et le catalogage des plantes médicinales à partir d'images. Grâce à l'intégration d'un modèle d'apprentissage automatique embarqué, l'application fournit une identification rapide ainsi que des fiches détaillées sur les vertus et usages des plantes.

---

## 📱 Aperçu des Fonctionnalités

- 📷 **Reconnaissance par Image :** Identification instantanée via l'appareil photo ou une image de la galerie.
- ⚡ **Mode Hors-Ligne :** Détection rapide en local grâce au modèle TensorFlow Lite embarqué.
- 📚 **Encyclopédie des Plantes :** Fiches détaillées couvrant les vertus médicinales, conseils d'utilisation et précautions.
- 🗂 **Historique & Favoris :** Sauvegarde des recherches récentes et enregistrement des plantes préférées.

---

## 🛠 Tech Stack

- **Framework Mobile :** [Flutter](https://flutter.dev/) (Dart)
- **Machine Learning :** [TensorFlow Lite](https://www.tensorflow.org/lite)
- **Base de données & Backend :** [Firebase](https://firebase.google.com/) (Firestore, Authentication)

---

## 🚀 Installation et Configuration

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé
- [Git](https://git-scm.com/) configuré
- Un appareil physique ou un émulateur (Android / iOS)

### Étapes d'installation

1. **Cloner le dépôt :**
   ```bash
   git clone https://github.com/votre-utilisateur/nom-du-depot.git
   cd applicationdedetectiondesplantesmedicinales
   ```

2. **Installer les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application :**
   ```bash
   flutter run
   ```

---

## 📂 Structure du Projet

```text
lib/
├── models/         # Modèles de données (Plantes, Utilisateur)
├── screens/        # Écrans principaux (Accueil, Caméra, Fiche Plante)
├── services/       # Interaction avec TFLite et Firebase
├── widgets/        # Composants d'interface réutilisables
└── main.dart       # Point d'entrée de l'application
```

---

## 👤 Auteur

- NGOMPA YOMBP Audrey Loic – [GitHub Profile](https://github.com/Lordemilio237)
// ============================================================
//  PlantaMed — Script d'importation Pro (Zéro Doublon)
// ============================================================

const https = require('https');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. INITIALISATION FIREBASE
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 2. LISTE DES PLANTES (55 espèces)
const PLANTES_MEDICINALES = [
  { nom_commun: 'Moringa', nom_scientifique: 'Moringa oleifera', categorie: 'Nutrition & Immunité' },
  { nom_commun: 'Neem (Margousier)', nom_scientifique: 'Azadirachta indica', categorie: 'Antiparasitaire & Infection' },
  { nom_commun: 'Aloe Vera', nom_scientifique: 'Aloe barbadensis', categorie: 'Peau & Cicatrisation' },
  { nom_commun: 'Gingembre', nom_scientifique: 'Zingiber officinale', categorie: 'Digestif & Douleur' },
  { nom_commun: 'Hibiscus (Bissap)', nom_scientifique: 'Hibiscus sabdariffa', categorie: 'Cardiovasculaire & Antioxydant' },
  { nom_commun: 'Curcuma', nom_scientifique: 'Curcuma longa', categorie: 'Anti-inflammatoire & Foie' },
  { nom_commun: 'Papayer', nom_scientifique: 'Carica papaya', categorie: 'Antiparasitaire & Infection' },
  { nom_commun: 'Citronnelle', nom_scientifique: 'Cymbopogon citratus', categorie: 'Relaxation & Sommeil' },
  { nom_commun: 'Basilic sacré', nom_scientifique: 'Ocimum tenuiflorum', categorie: 'Digestif & Douleur' },
  { nom_commun: 'Eucalyptus', nom_scientifique: 'Eucalyptus globulus', categorie: 'Respiratoire & Fièvre' },
  { nom_commun: 'Menthe poivrée', nom_scientifique: 'Mentha piperita', categorie: 'Digestif & Douleur' },
  { nom_commun: 'Camomille', nom_scientifique: 'Matricaria chamomilla', categorie: 'Relaxation & Sommeil' },
  { nom_commun: 'Ail', nom_scientifique: 'Allium sativum', categorie: 'Cardiovasculaire & Antioxydant' },
  { nom_commun: 'Thym', nom_scientifique: 'Thymus vulgaris', categorie: 'Respiratoire & Fièvre' },
  { nom_commun: 'Kinkeliba', nom_scientifique: 'Combretum micranthum', categorie: 'Digestif & Douleur' },
  { nom_commun: 'Vernonia (Ndolé)', nom_scientifique: 'Vernonia amygdalina', categorie: 'Antiparasitaire & Infection' },
  { nom_commun: 'Artemisia', nom_scientifique: 'Artemisia annua', categorie: 'Antipaludéen & Fièvre' },
  { nom_commun: 'Kalanchoé', nom_scientifique: 'Kalanchoe pinnata', categorie: 'Peau & Cicatrisation' },
  { nom_commun: 'Rooibos', nom_scientifique: 'Aspalathus linearis', categorie: 'Cardiovasculaire & Antioxydant' },
  { nom_commun: 'Spiruline', nom_scientifique: 'Arthrospira platensis', categorie: 'Nutrition & Immunité' },
  { nom_commun: 'Mango', nom_scientifique: 'Mangifera indica', categorie: 'Vitamines & Antioxydant' },
  { nom_commun: 'Pepper', nom_scientifique: 'Piper nigrum', categorie: 'Métabolisme & Toux' },
  { nom_commun: 'Pomegranate', nom_scientifique: 'Punica granatum', categorie: 'Cœur & Antioxydant' },
  { nom_commun: 'Raktachandini', nom_scientifique: 'Pterocarpus santalinus', categorie: 'Peau & Inflammation' },
  { nom_commun: 'Rose', nom_scientifique: 'Rosa', categorie: 'Peau & Relaxation' },
  { nom_commun: 'Sapota', nom_scientifique: 'Manilkara zapota', categorie: 'Énergie & Vitamines' },
  { nom_commun: 'Tulasi', nom_scientifique: 'Ocimum tenuiflorum', categorie: 'Immunité & Stress' },
  { nom_commun: 'Wood sorel', nom_scientifique: 'Oxalis', categorie: 'Digestion & Vitamine C' },
  { nom_commun: 'Jasmine', nom_scientifique: 'Jasminum', categorie: 'Relaxation & Sommeil' },
  { nom_commun: 'Amla', nom_scientifique: 'Phyllanthus emblica', categorie: 'Immunité & Digestion' },
  { nom_commun: 'Amruta Balli', nom_scientifique: 'Tinospora cordifolia', categorie: 'Fièvre & Détox' },
  { nom_commun: 'Arali', nom_scientifique: 'Nerium oleander', categorie: 'Attention: Toxique / Cardiaque' },
  { nom_commun: 'Ashoka', nom_scientifique: 'Saraca asoca', categorie: 'Santé Féminine' },
  { nom_commun: 'Ashwagandha', nom_scientifique: 'Withania somnifera', categorie: 'Stress & Énergie' },
  { nom_commun: 'Avacado', nom_scientifique: 'Persea americana', categorie: 'Nutrition & Peau' },
  { nom_commun: 'Bamboo', nom_scientifique: 'Bambusoideae', categorie: 'Articulations & Silice' },
  { nom_commun: 'Basale', nom_scientifique: 'Basella alba', categorie: 'Anémie & Digestion' },
  { nom_commun: 'Betel', nom_scientifique: 'Piper betle', categorie: 'Digestion & Haleine' },
  { nom_commun: 'Betel Nut', nom_scientifique: 'Areca catechu', categorie: 'Stimulant' },
  { nom_commun: 'Brahmi', nom_scientifique: 'Bacopa monnieri', categorie: 'Mémoire & Cerveau' },
  { nom_commun: 'Castor', nom_scientifique: 'Ricinus communis', categorie: 'Laxatif & Peau' },
  { nom_commun: 'Curry Leaf', nom_scientifique: 'Murraya koenigii', categorie: 'Cheveux & Diabète' },
  { nom_commun: 'Doddapatre', nom_scientifique: 'Plectranthus amboinicus', categorie: 'Toux & Rhume' },
  { nom_commun: 'Ekka', nom_scientifique: 'Calotropis gigantea', categorie: 'Anti-inflammatoire' },
  { nom_commun: 'Ganike', nom_scientifique: 'Solanum nigrum', categorie: 'Estomac & Fièvre' },
  { nom_commun: 'Gauva', nom_scientifique: 'Psidium guajava', categorie: 'Digestion & Vitamine C' },
  { nom_commun: 'Geranium', nom_scientifique: 'Pelargonium', categorie: 'Stress & Antibactérien' },
  { nom_commun: 'Henna', nom_scientifique: 'Lawsonia inermis', categorie: 'Cheveux & Refroidissement' },
  { nom_commun: 'Mint', nom_scientifique: 'Mentha', categorie: 'Digestion & Fraîcheur' },
  { nom_commun: 'Nagadali', nom_scientifique: 'Ruta graveolens', categorie: 'Douleurs & Spasmes' },
  { nom_commun: 'Lemon', nom_scientifique: 'Citrus limon', categorie: 'Détox & Immunité' },
  { nom_commun: 'Lemon grass', nom_scientifique: 'Cymbopogon', categorie: 'Grippe & Digestion' },
  { nom_commun: 'Nithyapushpa', nom_scientifique: 'Catharanthus roseus', categorie: 'Diabète & Hypertension' },
  { nom_commun: 'Nooni', nom_scientifique: 'Morinda citrifolia', categorie: 'Immunité & Énergie' },
  { nom_commun: 'Insulin', nom_scientifique: 'Chamaecostus cuspidatus', categorie: 'Diabète & Glycémie' },
];

// 3. FONCTIONS UTILITAIRES

// Supprime l'ancienne collection pour repartir sur du propre
async function clearCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.size === 0) return;
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`🗑️  Collection '${collectionName}' nettoyée.`);
}

function getLocalImageExtension(docId) {
  const extensions = ['.webp', '.jpg', '.jpeg', '.png'];
  for (let ext of extensions) {
    const filePath = path.join(__dirname, 'assets', 'images', `${docId}${ext}`);
    if (fs.existsSync(filePath)) return ext;
  }
  return null; // Retourne null si aucun fichier local n'existe
}

function fetchFromINaturalist(scientificName) {
  return new Promise((resolve) => {
    const query = encodeURIComponent(scientificName);
    const url = `https://api.inaturalist.org/v1/taxa?q=${query}&rank=species&per_page=1`;
    
    https.get(url, { headers: { 'User-Agent': 'PlantaMed/1.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.results && json.results.length > 0) {
            const taxon = json.results[0];
            resolve({
              imageUrl: taxon.default_photo?.medium_url || taxon.default_photo?.url || '',
              wikipedia: taxon.wikipedia_url || ''
            });
          } else resolve({ imageUrl: '', wikipedia: '' });
        } catch (e) { resolve({ imageUrl: '', wikipedia: '' }); }
      });
    }).on('error', () => resolve({ imageUrl: '', wikipedia: '' }));
  });
}

// 4. SCRIPT PRINCIPAL
async function main() {
  console.log('🌿 PlantaMed : Début de la synchronisation...\n');

  // ÉTAPE A : Nettoyer pour éviter les doublons d'anciens tests
  await clearCollection('plantes');

  const batch = db.batch();
  
  for (let i = 0; i < PLANTES_MEDICINALES.length; i++) {
    const plante = PLANTES_MEDICINALES[i];
    const docId = plante.nom_scientifique.toLowerCase().replace(/ /g, '_');
    const docRef = db.collection('plantes').doc(docId);

    process.stdout.write(`📡 Traitement [${i+1}/55] : ${plante.nom_commun}...`);

    // 1. Vérifier si image locale existe
    const localExt = getLocalImageExtension(docId);
    let finalImageUrl = localExt ? `assets/images/${docId}${localExt}` : '';
    let wikiUrl = '';

    // 2. Si pas d'image locale, on cherche sur l'API
    if (!finalImageUrl) {
      const data = await fetchFromINaturalist(plante.nom_scientifique);
      finalImageUrl = data.imageUrl;
      wikiUrl = data.wikipedia;
    }

    batch.set(docRef, {
      label_id: i.toString(),
      nom_commun: plante.nom_commun,
      nom_scientifique: plante.nom_scientifique,
      categorie: plante.categorie,
      image_url: finalImageUrl,
      wikipedia_url: wikiUrl,
      description: `La plante ${plante.nom_commun} est utilisée en médecine traditionnelle pour ses propriétés en ${plante.categorie.toLowerCase()}.`,
      est_favori: false,
      maladies_traitees: []
    });

    console.log(finalImageUrl.startsWith('http') ? ` ✅ API` : finalImageUrl ? ` 🏠 Local` : ` ⚠️ SANS IMAGE`);
    
    // Anti-Spam API
    if (i % 5 === 0) await new Promise(r => setTimeout(r, 500));
  }

  await batch.commit();
  console.log("\n🚀 SUCCÈS : 55 plantes importées sans doublons dans Firestore !");
}

main().catch(console.error);
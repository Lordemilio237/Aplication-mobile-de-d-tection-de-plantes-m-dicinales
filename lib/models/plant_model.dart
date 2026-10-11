// ============================================================
//  PlantaMed — Modèle Plant
// ============================================================

class Plant {
  final String?       firestoreId;
  final int?          id;
  final String        nomCommun;
  final String        nomScientifique;
  final String        famille;
  final String        description;
  final String        origine;
  final List<String>  vertusTherapeutiques;
  final List<String>  partiesUtilisees;
  final List<String>  modesUtilisation;
  final List<String>  maladiesTraitees;
  final List<String>  precautions;
  final String        posologie;
  final String        imageUrl;
  final String        imageAsset;
  final bool          estFavori;
  final String        categorie;
  final String        niveauDanger; // 'sûr' | 'modéré' | 'attention'
  final String?       videoUrl;
  final int           popularite;
  final List<String>  tags;

  Plant({
    this.firestoreId,
    this.id,
    required this.nomCommun,
    required this.nomScientifique,
    required this.famille,
    required this.description,
    required this.origine,
    required this.vertusTherapeutiques,
    required this.partiesUtilisees,
    required this.modesUtilisation,
    required this.maladiesTraitees,
    required this.precautions,
    required this.posologie,
    this.imageUrl     = '',
    this.imageAsset   = '',
    this.estFavori    = false,
    required this.categorie,
    this.niveauDanger = 'sûr',
    this.videoUrl,
    this.popularite   = 0,
    this.tags         = const [],
  });

  // ── Depuis Firestore ───────────────────────────────────────
  factory Plant.fromFirestore(Map<String, dynamic> data, String docId) {
    return Plant(
      firestoreId          : docId,
      nomCommun            : data['nom_commun']              ?? '',
      nomScientifique      : data['nom_scientifique']        ?? '',
      famille              : data['famille']                 ?? '',
      description          : data['description']             ?? '',
      origine              : data['origine']                 ?? '',
      vertusTherapeutiques : _toList(data['vertus_therapeutiques']),
      partiesUtilisees     : _toList(data['parties_utilisees']),
      modesUtilisation     : _toList(data['modes_utilisation']),
      maladiesTraitees     : _toList(data['maladies_traitees']),
      precautions          : _toList(data['precautions']),
      posologie            : data['posologie']               ?? '',
      imageUrl             : data['image_url']               ?? '',
      imageAsset           : data['image_asset']             ?? '',
      estFavori            : data['est_favori']              == true,
      categorie            : data['categorie']               ?? '',
      niveauDanger         : data['niveau_danger']           ?? 'sûr',
      videoUrl             : data['video_url'],
      popularite           : (data['popularite'] as num?)?.toInt() ?? 0,
      tags                 : _toList(data['tags']),
    );
  }

  // ── Vers Firestore ─────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'nom_commun'            : nomCommun,
    'nom_scientifique'      : nomScientifique,
    'famille'               : famille,
    'description'           : description,
    'origine'               : origine,
    'vertus_therapeutiques' : vertusTherapeutiques,
    'parties_utilisees'     : partiesUtilisees,
    'modes_utilisation'     : modesUtilisation,
    'maladies_traitees'     : maladiesTraitees,
    'precautions'           : precautions,
    'posologie'             : posologie,
    'image_url'             : imageUrl,
    'image_asset'           : imageAsset,
    'est_favori'            : estFavori,
    'categorie'             : categorie,
    'niveau_danger'         : niveauDanger,
    'video_url'             : videoUrl,
    'popularite'            : popularite,
    'tags'                  : tags,
  };

  // ── Depuis SQLite ──────────────────────────────────────────
  factory Plant.fromMap(Map<String, dynamic> map) => Plant(
    id                   : map['id'],
    nomCommun            : map['nom_commun']              ?? '',
    nomScientifique      : map['nom_scientifique']        ?? '',
    famille              : map['famille']                 ?? '',
    description          : map['description']             ?? '',
    origine              : map['origine']                 ?? '',
    vertusTherapeutiques : _splitPipe(map['vertus_therapeutiques']),
    partiesUtilisees     : _splitPipe(map['parties_utilisees']),
    modesUtilisation     : _splitPipe(map['modes_utilisation']),
    maladiesTraitees     : _splitPipe(map['maladies_traitees']),
    precautions          : _splitPipe(map['precautions']),
    posologie            : map['posologie']               ?? '',
    imageUrl             : map['image_url']               ?? '',
    imageAsset           : map['image_asset']             ?? '',
    estFavori            : map['est_favori']              == 1,
    categorie            : map['categorie']               ?? '',
    niveauDanger         : map['niveau_danger']           ?? 'sûr',
    videoUrl             : map['video_url'],
    popularite           : map['popularite']              ?? 0,
    tags                 : _splitPipe(map['tags']),
  );

  Map<String, dynamic> toMap() => {
    'id'                    : id,
    'nom_commun'            : nomCommun,
    'nom_scientifique'      : nomScientifique,
    'famille'               : famille,
    'description'           : description,
    'origine'               : origine,
    'vertus_therapeutiques' : vertusTherapeutiques.join('|'),
    'parties_utilisees'     : partiesUtilisees.join('|'),
    'modes_utilisation'     : modesUtilisation.join('|'),
    'maladies_traitees'     : maladiesTraitees.join('|'),
    'precautions'           : precautions.join('|'),
    'posologie'             : posologie,
    'image_url'             : imageUrl,
    'image_asset'           : imageAsset,
    'est_favori'            : estFavori ? 1 : 0,
    'categorie'             : categorie,
    'niveau_danger'         : niveauDanger,
    'video_url'             : videoUrl,
    'popularite'            : popularite,
    'tags'                  : tags.join('|'),
  };

  // ── Helpers ────────────────────────────────────────────────
  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) return _splitPipe(v);
    return [];
  }

  static List<String> _splitPipe(dynamic v) =>
      (v as String? ?? '').split('|').where((e) => e.isNotEmpty).toList();

  Plant copyWith({bool? estFavori}) => Plant(
    firestoreId          : firestoreId,
    id                   : id,
    nomCommun            : nomCommun,
    nomScientifique      : nomScientifique,
    famille              : famille,
    description          : description,
    origine              : origine,
    vertusTherapeutiques : vertusTherapeutiques,
    partiesUtilisees     : partiesUtilisees,
    modesUtilisation     : modesUtilisation,
    maladiesTraitees     : maladiesTraitees,
    precautions          : precautions,
    posologie            : posologie,
    imageUrl             : imageUrl,
    imageAsset           : imageAsset,
    estFavori            : estFavori ?? this.estFavori,
    categorie            : categorie,
    niveauDanger         : niveauDanger,
    videoUrl             : videoUrl,
    popularite           : popularite,
    tags                 : tags,
  );

  // ── Utilitaires UI ─────────────────────────────────────────
  String get niveauDangerEmoji {
    switch (niveauDanger) {
      case 'sûr'      : return '✅';
      case 'modéré'   : return '⚠️';
      case 'attention': return '🚨';
      default         : return '✅';
    }
  }

  @override
  String toString() => 'Plant($firestoreId — $nomCommun)';
}

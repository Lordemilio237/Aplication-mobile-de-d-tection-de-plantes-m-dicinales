import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/identification_result.dart';
import '../services/tflite.dart';
import '../services/plant_recognition_service.dart';
import 'plant_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  XFile?             _imageFile;
  bool               _isAnalyzing = false;
  bool               _modelLoaded = false;
  bool               _modelLoadError = false;
  String             _modelErrorMessage = '';
  RecognitionResult? _result;
  String             _selectedOrgan = 'auto';
  String             _statusMessage = '';

  final ImagePicker             _picker        = ImagePicker();
  final TFLiteService           _tfliteService = TFLiteService();
  final PlantRecognitionService _plantNetService = PlantRecognitionService();

  @override
  void initState() {
    super.initState();
    // Initialiser le modèle TFLite au démarrage de manière asynchrone
    if (!kIsWeb) {
      _initializeModel();
    } else {
      setState(() => _modelLoaded = true);
    }
  }

  // Initialiser le modèle TFLite avec gestion des erreurs
  Future<void> _initializeModel() async {
    try {
      await _tfliteService.loadModel();
      if (mounted) {
        setState(() {
          _modelLoaded = true;
          _modelLoadError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelLoaded = false;
          _modelLoadError = true;
          _modelErrorMessage = 'Erreur chargement IA: $e';
        });
      }
      debugPrint('Erreur initialisation modèle : $e');
    }
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  // ── Galerie ────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() { _imageFile = picked; _result = null; });
      }
    } catch (e) {
      _showError('Erreur galerie : $e');
    }
  }

  // ── Caméra ────────────────────────────────────────────
  Future<void> _takePhoto() async {
    if (kIsWeb) {
      _showError('Caméra indisponible sur Web. Utilise la Galerie.');
      return;
    }
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (picked != null) {
        setState(() { _imageFile = picked; _result = null; });
      }
    } catch (e) {
      _showError('Erreur caméra : $e');
    }
  }

  // ── Analyse ───────────────────────────────────────────
  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    
    // Vérifier que le modèle est prêt
    if (!kIsWeb && !_modelLoaded) {
      _showError('⏳ Le modèle IA est en cours de chargement. Veuillez attendre...');
      return;
    }
    
    setState(() { _isAnalyzing = true; _statusMessage = '🔍 Analyse en cours...'; });

    try {
      RecognitionResult result;

      if (kIsWeb) {
        // Sur Web → utiliser Pl@ntNet API
        setState(() => _statusMessage = '🌐 Appel Pl@ntNet API...');
        result = await _plantNetService.recognizeAndGetMedicinalInfo(
          File(_imageFile!.path),
          organ: _selectedOrgan,
        );
      } else {
        // Sur Mobile → utiliser TFLite local (hors-ligne)
        setState(() => _statusMessage = '🤖 Reconnaissance locale...');
        result = await _tfliteService.recognizePlant(File(_imageFile!.path));

        // Si confiance faible → fallback Pl@ntNet
        if (!result.isPlant && result.confidence < 0.6) {
          setState(() => _statusMessage = '🌐 Vérification Pl@ntNet...');
          try {
            result = await _plantNetService.recognizeAndGetMedicinalInfo(
              File(_imageFile!.path),
              organ: _selectedOrgan,
            );
          } catch (_) {
            // Garder le résultat TFLite si Pl@ntNet échoue
          }
        }
      }

      setState(() { _result = result; _isAnalyzing = false; _statusMessage = ''; });

    } catch (e) {
      setState(() { _isAnalyzing = false; _statusMessage = ''; });
      _showError('Erreur analyse : $e');
    }
  }

  void _reset() => setState(() {
    _imageFile = null;
    _result    = null;
    _statusMessage = '';
  });

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('📷 Scanner une plante',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_imageFile != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Indicateur chargement modèle ─────────────
          if (!kIsWeb && !_modelLoaded && !_modelLoadError)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9800)),
              ),
              child: const Column(children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '⏳ Initialisation du modèle IA...',
                  style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'L\'application fonctionne en ligne et hors ligne.\nLe modèle se configure pour la première utilisation.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFF6F00)),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),

          // ── Erreur chargement modèle ────────────────
          if (!kIsWeb && _modelLoadError)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF44336)),
              ),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.error, color: Color(0xFFC62828)),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Erreur chargement IA',
                    style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                  )),
                ]),
                const SizedBox(height: 8),
                Text(
                  _modelErrorMessage,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _initializeModel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                  ),
                  child: const Text('Réessayer'),
                ),
              ]),
            ),

          // ── Info Web ────────────────────────────────
          if (kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Sur navigateur : utilise la Galerie. '
                  'La reconnaissance IA locale fonctionne sur Android.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                )),
              ]),
            ),

          // ── Badge modèle ────────────────────────────
          if (!kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.memory, color: Color(0xFF2E7D32), size: 16),
                  SizedBox(width: 6),
                  Text('MobileNetV2 — Reconnaissance hors-ligne',
                      style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // ── Zone photo ──────────────────────────────
          if (_imageFile == null)
            _PhotoPrompt(onCamera: _takePhoto, onGallery: _pickFromGallery)
          else
            _PhotoPreview(imageFile: _imageFile!),

          const SizedBox(height: 16),

          // ── Sélecteur organe ────────────────────────
          if (_imageFile == null && kIsWeb)
            _OrganSelector(
              selected: _selectedOrgan,
              onChanged: (v) => setState(() => _selectedOrgan = v),
            ),

          const SizedBox(height: 16),

          // ── Boutons action ──────────────────────────
          if (_imageFile != null && !_isAnalyzing && _result == null)
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (kIsWeb || _modelLoaded) ? _analyzeImage : null,
                  icon: const Icon(Icons.biotech),
                  label: Text(kIsWeb
                      ? 'Analyser avec Pl@ntNet'
                      : _modelLoaded
                        ? 'Analyser avec IA locale'
                        : 'Chargement modèle...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (kIsWeb || _modelLoaded) ? const Color(0xFF2E7D32) : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.close),
              ),
            ]),

          // ── Chargement ──────────────────────────────
          if (_isAnalyzing)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                const SizedBox(height: 16),
                const Text('Analyse en cours...',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_statusMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  kIsWeb
                      ? 'Powered by Pl@ntNet 🌿'
                      : 'MobileNetV2_130_224 🤖',
                  style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ]),
            ),

          // ── Résultat ────────────────────────────────
          if (_result != null)
            _ResultCard(result: _result!, onReset: _reset),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  WIDGETS
// ════════════════════════════════════════════════════════

class _PhotoPrompt extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PhotoPrompt({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.3), width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.camera_alt, size: 70, color: Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        const Text('Photographier une plante',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Feuille, fleur, fruit ou écorce',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Caméra'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galerie'),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32))),
          ),
        ]),
      ]),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final XFile imageFile;
  const _PhotoPreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: kIsWeb
          ? Image.network(imageFile.path,
              width: double.infinity, height: 280, fit: BoxFit.cover)
          : Image.file(File(imageFile.path),
              width: double.infinity, height: 280, fit: BoxFit.cover),
    );
  }
}

class _OrganSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _OrganSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final organs = [
      {'value': 'auto',   'label': '🔍 Auto'},
      {'value': 'leaf',   'label': '🍃 Feuille'},
      {'value': 'flower', 'label': '🌸 Fleur'},
      {'value': 'fruit',  'label': '🍎 Fruit'},
      {'value': 'bark',   'label': '🌳 Écorce'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Partie à photographier :',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: organs.map((o) {
          final isSel = selected == o['value'];
          return GestureDetector(
            onTap: () => onChanged(o['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Text(o['label']!,
                  style: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  )),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final RecognitionResult result;
  final VoidCallback onReset;
  const _ResultCard({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final lines           = result.message.split('\n');
    final nomCommun       = lines.isNotEmpty ? lines[0] : '';
    final nomScientifique = lines.length > 1  ? lines[1] : '';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Statut + Nom ──────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(result.statusEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                result.isMedicinal
                    ? 'Plante médicinale identifiée'
                    : result.isPlant
                        ? 'Plante identifiée'
                        : 'Non reconnu',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(nomCommun,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (nomScientifique.isNotEmpty)
                Text(nomScientifique,
                    style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey)),
            ]),
          ),
        ]),

        const Divider(height: 24),

        // ── Barre confiance ───────────────────────────
        if (result.confidence > 0) ...[
          Row(children: [
            const Text('Confiance : ',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${(result.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: result.confidence > 0.7 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.confidence,
              backgroundColor: Colors.grey.shade200,
              color: result.confidence > 0.7 ? Colors.green : Colors.orange,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Bouton fiche médicinale ───────────────────
        if (result.isMedicinal && result.medicinalPlant != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      PlantDetailScreen(plant: result.medicinalPlant!))),
              icon: const Icon(Icons.eco),
              label: const Text('Voir les vertus médicinales'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

        // ── Message plante non médicinale ─────────────
        if (result.isPlant && !result.isMedicinal)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Cette plante n\'est pas dans notre base médicinale.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              )),
            ]),
          ),

        const SizedBox(height: 8),

        // ── Bouton recommencer ────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Scanner une autre plante'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PlantNetService {
  // Inscris-toi sur https://my.plantnet.org/ pour avoir ta clé
  final String _apiKey = "2b10VB2iEREG4uJ34Ltjrn1u"; 
  final String _baseUrl = "https://my-api.plantnet.org/v2/identify/all";

  Future<Map<String, dynamic>?> identifierPlante(File imageFile) async {
    try {
      var uri = Uri.parse("$_baseUrl?api-key=$_apiKey");
      var request = http.MultipartRequest("POST", uri);

      // Préparation du fichier image
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      var multipartFile = http.MultipartFile(
        'images',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);
      request.fields['organs'] = 'leaf'; // Précise l'organe pour plus de précision

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // On récupère le meilleur résultat
        var topResult = data['results'][0];
        return {
          'scientificName': topResult['species']['scientificNameWithoutAuthor'],
          'commonName': topResult['species']['commonNames']?[0] ?? "Inconnu",
          'score': topResult['score'],
        };
      }
      return null;
    } catch (e) {
      print("Erreur PlantNet: $e");
      return null;
    }
  }
}
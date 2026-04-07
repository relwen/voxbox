import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/services/api_response.dart';

class PartitionService {
  static const String _localPartitionsKey = 'local_partitions';
  static const String _lastSyncKey = 'last_partitions_sync';

  // Récupérer les partitions depuis le stockage local
  // Exclut les partitions liées aux messes (rubrique_section_id != null)
  static Future<List<Partition>> getLocalPartitions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? partitionsJson = prefs.getString(_localPartitionsKey);

    if (partitionsJson != null) {
      List<dynamic> partitionsList = jsonDecode(partitionsJson);
      List<Partition> partitions = partitionsList.map((json) => Partition.fromJson(json)).toList();
      // Filtrer les partitions liées aux messes
      return partitions.where((p) => p.rubriqueSectionId == null).toList();
    }
    return [];
  }

  // Sauvegarder les partitions localement
  static Future<void> saveLocalPartitions(List<Partition> partitions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String partitionsJson = jsonEncode(partitions.map((partition) => partition.toJson()).toList());
    await prefs.setString(_localPartitionsKey, partitionsJson);
  }

  // Récupérer les partitions depuis le serveur (pour la synchronisation)
  static Future<ApiResponse> getPartitionsFromServer() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      final response = await http.get(
        Uri.parse(AppConstance.partitionsURL),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          List<dynamic> serverPartitions = jsonDecode(response.body)['data'];
          List<Partition> partitions = serverPartitions.map((p) => Partition.fromJson(p)).toList();
          
          // Filtrer les partitions liées aux messes (rubrique_section_id != null)
          // Ces partitions ne doivent pas apparaître dans la liste des créations
          partitions = partitions.where((p) => p.rubriqueSectionId == null).toList();
          
          // Vérifier les fichiers téléchargés
          for (var partition in partitions) {
            await _checkDownloadedFiles(partition);
          }
          
          apiResponse.data = partitions;
          apiResponse.error = null;
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur lors de la récupération des partitions';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la récupération des partitions: $e';
    }
    return apiResponse;
  }

  // Vérifier les fichiers téléchargés pour une partition
  static Future<void> _checkDownloadedFiles(Partition partition) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String partitionsDir = '${appDocDir.path}/partitions';

      // Vérifier le fichier audio
      if (partition.audioPath != null) {
        String audioFilename = partition.audioPath!.split('/').last;
        String localAudioPath = '$partitionsDir/audio/$audioFilename';
        File localAudioFile = File(localAudioPath);
        
        if (await localAudioFile.exists()) {
          partition.localAudioPath = localAudioPath;
        }
      }

      // Vérifier le fichier PDF
      if (partition.pdfPath != null) {
        String pdfFilename = partition.pdfPath!.split('/').last;
        String localPdfPath = '$partitionsDir/pdf/$pdfFilename';
        File localPdfFile = File(localPdfPath);
        
        if (await localPdfFile.exists()) {
          partition.localPdfPath = localPdfPath;
        }
      }

      // Vérifier l'image
      if (partition.imagePath != null) {
        String imageFilename = partition.imagePath!.split('/').last;
        String localImagePath = '$partitionsDir/images/$imageFilename';
        File localImageFile = File(localImagePath);
        
        if (await localImageFile.exists()) {
          partition.localImagePath = localImagePath;
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification des fichiers téléchargés: $e');
    }
  }

  // Synchroniser les partitions avec le serveur
  static Future<ApiResponse> syncPartitions() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      String? lastSync = prefs.getString(_lastSyncKey);
      String syncUrl = '${AppConstance.partitionsURL}/sync';
      if (lastSync != null) {
        syncUrl += '?last_sync=$lastSync';
      }

      final response = await http.get(
        Uri.parse(syncUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          List<dynamic> serverPartitions = jsonDecode(response.body)['data'];
          List<Partition> newPartitions = serverPartitions.map((p) => Partition.fromJson(p)).toList();

          // Filtrer les partitions liées aux messes (rubrique_section_id != null)
          newPartitions = newPartitions.where((p) => p.rubriqueSectionId == null).toList();

          List<Partition> localPartitions = await getLocalPartitions();
          // Filtrer aussi les partitions locales liées aux messes
          localPartitions = localPartitions.where((p) => p.rubriqueSectionId == null).toList();
          
          Map<int, Partition> localMap = {for (var p in localPartitions) p.id: p};

          for (var newPartition in newPartitions) {
            localMap[newPartition.id] = newPartition;
          }

          List<Partition> updatedPartitions = localMap.values.toList();

          // Vérifier les fichiers téléchargés
          for (var partition in updatedPartitions) {
            await _checkDownloadedFiles(partition);
          }

          await saveLocalPartitions(updatedPartitions);
          await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

          apiResponse.data = updatedPartitions;
          apiResponse.error = null;
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur lors de la synchronisation';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la synchronisation: $e';
    }
    return apiResponse;
  }

  // Récupérer les partitions (avec option de rafraîchissement forcé)
  static Future<ApiResponse> getPartitions({bool forceRefresh = false}) async {
    ApiResponse apiResponse = ApiResponse();
    List<Partition> localPartitions = await getLocalPartitions();

    if (localPartitions.isNotEmpty && !forceRefresh) {
      apiResponse.data = localPartitions;
      apiResponse.error = null;
      return apiResponse;
    }

    // Tenter de synchroniser si connecté ou si rafraîchissement forcé
    try {
      var syncResponse = await syncPartitions();
      if (syncResponse.error == null) {
        apiResponse.data = syncResponse.data;
        apiResponse.error = null;
      } else {
        // Si la synchronisation échoue, retourner les données locales si disponibles
        if (localPartitions.isNotEmpty) {
          apiResponse.data = localPartitions;
          apiResponse.error = syncResponse.error; // Indiquer l'erreur de sync
        } else {
          apiResponse.error = syncResponse.error;
        }
      }
    } catch (e) {
      // En cas d'erreur de connexion, retourner les données locales
      if (localPartitions.isNotEmpty) {
        apiResponse.data = localPartitions;
        apiResponse.error = 'Erreur de connexion, affichage des données locales.';
      } else {
        apiResponse.error = 'Erreur de connexion: $e';
      }
    }
    return apiResponse;
  }

  // Créer une nouvelle partition
  static Future<ApiResponse> createPartition({
    required String title,
    String? description,
    required int categoryId,
    required int choraleId,
    String? audioFilePath,
    String? pdfFilePath,
    String? imageFilePath,
    int? rubriqueSectionId,
    int? pupitreId,
    String? messePart, // Nom de la partie de messe (ex: "Kyrié", "Sanctus")
    String? messeSubPart, // Sous-partie optionnelle
  }) async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      // Créer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstance.partitionsURL),
      );

      // Ajouter les headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Ajouter les champs
      request.fields['title'] = title;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      request.fields['category_id'] = categoryId.toString();
      request.fields['chorale_id'] = choraleId.toString();
      if (rubriqueSectionId != null) {
        request.fields['rubrique_section_id'] = rubriqueSectionId.toString();
      }
      if (pupitreId != null) {
        request.fields['pupitre_id'] = pupitreId.toString();
      }
      
      // Ajouter messe_part au format JSON attendu par le backend
      if (messePart != null) {
        final messePartJson = {
          'part': messePart,
          'subPart': messeSubPart,
        };
        request.fields['messe_part'] = jsonEncode(messePartJson);
        print('📋 messe_part: ${request.fields['messe_part']}');
      }

      print('📤 Champs envoyés:');
      print('  - title: $title');
      print('  - category_id: ${categoryId.toString()}');
      print('  - chorale_id: ${choraleId.toString()}');
      print('  - rubrique_section_id: ${rubriqueSectionId?.toString()}');
      print('  - pupitre_id: ${pupitreId?.toString()}');
      print('  - messe_part: ${messePart != null ? request.fields['messe_part'] : "absent"}');
      print('  - audio_file: ${audioFilePath != null ? "présent" : "absent"}');
      print('  - pdf_file: ${pdfFilePath != null ? "présent" : "absent"}');
      print('  - image_file: ${imageFilePath != null ? "présent" : "absent"}');

      // Ajouter les fichiers dans le champ 'files[]' comme attendu par le backend
      // Le backend attend tous les fichiers dans un seul champ 'files[]'
      List<File> filesToUpload = [];
      
      if (audioFilePath != null) {
        final audioFileObj = File(audioFilePath);
        if (await audioFileObj.exists()) {
          final fileSize = await audioFileObj.length();
          final fileName = audioFilePath.split('/').last;
          print('📁 Fichier audio trouvé: $audioFilePath');
          print('   - Nom: $fileName');
          print('   - Taille: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
          filesToUpload.add(audioFileObj);
        } else {
          print('❌ Fichier audio introuvable: $audioFilePath');
          apiResponse.error = 'Fichier audio introuvable: $audioFilePath';
          return apiResponse;
        }
      }

      if (pdfFilePath != null) {
        final pdfFileObj = File(pdfFilePath);
        if (await pdfFileObj.exists()) {
          final fileSize = await pdfFileObj.length();
          final fileName = pdfFilePath.split('/').last;
          print('📁 Fichier PDF trouvé: $pdfFilePath');
          print('   - Nom: $fileName');
          print('   - Taille: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
          filesToUpload.add(pdfFileObj);
        } else {
          print('❌ Fichier PDF introuvable: $pdfFilePath');
        }
      }

      if (imageFilePath != null) {
        final imageFileObj = File(imageFilePath);
        if (await imageFileObj.exists()) {
          final fileSize = await imageFileObj.length();
          final fileName = imageFilePath.split('/').last;
          print('📁 Fichier image trouvé: $imageFilePath');
          print('   - Nom: $fileName');
          print('   - Taille: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
          filesToUpload.add(imageFileObj);
        } else {
          print('❌ Fichier image introuvable: $imageFilePath');
        }
      }

      // Ajouter tous les fichiers dans le champ 'files[]' comme attendu par le backend
      for (var file in filesToUpload) {
        final fileName = file.path.split('/').last;
        var multipartFile = await http.MultipartFile.fromPath(
          'files[]', // Le backend attend 'files[]' pour un tableau de fichiers
          file.path,
          filename: fileName,
        );
        request.files.add(multipartFile);
        print('✅ Fichier ajouté à la requête multipart (field: files[], filename: $fileName)');
      }

      print('📦 Total fichiers dans la requête: ${request.files.length}');
      for (var file in request.files) {
        print('   - ${file.field}: ${file.filename ?? "sans nom"} (${file.length} bytes)');
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Réponse création partition - Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      switch (response.statusCode) {
        case 201:
        case 200:
          try {
          var responseData = jsonDecode(response.body);
            print('📦 Données parsées: $responseData');
            if (responseData['success'] == true && responseData['data'] != null) {
              try {
                final partitionData = responseData['data'];
                print('📋 Données de la partition créée:');
                print('   - ID: ${partitionData['id']}');
                print('   - Titre: ${partitionData['title']}');
                print('   - audio_path: ${partitionData['audio_path']}');
                print('   - pdf_path: ${partitionData['pdf_path']}');
                print('   - image_path: ${partitionData['image_path']}');
                print('   - audio_files: ${partitionData['audio_files']}');
                print('   - files: ${partitionData['files']}');
                
                apiResponse.data = Partition.fromJson(partitionData);
            apiResponse.error = null;
                print('✅ Partition créée avec succès: ${apiResponse.data?.id}');
                
                // Vérifier si les fichiers ont été sauvegardés
                if (audioFilePath != null) {
                  if (apiResponse.data?.audioPath == null || apiResponse.data?.audioPath!.isEmpty == true) {
                    print('⚠️ ATTENTION: Le fichier audio n\'a pas été sauvegardé sur le serveur!');
                    print('   Fichier envoyé: $audioFilePath');
                    print('   Chemin retourné: ${apiResponse.data?.audioPath}');
                  } else {
                    print('✅ Fichier audio sauvegardé: ${apiResponse.data?.audioPath}');
                  }
                }
              } catch (e, stackTrace) {
                print('❌ Erreur lors de la conversion Partition.fromJson: $e');
                print('📋 Stack trace: $stackTrace');
                print('📋 Données reçues: ${responseData['data']}');
                apiResponse.error = 'Erreur de conversion: $e';
              }
          } else {
            apiResponse.error = responseData['message'] ?? 'Erreur lors de la création';
              print('⚠️ Réponse sans succès: ${responseData['message']}');
            }
          } catch (e, stackTrace) {
            print('❌ Erreur lors du parsing JSON: $e');
            print('📋 Stack trace: $stackTrace');
            apiResponse.error = 'Erreur de parsing: $e';
          }
          break;
        case 422:
          var errors = jsonDecode(response.body)['errors'];
          apiResponse.error = errors[errors.keys.elementAt(0)][0];
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur lors de la création';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la création: $e';
    }
    return apiResponse;
  }

  // Télécharger un fichier de partition
  static Future<bool> downloadFile(Partition partition, String fileType) async {
    String? fileUrl;
    String? localPath;
    String? filename;

    switch (fileType) {
      case 'audio':
        if (partition.audioUrl == null) return false;
        fileUrl = partition.audioUrl;
        filename = partition.audioPath!.split('/').last;
        localPath = '${await _getPartitionsDir()}/audio/$filename';
        break;
      case 'pdf':
        if (partition.pdfUrl == null) return false;
        fileUrl = partition.pdfUrl;
        filename = partition.pdfPath!.split('/').last;
        localPath = '${await _getPartitionsDir()}/pdf/$filename';
        break;
      case 'image':
        if (partition.imageUrl == null) return false;
        fileUrl = partition.imageUrl;
        filename = partition.imagePath!.split('/').last;
        localPath = '${await _getPartitionsDir()}/images/$filename';
        break;
      default:
        return false;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print('Token non disponible pour le téléchargement.');
        return false;
      }

      // Créer le répertoire si nécessaire
      await Directory(File(localPath).parent.path).create(recursive: true);

      final response = await http.get(
        Uri.parse(fileUrl!),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await File(localPath).writeAsBytes(response.bodyBytes);
        
        // Mettre à jour la partition
        switch (fileType) {
          case 'audio':
            partition.localAudioPath = localPath;
            break;
          case 'pdf':
            partition.localPdfPath = localPath;
            break;
          case 'image':
            partition.localImagePath = localPath;
            break;
        }

        // Mettre à jour la partition dans le stockage local
        List<Partition> localPartitions = await getLocalPartitions();
        int index = localPartitions.indexWhere((p) => p.id == partition.id);
        if (index != -1) {
          localPartitions[index] = partition;
          await saveLocalPartitions(localPartitions);
        }
        return true;
      } else {
        print('Erreur de téléchargement: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur lors du téléchargement du fichier: $e');
      return false;
    }
  }

  // Obtenir le répertoire des partitions
  static Future<String> _getPartitionsDir() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/partitions';
  }

  // Supprimer un fichier téléchargé
  static Future<bool> deleteDownloadedFile(Partition partition, String fileType) async {
    String? localPath;

    switch (fileType) {
      case 'audio':
        localPath = partition.localAudioPath;
        break;
      case 'pdf':
        localPath = partition.localPdfPath;
        break;
      case 'image':
        localPath = partition.localImagePath;
        break;
      default:
        return false;
    }

    if (localPath == null) return false;

    try {
      File localFile = File(localPath);
      if (await localFile.exists()) {
        await localFile.delete();
        
        // Mettre à jour la partition
        switch (fileType) {
          case 'audio':
            partition.localAudioPath = null;
            break;
          case 'pdf':
            partition.localPdfPath = null;
            break;
          case 'image':
            partition.localImagePath = null;
            break;
        }

        // Mettre à jour la partition dans le stockage local
        List<Partition> localPartitions = await getLocalPartitions();
        int index = localPartitions.indexWhere((p) => p.id == partition.id);
        if (index != -1) {
          localPartitions[index] = partition;
          await saveLocalPartitions(localPartitions);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
      return false;
    }
  }
}

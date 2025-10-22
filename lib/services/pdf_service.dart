import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:voxbox/functions/appconstants.dart';

class PdfService {
  /// Ouvre un PDF avec plusieurs méthodes de fallback
  static Future<void> openPdf(String filePath, BuildContext context) async {
    try {
      // Normaliser le chemin du fichier
      final normalizedPath = _normalizeFilePath(filePath);
      
      // Méthode 1: Essayer d'ouvrir avec open_file (plus fiable)
      if (normalizedPath.startsWith('/')) {
        await _openLocalPdf(normalizedPath, context);
      } else {
        await _openRemotePdf(normalizedPath, context);
      }
    } catch (e) {
      // Méthode 2: Fallback vers url_launcher
      await _fallbackOpenPdf(_normalizeFilePath(filePath), context);
    }
  }

  /// Normalise le chemin du fichier (ajoute la base URL si nécessaire)
  static String _normalizeFilePath(String filePath) {
    // Si c'est déjà un chemin local complet
    if (filePath.startsWith('/')) {
      return filePath;
    }
    
    // Si c'est déjà une URL complète
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    
    // Si c'est un chemin relatif, ajouter la base URL
    if (!filePath.startsWith('/') && !filePath.contains('://')) {
      // Nettoyer le chemin (enlever les slashes en début)
      final cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
      return '${AppConstance.baseURL}/$cleanPath';
    }
    
    return filePath;
  }

  /// Ouvre un PDF local avec open_file
  static Future<void> _openLocalPdf(String filePath, BuildContext context) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('Fichier PDF introuvable: $filePath');
    }

    final result = await OpenFile.open(filePath);
    
    if (result.type != ResultType.done) {
      throw Exception('Impossible d\'ouvrir le PDF: ${result.message}');
    }
  }

  /// Télécharge et ouvre un PDF distant
  static Future<void> _openRemotePdf(String url, BuildContext context) async {
    try {
      print('🔍 Tentative de téléchargement du PDF: $url');
      
      // Télécharger le PDF
      final response = await http.get(Uri.parse(url));
      
      print('📡 Réponse HTTP: ${response.statusCode}');
      print('📏 Taille du fichier: ${response.bodyBytes.length} bytes');
      
      if (response.statusCode != 200) {
        throw Exception('Erreur de téléchargement: ${response.statusCode} - ${response.reasonPhrase}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Le fichier téléchargé est vide');
      }

      // Sauvegarder temporairement
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(url);
      final filePath = path.join(directory.path, 'temp_$fileName');
      
      print('💾 Sauvegarde vers: $filePath');
      
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Vérifier que le fichier a été sauvegardé
      if (!await file.exists()) {
        throw Exception('Le fichier n\'a pas pu être sauvegardé');
      }

      final fileSize = await file.length();
      print('✅ Fichier sauvegardé: $fileSize bytes');

      // Ouvrir le fichier téléchargé
      await _openLocalPdf(filePath, context);
      
    } catch (e) {
      print('❌ Erreur lors du téléchargement: $e');
      throw Exception('Erreur lors du téléchargement du PDF: $e');
    }
  }

  /// Méthode de fallback avec url_launcher
  static Future<void> _fallbackOpenPdf(String filePath, BuildContext context) async {
    try {
      final normalizedPath = _normalizeFilePath(filePath);
      print('🔄 Fallback - Tentative d\'ouverture avec url_launcher: $normalizedPath');
      
      Uri uri;
      
      if (normalizedPath.startsWith('/')) {
        uri = Uri.file(normalizedPath);
        print('📁 URI fichier local: $uri');
      } else {
        uri = Uri.parse(normalizedPath);
        print('🌐 URI URL: $uri');
      }

      if (await canLaunchUrl(uri)) {
        print('✅ URL peut être lancée, tentative d\'ouverture...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🎉 PDF ouvert avec succès via url_launcher');
      } else {
        print('❌ URL ne peut pas être lancée');
        throw Exception('Aucune application disponible pour ouvrir les PDFs');
      }
    } catch (e) {
      print('❌ Erreur fallback: $e');
      throw Exception('Erreur lors de l\'ouverture du PDF: $e');
    }
  }

  /// Affiche un dialogue avec plusieurs options pour ouvrir le PDF
  static Future<void> showPdfOptions(String filePath, BuildContext context) async {
    final normalizedPath = _normalizeFilePath(filePath);
    print('📋 Affichage des options PDF pour: $normalizedPath');
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ouvrir le PDF',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Fichier: ${path.basename(normalizedPath)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Option 1: Ouvrir avec l'app par défaut
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.blue),
              title: const Text('Ouvrir avec l\'application par défaut'),
              onTap: () async {
                Navigator.pop(context);
                await openPdf(filePath, context);
              },
            ),
            
            // Option 2: Télécharger d'abord
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Télécharger puis ouvrir'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadAndOpenPdf(filePath, context);
              },
            ),
            
            // Option 3: Partager le fichier
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Partager le fichier'),
              onTap: () async {
                Navigator.pop(context);
                await _sharePdf(filePath, context);
              },
            ),
            
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  /// Télécharge le PDF et l'ouvre
  static Future<void> _downloadAndOpenPdf(String filePath, BuildContext context) async {
    try {
      final normalizedPath = _normalizeFilePath(filePath);
      print('📥 Téléchargement forcé du PDF: $normalizedPath');
      
      if (!normalizedPath.startsWith('/')) {
        // C'est une URL, télécharger d'abord
        await _openRemotePdf(normalizedPath, context);
      } else {
        // C'est un fichier local, copier vers le dossier de téléchargements
        final directory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${directory.path}/Downloads');
        
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        
        final fileName = path.basename(normalizedPath);
        final destinationFile = File('${downloadDir.path}/$fileName');
        
        await File(normalizedPath).copy(destinationFile.path);
        await _openLocalPdf(destinationFile.path, context);
      }
    } catch (e) {
      print('❌ Erreur lors du téléchargement forcé: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Partage le PDF
  static Future<void> _sharePdf(String filePath, BuildContext context) async {
    try {
      final normalizedPath = _normalizeFilePath(filePath);
      print('📤 Partage du PDF: $normalizedPath');
      
      if (normalizedPath.startsWith('/')) {
        // Fichier local
        final file = File(normalizedPath);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(normalizedPath)], text: 'Partage du PDF');
        } else {
          throw Exception('Fichier introuvable');
        }
      } else {
        // URL - télécharger d'abord puis partager
        final response = await http.get(Uri.parse(normalizedPath));
        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = path.basename(normalizedPath);
          final tempFile = File('${directory.path}/temp_$fileName');
          await tempFile.writeAsBytes(response.bodyBytes);
          
          await Share.shareXFiles([XFile(tempFile.path)], text: 'Partage du PDF');
          
          // Nettoyer le fichier temporaire
          await tempFile.delete();
        } else {
          throw Exception('Erreur de téléchargement: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du partage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Vérifie si un fichier PDF est valide
  static Future<bool> isValidPdf(String filePath) async {
    try {
      final normalizedPath = _normalizeFilePath(filePath);
      print('🔍 Validation du PDF: $normalizedPath');
      
      if (normalizedPath.startsWith('/')) {
        final file = File(normalizedPath);
        if (!await file.exists()) {
          print('❌ Fichier local introuvable');
          return false;
        }
        
        // Lire les premiers bytes pour vérifier le header PDF
        final bytes = await file.readAsBytes();
        final isValid = bytes.length > 4 && 
               String.fromCharCodes(bytes.take(4)) == '%PDF';
        print('📄 Fichier local valide: $isValid');
        return isValid;
      }
      
      // Pour les URLs, on assume qu'elles sont valides
      print('🌐 URL PDF - validation assumée valide');
      return true;
    } catch (e) {
      print('❌ Erreur de validation: $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/functions/appconstants.dart';

/// Écran de démonstration pour tester les différents types de toasts
/// Utile pour voir à quoi ressemblent les notifications avant de les utiliser
class ToastDemoScreen extends StatelessWidget {
  const ToastDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démonstration Toast'),
        backgroundColor: AppConstance.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Card(
              color: AppConstance.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 48,
                      color: AppConstance.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Testez les Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cliquez sur les boutons ci-dessous pour voir les différents types de notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Succès
            _buildSectionTitle('Succès', Icons.check_circle, Colors.green),
            _buildToastButton(
              context,
              'Toast de Succès Simple',
              Colors.green,
              () => ToastService.success(context, 'Opération réussie !'),
            ),
            _buildToastButton(
              context,
              'Succès avec Titre',
              Colors.green,
              () => ToastService.success(
                context,
                'Votre vocalise a été sauvegardée avec succès',
                title: 'Enregistré',
              ),
            ),
            _buildToastButton(
              context,
              'Succès Longue Durée',
              Colors.green,
              () => ToastService.success(
                context,
                'Cette notification reste affichée plus longtemps',
                duration: const Duration(seconds: 5),
              ),
            ),

            const SizedBox(height: 24),

            // Section Erreur
            _buildSectionTitle('Erreur', Icons.error, Colors.red),
            _buildToastButton(
              context,
              'Toast d\'Erreur Simple',
              Colors.red,
              () => ToastService.error(context, 'Une erreur est survenue'),
            ),
            _buildToastButton(
              context,
              'Erreur avec Titre',
              Colors.red,
              () => ToastService.error(
                context,
                'Impossible de se connecter au serveur',
                title: 'Erreur de connexion',
              ),
            ),
            _buildToastButton(
              context,
              'Erreur de Validation',
              Colors.red,
              () => ToastService.error(
                context,
                'Veuillez remplir tous les champs obligatoires',
                title: 'Formulaire invalide',
              ),
            ),

            const SizedBox(height: 24),

            // Section Avertissement
            _buildSectionTitle('Avertissement', Icons.warning, Colors.orange),
            _buildToastButton(
              context,
              'Toast d\'Avertissement',
              Colors.orange,
              () => ToastService.warning(context, 'Attention, cette action est irréversible'),
            ),
            _buildToastButton(
              context,
              'Avertissement avec Titre',
              Colors.orange,
              () => ToastService.warning(
                context,
                'Votre session expire dans 5 minutes',
                title: 'Session',
              ),
            ),
            _buildToastButton(
              context,
              'Champ Requis',
              Colors.orange,
              () => ToastService.warning(
                context,
                'Veuillez saisir votre numéro de téléphone',
              ),
            ),

            const SizedBox(height: 24),

            // Section Information
            _buildSectionTitle('Information', Icons.info, Colors.blue),
            _buildToastButton(
              context,
              'Toast d\'Information',
              Colors.blue,
              () => ToastService.info(context, 'Nouvelle mise à jour disponible'),
            ),
            _buildToastButton(
              context,
              'Info avec Titre',
              Colors.blue,
              () => ToastService.info(
                context,
                'La synchronisation s\'effectue automatiquement toutes les 30 minutes',
                title: 'Information',
              ),
            ),

            const SizedBox(height: 24),

            // Section Chargement
            _buildSectionTitle('Chargement', Icons.downloading, Colors.indigo),
            _buildToastButton(
              context,
              'Toast de Chargement',
              Colors.indigo,
              () async {
                final loadingToast = ToastService.loading(
                  context,
                  'Téléchargement en cours...',
                );

                // Simuler un téléchargement
                await Future.delayed(const Duration(seconds: 3));

                ToastService.dismiss(loadingToast);
                ToastService.success(context, 'Téléchargement terminé !');
              },
            ),
            _buildToastButton(
              context,
              'Chargement avec Titre',
              Colors.indigo,
              () async {
                final loadingToast = ToastService.loading(
                  context,
                  'Synchronisation des vocalises...',
                  title: 'Synchronisation',
                );

                await Future.delayed(const Duration(seconds: 2));

                ToastService.dismiss(loadingToast);
                ToastService.success(
                  context,
                  '15 vocalises synchronisées',
                  title: 'Terminé',
                );
              },
            ),

            const SizedBox(height: 24),

            // Section Personnalisé
            _buildSectionTitle('Personnalisé', Icons.palette, Colors.purple),
            _buildToastButton(
              context,
              'Toast Musical',
              Colors.purple,
              () => ToastService.custom(
                context,
                'Nouvelle vocalise disponible',
                title: 'Bibliothèque',
                icon: Icons.library_music,
                color: Colors.purple,
              ),
            ),
            _buildToastButton(
              context,
              'Toast Partition',
              Colors.teal,
              () => ToastService.custom(
                context,
                'Partition téléchargée',
                title: 'PDF',
                icon: Icons.picture_as_pdf,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 24),

            // Section Positions
            _buildSectionTitle('Positions', Icons.place, Colors.brown),
            _buildToastButton(
              context,
              'En haut à droite (défaut)',
              Colors.grey.shade700,
              () => ToastService.info(
                context,
                'Position par défaut',
                alignment: Alignment.topRight,
              ),
            ),
            _buildToastButton(
              context,
              'En haut au centre',
              Colors.grey.shade700,
              () => ToastService.info(
                context,
                'Centré en haut',
                alignment: Alignment.topCenter,
              ),
            ),
            _buildToastButton(
              context,
              'En haut à gauche',
              Colors.grey.shade700,
              () => ToastService.info(
                context,
                'À gauche en haut',
                alignment: Alignment.topLeft,
              ),
            ),
            _buildToastButton(
              context,
              'En bas à droite',
              Colors.grey.shade700,
              () => ToastService.info(
                context,
                'En bas à droite',
                alignment: Alignment.bottomRight,
              ),
            ),

            const SizedBox(height: 24),

            // Bouton pour tout fermer
            ElevatedButton.icon(
              onPressed: () => ToastService.dismissAll(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Fermer toutes les notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToastButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

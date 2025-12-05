import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/chant_de_messe.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({
    Key? key,
    required this.query,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Partition> partitionResults = [];
  List<Vocalise> vocaliseResults = [];
  List<Messe> messeResults = [];
  List<ChantDeMesse> chantResults = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // TODO: Implémenter les appels API pour la recherche
      // Pour l'instant, nous créons des résultats vides
      await Future.delayed(const Duration(seconds: 1)); // Simulation d'un appel API

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de la recherche: ${e.toString()}';
      });
    }
  }

  int get totalResults =>
      partitionResults.length +
      vocaliseResults.length +
      messeResults.length +
      chantResults.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppConstance.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résultats de recherche',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '"${widget.query}"',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState()
              : totalResults == 0
                  ? _buildEmptyState()
                  : _buildResults(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstance.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstance.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun élément ne correspond à "${widget.query}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestionItem('Vérifiez l\'orthographe'),
            _buildSuggestionItem('Essayez des mots-clés plus généraux'),
            _buildSuggestionItem('Essayez des mots-clés différents'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppConstance.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compteur de résultats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstance.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstance.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppConstance.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '$totalResults résultat${totalResults > 1 ? 's' : ''} trouvé${totalResults > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstance.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Résultats des partitions
          if (partitionResults.isNotEmpty) ...[
            _buildSectionTitle('Partitions', partitionResults.length),
            const SizedBox(height: 12),
            ...partitionResults.map((partition) => _buildPartitionCard(partition)),
            const SizedBox(height: 24),
          ],

          // Résultats des vocalises
          if (vocaliseResults.isNotEmpty) ...[
            _buildSectionTitle('Vocalises', vocaliseResults.length),
            const SizedBox(height: 12),
            ...vocaliseResults.map((vocalise) => _buildVocaliseCard(vocalise)),
            const SizedBox(height: 24),
          ],

          // Résultats des messes
          if (messeResults.isNotEmpty) ...[
            _buildSectionTitle('Messes', messeResults.length),
            const SizedBox(height: 12),
            ...messeResults.map((messe) => _buildMesseCard(messe)),
            const SizedBox(height: 24),
          ],

          // Résultats des chants
          if (chantResults.isNotEmpty) ...[
            _buildSectionTitle('Chants de Messe', chantResults.length),
            const SizedBox(height: 12),
            ...chantResults.map((chant) => _buildChantCard(chant)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppConstance.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartitionCard(Partition partition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppConstance.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: AppConstance.primary,
          ),
        ),
        title: Text(
          partition.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          partition.description ?? 'Aucune description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          // TODO: Naviguer vers les détails de la partition
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouverture de "${partition.title}"'),
              backgroundColor: AppConstance.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVocaliseCard(Vocalise vocalise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.orange,
          ),
        ),
        title: Text(
          vocalise.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${vocalise.voicePart} • ${vocalise.description ?? 'Aucune description'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          // TODO: Naviguer vers les détails de la vocalise
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouverture de "${vocalise.title}"'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMesseCard(Messe messe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.church_rounded,
            color: Colors.blue,
          ),
        ),
        title: Text(
          messe.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          messe.description ?? 'Aucune description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          // TODO: Naviguer vers les détails de la messe
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouverture de "${messe.nom}"'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChantCard(ChantDeMesse chant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.multitrack_audio_rounded,
            color: Colors.purple,
          ),
        ),
        title: Text(
          chant.titre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          chant.description ?? 'Aucune description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          // TODO: Naviguer vers les détails du chant
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouverture de "${chant.titre}"'),
              backgroundColor: Colors.purple,
            ),
          );
        },
      ),
    );
  }
}

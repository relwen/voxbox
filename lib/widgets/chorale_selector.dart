import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/services/chorale_service.dart';

class ChoraleSelector extends StatefulWidget {
  final Chorale? selectedChorale;
  final Function(Chorale?) onChoraleSelected;
  final String? label;
  final String? hint;

  const ChoraleSelector({
    super.key,
    this.selectedChorale,
    required this.onChoraleSelected,
    this.label,
    this.hint,
  });

  @override
  State<ChoraleSelector> createState() => _ChoraleSelectorState();
}

class _ChoraleSelectorState extends State<ChoraleSelector> {
  List<Chorale> _chorales = [];
  List<Chorale> _filteredChorales = [];
  bool _loading = false;
  bool _showDropdown = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    // Ne pas charger les chorales automatiquement - attendre une connexion
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showDropdown = _focusNode.hasFocus;
    });
    
    // Charger les chorales quand l'utilisateur clique sur le champ
    if (_focusNode.hasFocus && _chorales.isEmpty) {
      _loadChorales();
    }
  }

  void _onSearchChanged() {
    _filterChorales(_searchController.text);
  }

  void _filterChorales(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChorales = _chorales;
      } else {
        _filteredChorales = _chorales
            .where((chorale) =>
                chorale.nom.toLowerCase().contains(query.toLowerCase()) ||
                (chorale.ville?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  Future<void> _loadChorales() async {
    setState(() {
      _loading = true;
    });

    try {
      // L'API des chorales est accessible sans authentification
      print('🔄 Chargement des chorales depuis l\'API...');

      // Récupérer les chorales depuis la base de données
      print('🔄 Début du chargement des chorales...');
      final response = await ChoraleService.getChorales();
      print('📡 Réponse reçue: error=${response.error}, data=${response.data}');
      
      if (response.error == null && response.data != null) {
        setState(() {
          _chorales = response.data as List<Chorale>;
          _filteredChorales = response.data as List<Chorale>;
          _loading = false;
        });
        
        // Log pour debug
        print('✅ Chorales chargées depuis la BD: ${_chorales.length} chorales');
        for (var chorale in _chorales) {
          print('   - ${chorale.nom} (${chorale.ville})');
        }
      } else {
        // En cas d'erreur, afficher un message d'erreur
        print('❌ Erreur API: ${response.error}');
        
        setState(() {
          _chorales = [];
          _filteredChorales = [];
          _loading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des chorales: ${response.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'exception, afficher un message d'erreur
      print('❌ Exception lors du chargement: $e');
      
      setState(() {
        _chorales = [];
        _filteredChorales = [];
        _loading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _selectChorale(Chorale chorale) {
    widget.onChoraleSelected(chorale);
    _searchController.text = chorale.nom;
    _focusNode.unfocus();
    setState(() {
      _showDropdown = false;
    });
  }

  void _clearSelection() {
    widget.onChoraleSelected(null);
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _showDropdown = false;
    });
  }

  void _refreshChorales() {
    _loadChorales();
  }
  
  /// Méthode publique pour recharger les chorales après connexion
  void reloadChorales() {
    _loadChorales();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Container principal
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[50],
            border: Border.all(
              color: _focusNode.hasFocus ? AppConstance.primary : Colors.grey[200]!,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppConstance.primary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Champ de recherche
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Rechercher une chorale...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  suffixIcon: widget.selectedChorale != null
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: _clearSelection,
                        )
                      : Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _showDropdown = true;
                  });
                },
              ),

              // Dropdown avec les chorales
              if (_showDropdown) _buildDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          : _filteredChorales.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredChorales.length,
                  itemBuilder: (context, index) {
                    final chorale = _filteredChorales[index];
                    final isSelected = widget.selectedChorale?.id == chorale.id;

                    return InkWell(
                      onTap: () => _selectChorale(chorale),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppConstance.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // Icône de chorale
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppConstance.primary
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.group,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Informations de la chorale
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chorale.nom,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppConstance.primary
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  if (chorale.ville != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      chorale.ville!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Indicateur de sélection
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppConstance.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune chorale trouvée',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec un autre terme de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshChorales,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/pending_approval_screen.dart';
import 'package:http/http.dart' as http;

class CompleteProfileScreen extends StatefulWidget {
  final User user;

  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _choraleSearchController = TextEditingController();

  List<Chorale> _chorales = [];
  List<Chorale> _filteredChorales = [];
  Chorale? _selectedChorale;
  List<ChoralePupitre> _pupitres = [];
  ChoralePupitre? _selectedPupitre;
  bool _isLoading = false;
  bool _loadingChorales = true;
  bool _loadingPupitres = false;
  bool _showChoraleDropdown = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs si disponibles
    if (widget.user.name != null && widget.user.name!.isNotEmpty) {
      _nameController.text = widget.user.name!;
    }
    _loadChorales();
  }

  Future<void> _loadChorales() async {
    setState(() => _loadingChorales = true);

    try {
      // Récupérer le token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chorales'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          List<Chorale> chorales = (responseData['data'] as List)
              .map((json) => Chorale.fromJson(json))
              .toList();

          setState(() {
            _chorales = chorales;
            _filteredChorales = chorales;
            _loadingChorales = false;
            
            // Pré-sélectionner la chorale si l'utilisateur en a déjà une
            if (widget.user.choraleId != null && chorales.isNotEmpty) {
              try {
                _selectedChorale = chorales.firstWhere(
                  (c) => c.id == widget.user.choraleId,
                );
                if (_selectedChorale != null) {
                  _choraleSearchController.text = _selectedChorale!.nom;
                  // Charger les pupitres de la chorale pré-sélectionnée
                  _loadPupitres(_selectedChorale!.id);
                }
              } catch (e) {
                // Chorale non trouvée dans la liste
                print('Chorale ID ${widget.user.choraleId} non trouvée dans la liste');
              }
            }
          });
        } else {
          throw Exception(responseData['message'] ?? 'Erreur de chargement');
        }
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _loadingChorales = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des chorales: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadPupitres(int choraleId) async {
    setState(() {
      _loadingPupitres = true;
      _pupitres = [];
      _selectedPupitre = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chorales/$choraleId/pupitres'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          List<ChoralePupitre> pupitres = (responseData['data'] as List)
              .map((json) => ChoralePupitre.fromJson(json))
              .toList();

          setState(() {
            _pupitres = pupitres;
            _loadingPupitres = false;
            
            // Pré-sélectionner le pupitre si l'utilisateur en a déjà un
            if (widget.user.voicePart != null && widget.user.voicePart!.isNotEmpty) {
              try {
                _selectedPupitre = pupitres.firstWhere(
                  (p) => p.nom.toUpperCase() == widget.user.voicePart!.toUpperCase(),
                );
              } catch (e) {
                // Pupitre non trouvé dans la liste
                print('Pupitre ${widget.user.voicePart} non trouvé dans la liste');
              }
            }
          });
        } else {
          throw Exception(responseData['message'] ?? 'Erreur de chargement');
        }
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _loadingPupitres = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des pupitres: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChorale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une chorale'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPupitre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre pupitre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Récupérer le token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Mettre à jour le profil via l'API
      final requestBody = {
        'name': _nameController.text.trim(),
        'chorale_id': _selectedChorale!.id,
        'voice_part': _selectedPupitre!.nom,
      };
      
      print('📤 Envoi de la mise à jour du profil:');
      print('   - Chorale ID: ${requestBody['chorale_id']}');
      print('   - Voice Part: ${requestBody['voice_part']}');
      print('   - Name: ${requestBody['name']}');
      
      final response = await http.put(
        Uri.parse('${AppConstance.baseURL}/api/me'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Réponse du serveur (${response.statusCode}):');
      print('   ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Debug: Vérifier la structure de la réponse
          print('📋 Données utilisateur reçues:');
          print('   ${jsonEncode(responseData['user'])}');
          
          // Mettre à jour l'utilisateur en cache
          User updatedUser = User.fromJson(responseData['user']);
          updatedUser.profileComplete = responseData['profile_complete'] ?? false;
          updatedUser.profileIncomplete = responseData['profile_incomplete'] ?? true;
          
          // Debug: Vérifier que chorale_id est bien présent
          print('✅ Profil mis à jour:');
          print('   - Chorale ID: ${updatedUser.choraleId}');
          print('   - Voice Part: ${updatedUser.voicePart}');
          print('   - Name: ${updatedUser.name}');
          print('   - Status: ${updatedUser.status}');
          print('   - Profile Complete: ${updatedUser.profileComplete}');
          print('   - Profile Incomplete: ${updatedUser.profileIncomplete}');
          
          await prefs.setString('user', jsonEncode(updatedUser.toJson()));

          if (mounted) {
            // Vérifier explicitement que tous les champs requis sont remplis
            // Nom, Chorale et Pupitre doivent être présents avant de vérifier le statut
            bool isNameEmpty = updatedUser.name == null || updatedUser.name!.trim().isEmpty;
            bool isVoicePartEmpty = updatedUser.voicePart == null || updatedUser.voicePart!.trim().isEmpty;
            bool isChoraleIdEmpty = updatedUser.choraleId == null;
            
            bool isProfileFullyComplete = !isNameEmpty && !isVoicePartEmpty && !isChoraleIdEmpty;
            
            if (!isProfileFullyComplete) {
              // Profil toujours incomplet - afficher un message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez compléter tous les champs requis (nom, chorale, pupitre)'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() => _isLoading = false);
              return;
            }
            
            // Le profil est complètement rempli (nom, chorale, pupitre), maintenant vérifier le statut
            if (updatedUser.status == 'pending') {
              // Statut pending - rediriger vers l'écran d'attente
              print('⏳ Profil complètement rempli mais statut pending - Affichage de l\'écran d\'attente');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingApprovalScreen(),
                ),
              );
            } else {
              // Profil complet et approuvé - rediriger vers la page d'accueil
              print('👤 Profil complètement rempli et approuvé - Redirection vers HomePage');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          }
        } else {
          throw Exception(responseData['message'] ?? 'Erreur de mise à jour');
        }
      } else {
        // Essayer de parser les erreurs de validation
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['message'] ?? 'Erreur serveur';
          
          // Si il y a des erreurs de validation détaillées
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e is List ? e : [e]).toList();
            if (errorList.isNotEmpty) {
              errorMessage = errorList.first.toString();
            }
          }
          
          throw Exception(errorMessage);
        } catch (parseError) {
          throw Exception('Erreur serveur (${response.statusCode})');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstance.priGradient,
              AppConstance.secondary,
              AppConstance.primary.withOpacity(0.8),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 20),
                const Icon(
                  Icons.person_add_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complétez votre profil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pour une meilleure expérience',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),

                // Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nom complet
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom complet *',
                            prefixIcon: Icon(Icons.person, color: AppConstance.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppConstance.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Chorale avec recherche
                        if (_loadingChorales)
                          const Center(child: CircularProgressIndicator())
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _choraleSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Chorale *',
                                  hintText: 'Rechercher une chorale...',
                                  prefixIcon: Icon(Icons.church, color: AppConstance.primary),
                                  suffixIcon: _selectedChorale != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _selectedChorale = null;
                                              _choraleSearchController.clear();
                                              _filteredChorales = _chorales;
                                              _showChoraleDropdown = false;
                                              _pupitres = [];
                                              _selectedPupitre = null;
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppConstance.primary, width: 2),
                                  ),
                                ),
                                readOnly: _selectedChorale != null,
                                onTap: () {
                                  if (_selectedChorale == null) {
                                    setState(() {
                                      _showChoraleDropdown = true;
                                    });
                                  }
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _showChoraleDropdown = true;
                                    _filteredChorales = _chorales
                                        .where((chorale) => chorale.nom
                                            .toLowerCase()
                                            .contains(value.toLowerCase()))
                                        .toList();
                                  });
                                },
                                validator: (value) {
                                  if (_selectedChorale == null) {
                                    return 'Veuillez sélectionner une chorale';
                                  }
                                  return null;
                                },
                              ),
                              if (_showChoraleDropdown && _filteredChorales.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredChorales.length,
                                    itemBuilder: (context, index) {
                                      final chorale = _filteredChorales[index];
                                      return ListTile(
                                        title: Text(chorale.nom),
                                        subtitle: chorale.description != null
                                            ? Text(
                                                chorale.description!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedChorale = chorale;
                                            _choraleSearchController.text = chorale.nom;
                                            _showChoraleDropdown = false;
                                            // Charger les pupitres de la chorale sélectionnée
                                            _loadPupitres(chorale.id);
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Pupitre
                        if (_selectedChorale == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Veuillez d\'abord sélectionner une chorale',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_loadingPupitres)
                          const Center(child: CircularProgressIndicator())
                        else if (_pupitres.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aucun pupitre disponible pour cette chorale',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<ChoralePupitre>(
                            value: _selectedPupitre,
                            decoration: InputDecoration(
                              labelText: 'Pupitre *',
                              prefixIcon: Icon(Icons.music_note, color: AppConstance.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppConstance.primary, width: 2),
                              ),
                            ),
                            items: _pupitres.map((pupitre) {
                              return DropdownMenuItem(
                                value: pupitre,
                                child: Text(pupitre.nom),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedPupitre = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Veuillez sélectionner votre pupitre';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 32),

                        // Bouton Enregistrer
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstance.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enregistrer mon profil',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _choraleSearchController.dispose();
    super.dispose();
  }
}

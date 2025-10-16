import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/widgets/chorale_selector.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/services/auth_service.dart';

class UserRegistrationScreen extends StatefulWidget {
  final String? phoneNumber;
  
  const UserRegistrationScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  Chorale? _selectedChorale;
  String? _selectedPupitre;
  bool loading = false;
  
  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Liste des pupitres disponibles (valeurs acceptées par le backend)
  final List<Map<String, dynamic>> _pupitres = [
    {'value': 'SOPRANE', 'label': 'Soprane', 'icon': Icons.person, 'color': Colors.pink},
    {'value': 'ALTO', 'label': 'Alto', 'icon': Icons.person, 'color': Colors.orange},
    {'value': 'TENOR', 'label': 'Ténor', 'icon': Icons.person, 'color': Colors.blue},
    {'value': 'BASSE', 'label': 'Basse', 'icon': Icons.person, 'color': Colors.brown},
    {'value': 'BARITON', 'label': 'Baryton', 'icon': Icons.person, 'color': Colors.purple},
  ];


  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs d'animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Configurer les animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer les animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }



  void _createAccount() async {
    if (_fullNameController.text.isEmpty || 
        widget.phoneNumber == null ||
        _selectedPupitre == null || 
        _selectedChorale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez remplir tous les champs'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // Validation côté client
      if (_fullNameController.text.length < 3) {
        throw Exception('Le nom complet doit contenir au moins 3 caractères');
      }
      
      if (widget.phoneNumber == null || widget.phoneNumber!.length < 8) {
        throw Exception('Numéro de téléphone manquant ou invalide');
      }
      
      // Générer un email et mot de passe temporaires
      final name = _fullNameController.text.trim();
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@voxbox.bf';
      final password = 'password123'; // Mot de passe temporaire
      
      // Utiliser le numéro de téléphone passé en paramètre
      String phone = widget.phoneNumber!;
      
      print('🔄 Création du compte...');
      print('   - Nom: $name');
      print('   - Email: $email');
      print('   - Téléphone: $phone');
      print('   - Chorale: ${_selectedChorale!.nom} (ID: ${_selectedChorale!.id})');
      print('   - Pupitre: $_selectedPupitre');
      
      // Appel API pour créer le compte
      final response = await registerWithLaravel(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
        choraleId: _selectedChorale!.id,
        voicePart: _selectedPupitre!,
        phone: phone,
      );

      if (response.error == null && response.data != null) {
        final user = response.data as User;
        print('✅ Compte créé avec succès sur le serveur!');
        print('   - ID: ${user.id}');
        print('   - Nom: ${user.name}');
        print('   - Email: ${user.email}');
        
        _saveAndRedirectToHome(user);
      } else {
        throw Exception(response.error ?? 'Erreur inconnue lors de la création du compte');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print('❌ Erreur lors de la création: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la création: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _saveAndRedirectToHome(User user) async {
    setState(() {
      loading = false;
    });

    // Sauvegarder les données utilisateur localement
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setBool('isConnected', false); // Pas encore connecté, en attente d'approbation
      print('✅ Données utilisateur sauvegardées localement');
    } catch (e) {
      print('⚠️ Erreur lors de la sauvegarde locale: $e');
    }

    // Afficher un message de succès avec information sur l'approbation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compte créé avec succès ! Votre compte est en attente d\'approbation.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );

    // Attendre un peu pour que l'utilisateur voie le message
    await Future.delayed(const Duration(seconds: 2));

    // Naviguer vers la page de connexion au lieu de l'accueil
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstance.priGradient,
              AppConstance.secondary,
              AppConstance.primary.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header moderne avec glassmorphism
                _buildModernHeader(size),
                
                // Formulaire avec design card moderne
                _buildModernForm(size),
                
                // Espace en bas
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(Size size) {
    return Container(
      height: size.height * 0.35,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo avec effet glassmorphism
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.person_add_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Titre avec effet de texte moderne
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Colors.white70],
            ).createShader(bounds),
            child: const Text(
              'Créer votre compte',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sous-titre
          Text(
            'Rejoignez notre communauté',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernForm(Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Titre du formulaire
          Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Champ du formulaire
          _buildModernTextField(
            controller: _fullNameController,
            label: 'Nom complet',
            icon: Icons.person_outline,
            hint: 'Entrez votre nom complet',
            
          ),
          
          const SizedBox(height: 20),
          
          // Affichage du numéro de téléphone (lecture seule)
          if (widget.phoneNumber != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.phoneNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
           
           // Sélecteur de chorales
           ChoraleSelector(
             selectedChorale: _selectedChorale,
             onChoraleSelected: (chorale) {
               setState(() {
                 _selectedChorale = chorale;
               });
             },
             label: 'Chorale',
             hint: 'Rechercher votre chorale...',
           ),
          
          const SizedBox(height: 25),
          
          // Sélection du pupitre
          _buildModernPupitreSelection(),
          
          const SizedBox(height: 30),
          
          // Bouton de création
          _buildModernCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[50],
        border: Border.all(
          color: controller.text.isNotEmpty 
            ? AppConstance.primary.withOpacity(0.3)
            : Colors.grey[200]!,
          width: controller.text.isNotEmpty ? 2 : 1,
        ),
        boxShadow: controller.text.isNotEmpty ? [
          BoxShadow(
            color: AppConstance.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (value) {
          setState(() {
            // Déclencher la reconstruction pour l'animation
          });
        },
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 22,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPupitreSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPupitre,
        decoration: InputDecoration(
          labelText: 'Pupitre',
          prefixIcon: Icon(
            Icons.music_note,
            color: Colors.grey[600],
            size: 22,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        items: _pupitres.map((Map<String, dynamic> pupitre) {
          return DropdownMenuItem<String>(
            value: pupitre['value'],
            child: Text(
              pupitre['label'],
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPupitre = newValue;
          });
          
          // Animation de feedback lors de la sélection
          _slideController.reset();
          _slideController.forward();
        },
      ),
    );
  }

  Widget _buildModernCreateButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: loading 
            ? [Colors.grey[400]!, Colors.grey[500]!]
            : [AppConstance.priGradient, AppConstance.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: loading 
              ? Colors.grey.withOpacity(0.2)
              : const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: loading ? 8 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: loading ? null : _createAccount,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Créer mon compte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
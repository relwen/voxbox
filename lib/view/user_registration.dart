import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/widgets/chorale_selector.dart';
import 'package:voxbox/view/home.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  Chorale? _selectedChorale;
  String? _selectedPupitre;
  bool loading = false;

  // Liste des pupitres disponibles
  final List<Map<String, dynamic>> _pupitres = [
    {'value': 'soprano', 'label': 'Soprano', 'icon': Icons.person, 'color': Colors.pink},
    {'value': 'alto', 'label': 'Alto', 'icon': Icons.person, 'color': Colors.orange},
    {'value': 'tenor', 'label': 'Ténor', 'icon': Icons.person, 'color': Colors.blue},
    {'value': 'basse', 'label': 'Basse', 'icon': Icons.person, 'color': Colors.brown},
    {'value': 'tutti', 'label': 'Tutti', 'icon': Icons.group, 'color': Colors.purple},
  ];


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _createAccount() async {
    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty || 
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
      // Simuler un appel API avec validation
      await Future.delayed(const Duration(seconds: 2));
      
      // Simuler une validation côté serveur
      if (_firstNameController.text.length < 2) {
        throw Exception('Le prénom doit contenir au moins 2 caractères');
      }
      
      if (_lastNameController.text.length < 2) {
        throw Exception('Le nom doit contenir au moins 2 caractères');
      }
      
      // Créer l'utilisateur avec les vraies données
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch, // ID unique temporaire
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: '${_firstNameController.text.toLowerCase()}.${_lastNameController.text.toLowerCase()}@voxbox.bf',
        phone: '+22600000000', // TODO: Récupérer le vrai numéro depuis l'OTP
        voicePart: _selectedPupitre,
        chorale: _selectedChorale!.toJson(),
      );

      // Simuler la sauvegarde en base de données
      print('✅ Compte créé avec succès:');
      print('   - Nom: ${user.name}');
      print('   - Email: ${user.email}');
      print('   - Pupitre: ${user.voicePart}');
      print('   - Chorale: ${_selectedChorale!.nom}');

      _saveAndRedirectToHome(user);
    } catch (e) {
      setState(() {
        loading = false;
      });
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

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compte créé avec succès ! Bienvenue ${user.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Attendre un peu pour que l'utilisateur voie le message
    await Future.delayed(const Duration(seconds: 1));

    // Naviguer vers l'accueil
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
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
    return Container(
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
          
          // Champs du formulaire
          _buildModernTextField(
            controller: _firstNameController,
            label: 'Prénom',
            icon: Icons.person_outline,
            hint: 'Entrez votre prénom',
          ),
          
          const SizedBox(height: 20),
          
          _buildModernTextField(
            controller: _lastNameController,
            label: 'Nom',
            icon: Icons.person_outline,
            hint: 'Entrez votre nom',
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
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
        },
      ),
    );
  }

  Widget _buildModernCreateButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstance.priGradient, AppConstance.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _createAccount,
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
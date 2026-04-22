import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/complete_profile_screen.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/pending_approval_screen.dart';
import 'package:voxbox/services/notification_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool loading = false;
  bool isResending = false;
  int countdown = 60;
  bool canResend = false;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _startCountdown();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          countdown--;
          if (countdown <= 0) {
            canResend = true;
          } else {
            _startCountdown();
          }
        });
      }
    });
  }

  // Cette fonction n'est plus utilisée - remplacée par verifyOTP direct

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ToastService.warning(
        context,
        'Veuillez saisir le code OTP complet (6 chiffres)',
        title: 'Code incomplet'
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // Appeler l'API pour vérifier l'OTP et se connecter
      print('🔐 Vérification OTP pour: ${widget.phoneNumber}');
      final response = await verifyOTP(widget.phoneNumber, otp);

      setState(() {
        loading = false;
      });

      if (response.error == null && response.data != null) {
        // OTP valide - Connexion réussie avec token
        print('✅ OTP valide - Connexion réussie!');

        // Les données utilisateur sont déjà sauvegardées dans verifyOTP
        // Récupérer l'utilisateur depuis SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        String? userString = prefs.getString('user');
        User? user;
        
        if (userString != null) {
          try {
            Map<String, dynamic> userMap = jsonDecode(userString);
            user = User.fromJson(userMap);
          } catch (e) {
            print('Erreur de parsing utilisateur: $e');
            user = response.data as User?;
          }
        } else {
          user = response.data as User?;
        }

        if (!mounted || user == null) return;

        // À ce point, user n'est plus null, on peut l'utiliser directement
        final currentUser = user!;

        // Vérifier explicitement que tous les champs requis sont remplis
        // Nom, Chorale et Pupitre doivent être présents avant de vérifier le statut
        bool isNameEmpty = currentUser.name == null || currentUser.name!.trim().isEmpty;
        bool isVoicePartEmpty = currentUser.voicePart == null || currentUser.voicePart!.trim().isEmpty;
        bool isChoraleIdEmpty = currentUser.choraleId == null;
        
        bool needsProfileCompletion = isNameEmpty || isVoicePartEmpty || isChoraleIdEmpty;

        if (needsProfileCompletion) {
          // Profil incomplet - rediriger vers le formulaire de complétion
          // L'utilisateur doit compléter son profil (nom, chorale, pupitre) avant de vérifier le statut
          print('🆕 Profil incomplet détecté - Redirection vers complétion de profil');
          print('   - Nom: ${currentUser.name ?? "VIDE"}');
          print('   - Email: ${currentUser.email ?? "VIDE"}');
          print('   - Voice Part: ${currentUser.voicePart ?? "VIDE"}');
          print('   - Chorale ID: ${currentUser.choraleId ?? "VIDE"}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(user: currentUser),
            ),
          );
          return;
        }

        // Le profil est complètement rempli (nom, chorale, pupitre), maintenant vérifier le statut
        if (currentUser.status == 'pending') {
          // Statut pending - afficher l'écran d'attente
          print('⏳ Profil complet mais statut pending - Affichage de l\'écran d\'attente');
          print('   - Status: ${currentUser.status}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
          );
        } else {
          // Profil complet et approuvé - rediriger vers l'accueil
          print('👤 Profil complet et approuvé - Redirection vers HomePage');
          print('   - Status: ${currentUser.status}');
          
          // Mettre à jour le token FCM sur le serveur dès que l'utilisateur est connecté et approuvé
          NotificationService().updateTokenOnServer();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        }
      } else {
        // Erreur lors de la vérification OTP
        print('❌ Erreur OTP: ${response.error}');

        if (!mounted) return;

        // Vérifier le type d'erreur
        if (response.error?.contains('Code OTP incorrect') == true ||
            response.error?.contains('expiré') == true) {
          // Code incorrect ou expiré
          ToastService.error(
            context,
            response.error ?? 'Code OTP incorrect ou expiré',
            title: 'Code invalide'
          );
        } else if (response.error?.contains('Trop de tentatives') == true) {
          // Trop de tentatives
          ToastService.warning(
            context,
            response.error!,
            title: 'Limite atteinte'
          );
          // Relancer le countdown automatiquement
          _startCountdown();
        } else {
          // Autre erreur
          ToastService.error(
            context,
            response.error ?? 'Erreur de vérification',
            title: 'Erreur'
          );
        }
      }

    } catch (e) {
      setState(() {
        loading = false;
      });

      print('💥 Exception: $e');

      if (!mounted) return;

      ToastService.error(
        context,
        'Erreur inattendue: $e',
        title: 'Erreur système'
      );
    }
  }

  void _resendOTP() async {
    if (!canResend) return;

    setState(() {
      isResending = true;
      canResend = false;
      countdown = 60;
    });

    try {
      // Appeler l'API pour renvoyer l'OTP
      print('📱 Renvoi OTP pour: ${widget.phoneNumber}');
      final response = await requestOTP(widget.phoneNumber);

      setState(() {
        isResending = false;
      });

      if (response.error == null && response.data != null) {
        // OTP renvoyé avec succès
        print('✅ OTP renvoyé avec succès');

        if (!mounted) return;

        ToastService.success(
          context,
          'Un nouveau code OTP a été envoyé',
          title: 'Code renvoyé'
        );

        _startCountdown();
      } else {
        // Erreur lors du renvoi
        print('❌ Erreur renvoi: ${response.error}');

        setState(() {
          canResend = true;
          countdown = 0;
        });

        if (!mounted) return;

        ToastService.error(
          context,
          response.error ?? 'Erreur lors du renvoi du code',
          title: 'Échec du renvoi'
        );
      }

    } catch (e) {
      setState(() {
        isResending = false;
        canResend = true;
        countdown = 0;
      });

      print('💥 Exception: $e');

      if (!mounted) return;

      ToastService.error(
        context,
        'Erreur lors du renvoi: $e',
        title: 'Erreur système'
      );
    }
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-vérifier quand tous les 6 chiffres sont saisis
        _verifyOTP();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
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
        child: Stack(
          children: [
            // Background decorative elements
            _buildBackgroundElements(size),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    // Header section
                    SizedBox(
                      height: size.height * 0.25,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildHeader(),
                        ),
                      ),
                    ),
                    
                    // OTP form section
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildOTPForm(),
                    ),
                    
                    // Espace en bas
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements(Size size) {
    return Stack(
      children: [
        // Floating circles with simple positioning
        Positioned(
          top: size.height * 0.1,
          right: 20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          left: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          right: 30,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        // Élément géométrique simple
        Positioned(
          top: size.height * 0.45,
          left: 30,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with enhanced glassmorphism effect
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.15),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // Title with enhanced visibility
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.9), Colors.white70],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Vérification OTP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        
      ],
    );
  }

  Widget _buildOTPForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, -15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with modern styling
            Text(
              'Saisissez le code',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Entrez le code à 6 chiffres reçu par SMS',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // OTP input fields
            _buildOTPInputs(),
            const SizedBox(height: 30),
            
            // Verify button
            _buildVerifyButton(),
            const SizedBox(height: 20),
            
            // Resend OTP
            _buildResendOTP(),
            const SizedBox(height: 16),
            
            // Loading indicator
            if (loading) _buildLoadingIndicator(),

            // Bouton pour fermer tous les toasts
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ToastService.dismissAll(),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Fermer les notifications'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPInputs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer la largeur disponible et ajuster la taille des champs
        final availableWidth = constraints.maxWidth;
        final fieldWidth = (availableWidth - 50) / 6; // 50px pour les espaces
        final fieldSize = fieldWidth.clamp(40.0, 55.0); // Limiter entre 40 et 55px

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            final isFocused = _focusNodes[index].hasFocus;
            final hasValue = _otpControllers[index].text.isNotEmpty;
            
            return Container(
              width: fieldSize,
              height: fieldSize + 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isFocused || hasValue
                    ? LinearGradient(
                        colors: [
                          AppConstance.primary.withOpacity(0.1),
                          AppConstance.priGradient.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: isFocused || hasValue ? null : Colors.grey[50],
                border: Border.all(
                  color: isFocused
                      ? AppConstance.primary
                      : hasValue
                          ? AppConstance.priGradient
                          : Colors.grey[300]!,
                  width: isFocused ? 2.5 : 1.5,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppConstance.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: TextStyle(
                  fontSize: fieldSize * 0.4, // Taille de police proportionnelle
                  fontWeight: FontWeight.w700,
                  color: isFocused || hasValue
                      ? const Color(0xFF2D3748)
                      : Colors.grey[600],
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (value) => _onOTPChanged(index, value),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstance.primary,
            AppConstance.priGradient,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppConstance.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppConstance.priGradient.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: loading ? null : _verifyOTP,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Vérifier le code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendOTP() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adapter le layout selon la largeur disponible
          if (constraints.maxWidth < 300) {
            // Layout vertical pour les petits écrans
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Vous n\'avez pas reçu le code ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: canResend ? _resendOTP : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: canResend 
                          ? AppConstance.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      canResend ? 'Renvoyer' : '${countdown}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: canResend 
                            ? AppConstance.primary
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Layout horizontal pour les écrans plus larges
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Vous n\'avez pas reçu le code ? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: canResend ? _resendOTP : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: canResend 
                          ? AppConstance.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      canResend ? 'Renvoyer' : '${countdown}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: canResend 
                            ? AppConstance.primary
                            : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppConstance.primary.withOpacity(0.1),
                  AppConstance.priGradient.withOpacity(0.1),
                ],
              ),
            ),
            child: SpinKitCircle(
              color: AppConstance.primary,
              size: 40.0,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vérification en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

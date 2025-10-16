import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/view/user_registration.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/account_pending.dart';
import 'package:voxbox/services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
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

  // Effectuer une vraie connexion avec le numéro de téléphone
  Future<void> _performLogin(String phoneNumber) async {
    try {
      print('🔄 Tentative de connexion avec le numéro: $phoneNumber');
      
      // Utiliser le nouveau service de connexion par téléphone
      final loginResponse = await loginByPhone(phoneNumber);
      
      if (loginResponse.error == null && loginResponse.data != null) {
        print('🎉 Connexion réussie avec token!');
        
        // Sauvegarder les données de connexion
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isConnected', true);
        await prefs.setString('user', jsonEncode(loginResponse.data!.toJson()));
        
        // Rediriger vers l'accueil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        }
      } else {
        print('❌ Erreur de connexion: ${loginResponse.error}');
        
        // Vérifier si c'est un compte en attente
        if (loginResponse.error?.contains('attente d\'approbation') == true) {
          // Rediriger vers la page de compte en attente
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AccountPendingScreen(
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          }
        } else {
          // Afficher un message d'erreur à l'utilisateur
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loginResponse.error ?? 'Erreur de connexion'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          // En cas d'erreur, rediriger vers l'inscription
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserRegistrationScreen(
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('💥 Exception lors de la connexion: $e');
      
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // En cas d'exception, rediriger vers l'inscription
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserRegistrationScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      }
    }
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veuillez saisir le code OTP complet'),
        backgroundColor: Colors.orange
      ));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // TODO: Appeler l'API pour vérifier l'OTP
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        loading = false;
      });

      // Vérifier si le numéro existe en base de données
      print('🔍 Vérification de l\'existence du numéro: ${widget.phoneNumber}');
      final response = await checkPhoneExists(widget.phoneNumber);
      
      if (response.error == null && response.data != null) {
        bool phoneExists = response.data as bool;
        
        if (phoneExists) {
          // Le numéro existe, faire une vraie connexion
          print('✅ Numéro trouvé, connexion avec token');
          await _performLogin(widget.phoneNumber);
        } else {
          // Le numéro n'existe pas, rediriger vers l'inscription
          print('📝 Numéro non trouvé, redirection vers l\'inscription');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserRegistrationScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
        // Erreur lors de la vérification, rediriger vers l'inscription par défaut
        print('⚠️ Erreur lors de la vérification, redirection vers l\'inscription');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserRegistrationScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red
      ));
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
      // TODO: Appeler l'API pour renvoyer l'OTP
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        isResending = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code OTP renvoyé !'),
        backgroundColor: Colors.green
      ));
      
      _startCountdown();
      
    } catch (e) {
      setState(() {
        isResending = false;
        canResend = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red
      ));
    }
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 4) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
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
              'Entrez le code à 5 chiffres reçu par SMS',
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
        final fieldWidth = (availableWidth - 40) / 5; // 40px pour les espaces
        final fieldSize = fieldWidth.clamp(45.0, 60.0); // Limiter entre 45 et 60px
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
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

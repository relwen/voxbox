import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/otp_screen.dart';
import 'package:voxbox/view/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  bool loading = false;
  String selectedCountryCode = '+226'; // Code par défaut Mali
  String? phoneNumber; // Pour stocker le numéro entre les écrans

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
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
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });
  }

  void sendOTP() async {
    if (phoneController.text.isEmpty) {
      ToastService.warning(
        context,
        'Veuillez saisir votre numéro de téléphone',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      String fullPhoneNumber = selectedCountryCode + phoneController.text;
      phoneNumber = fullPhoneNumber; // Stocker pour l'écran OTP

      // Appeler l'API pour envoyer l'OTP
      print('📱 Envoi OTP pour: $fullPhoneNumber');
      final response = await requestOTP(fullPhoneNumber);

      setState(() {
        loading = false;
      });

      if (response.error == null && response.data != null) {


        if (!mounted) return;

        // Naviguer vers l'écran OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(phoneNumber: fullPhoneNumber),
          ),
        );
      } else {
        // Erreur lors de l'envoi de l'OTP
        print('❌ Erreur: ${response.error}');

        if (!mounted) return;

        ToastService.error(
          context,
          response.error ?? 'Erreur lors de l\'envoi du code',
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      print('💥 Exception: $e');

      if (!mounted) return;

      ToastService.error(
        context,
        'Erreur: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Permet au clavier de redimensionner l'écran
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
                physics: const BouncingScrollPhysics(), // Scroll plus fluide
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header section with logo and title
                        SizedBox(
                          height:
                              size.height * 0.4, // Hauteur fixe pour le header
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildHeader(),
                            ),
                          ),
                        ),

                        // Login form section
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLoginForm(),
                        ),

                        // Espace en bas pour éviter que le clavier cache le contenu
                        SizedBox(
                            height:
                                MediaQuery.of(context).viewInsets.bottom + 20),
                      ],
                    ),
                  ),
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
        // Floating circles
        Positioned(
          top: size.height * 0.1,
          right: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          left: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
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
        // Logo with glow effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            AppImages.logo,
            width: 120,
            height: 120,
          ),
        ),
        const SizedBox(height: 20),

        // App name with gradient text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: const Text(
            'Connectez-vous avec \nvotre numéro de téléphone',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(15, 20, 15, 15), // Padding réduit en haut
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Prend seulement l'espace nécessaire
          children: [
            // Titre du formulaire
            Text(
              'Connexion',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstance.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Phone field
            _buildPhoneField(),
            const SizedBox(height: 24),

            // Send OTP button
            _buildSendOTPButton(),
            const SizedBox(height: 16),

            // Loading indicator
            if (loading) _buildLoadingIndicator(),

            const SizedBox(height: 20),

            // Skip Login Button (Apple Compliance)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: Text(
                'Continuer sans compte',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: IntlPhoneField(
            controller: phoneController,
            initialCountryCode: 'BF',
            onCountryChanged: (country) {
              setState(() {
                selectedCountryCode = country.dialCode;
              });
            },
            decoration: InputDecoration(
              hintText: 'Votre numéro de téléphone',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppConstance.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 16),
            dropdownTextStyle: const TextStyle(fontSize: 16),
            flagsButtonPadding: const EdgeInsets.only(left: 5),
            invalidNumberMessage: 'Numéro invalide',
          ),
        ),
      ],
    );
  }

  Widget _buildSendOTPButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstance.primary, AppConstance.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppConstance.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: loading ? null : sendOTP,
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
                        Icons.sms_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Envoyer le code OTP',
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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SpinKitFadingCircle(
            color: AppConstance.primary,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Connexion en cours...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

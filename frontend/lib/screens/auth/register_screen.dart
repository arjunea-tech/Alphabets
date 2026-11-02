import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await widget.authService.register(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Show cheerful Tamil success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registration successful! 🎉',
                  style: GoogleFonts.catamaran(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to Login screen
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Brand Header & Mascot
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_logo_english.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'ALPHABETS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.catamaran(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'Create an Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.catamaran(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'Learn English Alphabets with fun and joy!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.catamaran(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error banner if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFB3B3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.playfulPink, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.catamaran(
                                  color: const Color(0xFFC53030),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Input Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1.  (Name)
                          _buildFieldLabel('Name', Icons.person_rounded),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.catamaran(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Enter your name',
                              prefixIcon: Icons.badge_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // 2.  (Email)
                          _buildFieldLabel('Email Address', Icons.email_rounded),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: GoogleFonts.catamaran(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'example@gmail.com',
                              prefixIcon: Icons.alternate_email_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email address is required';
                              }
                              final trimmed = value.trim();
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // 3.  (Password)
                          _buildFieldLabel('Password', Icons.lock_rounded),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.catamaran(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'At least 6 characters',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // 4.   (Confirm Password)
                          _buildFieldLabel('Confirm Password', Icons.lock_clock_rounded),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            style: GoogleFonts.catamaran(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: Icons.verified_user_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Button:   (Register)
                    BouncyButton(
                      onPressed: _isLoading ? () {} : _handleRegister,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.orangeGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.8,
                                  ),
                                )
                              : Text(
                                  'Sign Up',
                                  style: GoogleFonts.catamaran(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Secondary Link:   ? 
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.catamaran(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: GoogleFonts.catamaran(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondaryDark,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.catamaran(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.catamaran(
        color: const Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.playfulPink, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.playfulPink, width: 2),
      ),
    );
  }
}

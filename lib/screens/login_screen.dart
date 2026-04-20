import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_card.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final user = await authService.restoreSession();
    if (user != null && mounted) {
      _navigateAfterLogin(user);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _checkSetupComplete() async {
    try {
      final result = await dbService.getSetting('setupComplete');
      if (result == 'true') {
        if (authService.currentUser != null) {
          if (authService.currentUser!.primaryRole == UserRole.teacher) {
            final teacherSetup = await dbService.getSetting(
              'teacherSetup_${authService.currentUser!.id}',
            );
            return teacherSetup == 'true';
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _navigateAfterLogin(UserModel user) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => DashboardScreen(user: user),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToSetup(UserModel user) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => SetupScreen(user: user),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      if (result is UserModel) {
        final isSetupComplete = await _checkSetupComplete();
        if (!mounted) return;
        if (isSetupComplete) {
          _navigateAfterLogin(result);
        } else {
          _navigateToSetup(result);
        }
      } else if (result is String) {
        showInfoSnackBar(context, result);
      } else {
        showErrorSnackBar(context, 'Invalid email or password.');
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.primaryTeal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reset Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter the account email. A password reset link will be sent to your inbox.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Account Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: sending ? null : () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: sending
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                showInfoSnackBar(
                                    context, 'Enter a valid account email.');
                                return;
                              }
                              setSheetState(() => sending = true);
                              final error = await authService.resetPassword(
                                email: email,
                              );
                              if (!ctx.mounted) return;
                              final scaffoldContext = context;
                              Navigator.pop(ctx);
                              if (!scaffoldContext.mounted) return;
                              if (error == null) {
                                showSuccessSnackBar(scaffoldContext,
                                    'Password reset link sent to $email');
                              } else {
                                showErrorSnackBar(scaffoldContext, error);
                              }
                            },
                      child: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      emailCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryTeal.withValues(alpha: isDark ? 0.3 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: isDark ? 0.2 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Logo and branding
                      SlideUpFade(
                        delay: const Duration(milliseconds: 100),
                        child: _buildBrandHeader(isDark),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login form card
                      SlideUpFade(
                        delay: const Duration(milliseconds: 200),
                        child: _buildLoginCard(isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(bool isDark) {
    return Column(
      children: [
        // Logo container with gradient
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        
        // App name
        Text(
          'Schoolify',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          'School Management Platform',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your institution credentials',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),
            
            // Email field
            _buildFieldLabel('Email Address', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'admin@school.com',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.alternate_email_rounded,
                    size: 18,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 20),
            
            // Password field
            _buildFieldLabel('Password', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.accentRose,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20,
                    color: isDark 
                        ? AppColors.darkTextMuted 
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Password required' : null,
            ),
            const SizedBox(height: 12),
            
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Create account button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => const RegisterScreen(),
                    transitionsBuilder: (_, animation, _, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: BorderSide(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Create Owner Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

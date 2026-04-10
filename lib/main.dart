import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite_common_ffi required on Linux/Windows/macOS desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize DB (creates tables + seeds data on first run)
  await dbService.db;
  await themeService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'School Management System',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF080E1A), Color(0xFF0D1626), Color(0xFF111E33)]
                      : const [Color(0xFFF0F4FF), Color(0xFFEEF2FF), Color(0xFFE8F5F0)],
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const LoginScreen(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    const Color primaryColor = Color(0xFF4F46E5);
    const Color secondaryColor = Color(0xFF7C3AED);
    const Color surfaceColor = Color(0xFFFFFFFF);
    const Color backgroundColor = Color(0xFFF0F4FF);
    const Color textColor = Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'PlusJakartaSans',
      textTheme: Typography.blackCupertino.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFF1E293B).withOpacity(0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle: TextStyle(fontWeight: FontWeight.w500, color: textColor.withOpacity(0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: textColor.withOpacity(0.85),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        selectedColor: primaryColor.withOpacity(0.15),
        backgroundColor: const Color(0xFFEFF2FF),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: Color(0xFFE8EDF5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color primaryColor = Color(0xFF818CF8);
    const Color secondaryColor = Color(0xFFA78BFA);
    const Color surfaceColor = Color(0xFF141E30);
    const Color backgroundColor = Color(0xFF080E1A);
    const Color textColor = Color(0xFFF1F5F9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'PlusJakartaSans',
      textTheme: Typography.whiteCupertino.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: primaryColor.withOpacity(0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1626),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle: TextStyle(fontWeight: FontWeight.w500, color: textColor.withOpacity(0.35)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: textColor.withOpacity(0.9),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        selectedColor: primaryColor.withOpacity(0.2),
        backgroundColor: const Color(0xFF1A2540),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: Color(0xFF1E2D45),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final user = await authService.restoreSession();
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DashboardScreen(user: user),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await authService.login(_emailController.text, _passwordController.text);
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DashboardScreen(user: user),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Invalid credentials. Please try again.'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred. Please try again.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _fillDemo(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withOpacity(isDark ? 0.18 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(isDark ? 0.15 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          _buildBrandHeader(theme, isDark),
                          const SizedBox(height: 28),
                          _buildLoginCard(theme, isDark),
                          const SizedBox(height: 16),
                          _buildQuickAccessPanel(theme, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EduManage Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'School Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withOpacity(isDark ? 0.25 : 0.07),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in with your institution credentials',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Email Address', theme),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'admin@school.com',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 18),
            _buildFieldLabel('Password', theme),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) => (value == null || value.length < 6) ? 'Password required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: theme.colorScheme.onSurface.withOpacity(0.75),
      ),
    );
  }

  Widget _buildQuickAccessPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Demo Login',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a role to auto-fill credentials',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _DemoBadge(label: 'Admin', color: const Color(0xFF6366F1), onTap: () => _fillDemo('admin@school.com'))),
              const SizedBox(width: 8),
              Expanded(child: _DemoBadge(label: 'Teacher', color: const Color(0xFF10B981), onTap: () => _fillDemo('teacher@school.com'))),
              const SizedBox(width: 8),
              Expanded(child: _DemoBadge(label: 'Student', color: const Color(0xFFF59E0B), onTap: () => _fillDemo('student@school.com'))),
              const SizedBox(width: 8),
              Expanded(child: _DemoBadge(label: 'Parent', color: const Color(0xFFEC4899), onTap: () => _fillDemo('parent@school.com'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoBadge({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

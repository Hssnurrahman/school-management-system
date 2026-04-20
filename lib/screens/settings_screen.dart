import 'package:flutter/material.dart';
import 'audit_log_screen.dart';
import 'login_screen.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  String _language = 'English';
  Map<String, String> _schoolInfo = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadSchoolInfo();
  }

  Future<void> _loadSchoolInfo() async {
    final info = await dbService.getSchoolInfo();
    if (mounted) setState(() => _schoolInfo = info);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, authService]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              ModernAppBar(
                title: 'Settings',
                expandedHeight: 140,
                backgroundIcon: Icons.settings_rounded,
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      SlideUpFade(
                        child: _buildProfileCard(isDark),
                      ),
                      
                      // School Info Card (for admins)
                      if (authService.currentUser?.primaryRole == UserRole.owner ||
                          authService.currentUser?.primaryRole == UserRole.principal) ...[
                        const SizedBox(height: 16),
                        SlideUpFade(
                          delay: const Duration(milliseconds: 100),
                          child: _buildSchoolInfoCard(isDark),
                        ),
                      ],
                      
                      const SizedBox(height: 28),
                      
                      // Preferences Section
                      SlideUpFade(
                        delay: const Duration(milliseconds: 200),
                        child: _buildSectionLabel('Preferences'),
                      ),
                      const SizedBox(height: 12),
                      SlideUpFade(
                        delay: const Duration(milliseconds: 250),
                        child: _buildSettingsGroup([
                          _SettingItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: AppColors.accentCyan,
                            title: 'Notifications',
                            subtitle: 'Manage alerts and updates',
                            trailing: Switch.adaptive(
                              value: _notificationsEnabled,
                              onChanged: (val) =>
                                  setState(() => _notificationsEnabled = val),
                              activeThumbColor: AppColors.accentCyan,
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: AppColors.primaryPurple,
                            title: 'Dark Mode',
                            subtitle: 'Reduce eye strain at night',
                            trailing: Switch.adaptive(
                              value: themeService.isDarkMode,
                              onChanged: (val) => themeService.setDarkMode(val),
                              activeThumbColor: AppColors.primaryPurple,
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.language_rounded,
                            iconColor: AppColors.accentEmerald,
                            title: 'Language',
                            subtitle: _language,
                            onTap: _showLanguagePicker,
                          ),
                        ]),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Administration Section (Owner only)
                      if (authService.currentUser?.primaryRole ==
                          UserRole.owner) ...[
                        SlideUpFade(
                          delay: const Duration(milliseconds: 280),
                          child: _buildSectionLabel('Administration'),
                        ),
                        const SizedBox(height: 12),
                        SlideUpFade(
                          delay: const Duration(milliseconds: 290),
                          child: _buildSettingsGroup([
                            _SettingItem(
                              icon: Icons.history_rounded,
                              iconColor: AppColors.primaryTeal,
                              title: 'Audit Log',
                              subtitle: 'Sensitive actions (fees, roles, settings)',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuditLogScreen(),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Account Section
                      SlideUpFade(
                        delay: const Duration(milliseconds: 300),
                        child: _buildSectionLabel('Account'),
                      ),
                      const SizedBox(height: 12),
                      SlideUpFade(
                        delay: const Duration(milliseconds: 350),
                        child: _buildSettingsGroup([
                          _SettingItem(
                            icon: Icons.swap_horiz_rounded,
                            iconColor: AppColors.accentCyan,
                            title: 'Switch Role',
                            subtitle: authService.hasMultipleRoles
                                ? 'Current: ${_roleTitle(authService.effectiveRole)}'
                                : 'You have only one role',
                            onTap: authService.hasMultipleRoles
                                ? _showRoleSwitcher
                                : null,
                          ),
                          _SettingItem(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.accentAmber,
                            title: 'Change Password',
                            onTap: () => _showComingSoon('Change Password'),
                          ),
                          _SettingItem(
                            icon: Icons.help_outline_rounded,
                            iconColor: AppColors.accentPink,
                            title: 'Help & Feedback',
                            onTap: () => _showComingSoon('Help & Support'),
                          ),
                          _SettingItem(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.primaryTeal,
                            title: 'About App',
                            onTap: _showAboutDialog,
                          ),
                        ]),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Out Button
                      SlideUpFade(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSignOutButton(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final u = authService.currentUser;
    final name = u?.name ?? 'Signed out';
    final email = u?.email ?? '';
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primaryTeal,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? '—' : email,
                  style: TextStyle(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (u != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _roleTitle(authService.effectiveRole),
                      style: const TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 20,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildSettingTile(item: item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingTile({required _SettingItem item}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 22),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: item.trailing ??
          (item.onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: isDark 
                      ? AppColors.darkTextMuted 
                      : AppColors.lightTextMuted,
                )
              : null),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        await authService.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.roseGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRose.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard(bool isDark) {
    final name = _schoolInfo['name']?.isNotEmpty == true
        ? _schoolInfo['name']!
        : 'Not set';
    final address = _schoolInfo['address'] ?? '';
    final phone = _schoolInfo['phone'] ?? '';
    final email = _schoolInfo['email'] ?? '';
    final canEditSchool =
        authService.currentUser?.primaryRole == UserRole.owner;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'School Information',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              if (canEditSchool)
                GestureDetector(
                  onTap: () => _showEditSchoolInfoSheet(isDark),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryTeal,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.business_rounded, name, isDark),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, address, isDark),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.phone_outlined, phone, isDark),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.email_outlined, email, isDark),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    showSuccessSnackBar(context, '$feature coming soon!');
  }

  String _roleTitle(UserRole? role) {
    if (role == null) return 'Role';
    return role.name[0].toUpperCase() + role.name.substring(1);
  }

  void _showRoleSwitcher() {
    final currentRole = authService.effectiveRole;
    final allRoles = authService.currentUser?.allRoles ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Switch Role',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the role you want to use for this session',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ...allRoles.map((role) => _buildRoleTile(role, currentRole)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTile(UserRole role, UserRole? currentRole) {
    final isSelected = role == currentRole;
    return ListTile(
      onTap: () async {
        if (!isSelected) {
          await authService.switchRole(role);
          if (mounted) {
            Navigator.pop(context);
            showSuccessSnackBar(context, 'Switched to ${role.name}');
          }
        } else {
          Navigator.pop(context);
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentCyan.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getRoleIcon(role),
          color: isSelected ? AppColors.accentCyan : Colors.grey,
          size: 22,
        ),
      ),
      title: Text(
        role.name[0].toUpperCase() + role.name.substring(1),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan)
          : null,
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.stars_rounded;
      case UserRole.principal:
        return Icons.account_balance_rounded;
      case UserRole.teacher:
        return Icons.school_rounded;
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Schoolify',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A comprehensive solution for managing school operations, students, staff, and more.',
              style: TextStyle(
                fontSize: 14, 
                height: 1.6,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'French', 'Arabic'].map<Widget>((lang) {
              final isSelected = _language == lang;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTeal.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primaryTeal : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryTeal,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: () {
                    setState(() => _language = lang);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditSchoolInfoSheet(bool isDark) {
    final nameCtrl = TextEditingController(text: _schoolInfo['name'] ?? '');
    final addressCtrl = TextEditingController(text: _schoolInfo['address'] ?? '');
    final phoneCtrl = TextEditingController(text: _schoolInfo['phone'] ?? '');
    final emailCtrl = TextEditingController(text: _schoolInfo['email'] ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 20,
            left: 24,
            right: 24,
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
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Edit School Info',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'School Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() => saving = true);
                            final info = {
                              'name': nameCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                            };
                            await dbService.saveSchoolInfo(info);
                            await dbService.writeAudit(
                              actor: authService.currentUser,
                              action: 'settings.school_info.update',
                              targetType: 'settings',
                              targetId: 'school_info',
                              metadata: info,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadSchoolInfo();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
    });
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

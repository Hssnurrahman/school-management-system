import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../utils/app_snackbar.dart';

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
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0, 0.8),
            (0.4 + index * 0.1).clamp(0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
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
    return ListenableBuilder(
      listenable: Listenable.merge([themeService, authService]),
      builder: (context, child) {
        final isDark = themeService.isDarkMode;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
                  title: const Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Icon(Icons.settings_rounded, color: Colors.white.withValues(alpha: 0.08), size: 130),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimations[0],
                        child: _buildProfileCard(isDark),
                      ),
                      if (authService.currentUser?.primaryRole ==
                              UserRole.owner ||
                          authService.currentUser?.primaryRole ==
                              UserRole.principal) ...[
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeAnimations[0],
                          child: _buildSchoolInfoCard(isDark),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: _buildSectionLabel('Preferences'),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: _buildSettingsGroup(isDark, [
                          _SettingItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            title: 'Notifications',
                            subtitle: 'Manage alerts and updates',
                            trailing: Switch.adaptive(
                              value: _notificationsEnabled,
                              onChanged: (val) =>
                                  setState(() => _notificationsEnabled = val),
                              activeTrackColor: const Color(0xFF0EA5E9),
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Dark Mode',
                            subtitle: 'Reduce eye strain at night',
                            trailing: Switch.adaptive(
                              value: themeService.isDarkMode,
                              onChanged: (val) => themeService.setDarkMode(val),
                              activeTrackColor: const Color(0xFF0284C7),
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Language',
                            subtitle: _language,
                            onTap: _showLanguagePicker,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fadeAnimations[2],
                        child: _buildSectionLabel('Account'),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimations[2],
                        child: _buildSettingsGroup(isDark, [
                          _SettingItem(
                            icon: Icons.swap_horiz_rounded,
                            iconColor: const Color(0xFF0EA5E9),
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
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Change Password',
                            onTap: () => _showComingSoon('Change Password'),
                          ),
                          _SettingItem(
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFFEC4899),
                            title: 'Help & Feedback',
                            onTap: () => _showComingSoon('Help & Support'),
                          ),
                          _SettingItem(
                            icon: Icons.info_outline_rounded,
                            iconColor: const Color(0xFF14B8A6),
                            title: 'About App',
                            onTap: _showAboutDialog,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimations[3],
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final u = authService.currentUser;
    final name = u?.name ?? 'Signed out';
    final email = u?.email ?? '';
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isDark ? const Color(0xFF141E30) : Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontSize: 22,
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
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty ? '—' : email,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (u != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _roleTitle(authService.effectiveRole),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF0D9488),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(bool isDark, List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildSettingTile(isDark: isDark, item: item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 60,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFE8EDF5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingTile({required bool isDark, required _SettingItem item}) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 20),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing:
          item.trailing ??
          (item.onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                )
              : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
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
            const SizedBox(height: 20),
            const Text(
              'Switch Role',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the role you want to use for this session',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
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
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getRoleIcon(role),
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey,
          size: 22,
        ),
      ),
      title: Text(
        role.name[0].toUpperCase() + role.name.substring(1),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0EA5E9))
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Schoolify',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 14),
            const Text(
              'A comprehensive solution for managing school operations, students, staff, and more.',
              style: TextStyle(fontSize: 13, height: 1.5),
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'French', 'Arabic'].map<Widget>((lang) {
              final isSelected = _language == lang;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(
                    lang,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0D9488) : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0D9488),
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

  Widget _buildSchoolInfoCard(bool isDark) {
    final name = _schoolInfo['name']?.isNotEmpty == true
        ? _schoolInfo['name']!
        : 'Not set';
    final address = _schoolInfo['address'] ?? '';
    final phone = _schoolInfo['phone'] ?? '';
    final email = _schoolInfo['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'School Information',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditSchoolInfoSheet(isDark),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0D9488),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.business_rounded, name, isDark),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined, address, isDark),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, phone, isDark),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          size: 15,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditSchoolInfoSheet(bool isDark) {
    final nameCtrl = TextEditingController(text: _schoolInfo['name'] ?? '');
    final addressCtrl =
        TextEditingController(text: _schoolInfo['address'] ?? '');
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit School Info',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'School Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() => saving = true);
                            await dbService.saveSchoolInfo({
                              'name': nameCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadSchoolInfo();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
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

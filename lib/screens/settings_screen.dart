import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  String _language = 'English';
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval((index * 0.1).clamp(0, 0.8), (0.4 + index * 0.1).clamp(0, 1.0), curve: Curves.easeOut),
        ),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final isDark = themeService.isDarkMode;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.settings_rounded, color: Colors.white.withOpacity(0.12), size: 120),
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
                      FadeTransition(opacity: _fadeAnimations[0], child: _buildProfileCard(isDark)),
                      const SizedBox(height: 28),
                      FadeTransition(opacity: _fadeAnimations[1], child: _buildSectionLabel('Preferences')),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: _buildSettingsGroup(isDark, [
                          _SettingItem(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Notifications',
                            subtitle: 'Manage alerts and updates',
                            trailing: Switch.adaptive(
                              value: _notificationsEnabled,
                              onChanged: (val) => setState(() => _notificationsEnabled = val),
                              activeColor: const Color(0xFF6366F1),
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Dark Mode',
                            subtitle: 'Reduce eye strain at night',
                            trailing: Switch.adaptive(
                              value: themeService.isDarkMode,
                              onChanged: (val) => themeService.setDarkMode(val),
                              activeColor: const Color(0xFF8B5CF6),
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
                      FadeTransition(opacity: _fadeAnimations[2], child: _buildSectionLabel('Security & Support')),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimations[2],
                        child: _buildSettingsGroup(isDark, [
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
                      FadeTransition(opacity: _fadeAnimations[3], child: _buildSignOutButton()),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isDark ? const Color(0xFF141E30) : Colors.white,
              child: const Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hassan Ali', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 3),
                Text(
                  'admin@school.com',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 18),
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
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
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
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
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
          color: item.iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 20),
      ),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: item.trailing ??
          (item.onTap != null
              ? Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
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
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.25),
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
            Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('$feature coming soon!'),
          ],
        ),
        backgroundColor: const Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('EduManage Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 14),
            const Text(
              'A comprehensive solution for managing school operations, students, staff, and more.',
              style: TextStyle(fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'French', 'Arabic'].map((lang) {
              final isSelected = _language == lang;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: isSelected ? const Color(0xFF4F46E5) : null)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5)) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () { setState(() => _language = lang); Navigator.pop(context); },
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
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

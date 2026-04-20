import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern app bar with gradient background
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final Widget? flexibleSpace;
  final Gradient? gradient;
  final IconData? backgroundIcon;
  final Color? backgroundIconColor;
  final double backgroundIconSize;
  final VoidCallback? onLeadingTap;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.expandedHeight = 160,
    this.floating = false,
    this.pinned = true,
    this.flexibleSpace,
    this.gradient,
    this.backgroundIcon,
    this.backgroundIconColor,
    this.backgroundIconSize = 130,
    this.onLeadingTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(expandedHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
      leading: leading ?? (Navigator.canPop(context)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              onPressed: onLeadingTap ?? () => Navigator.pop(context),
            )
          : null),
      actions: actions?.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: action,
        );
      }).toList(),
      flexibleSpace: flexibleSpace ?? FlexibleSpaceBar(
        titlePadding: EdgeInsets.fromLTRB(
          Navigator.canPop(context) ? 72 : 20,
          0,
          16,
          16,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? (isDark 
                ? AppColors.darkSurfaceGradient 
                : AppColors.lightSurfaceGradient),
          ),
          child: backgroundIcon != null
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      backgroundIcon,
                      color: (backgroundIconColor ?? (isDark 
                          ? Colors.white 
                          : AppColors.primaryTeal)).withValues(alpha: 0.08),
                      size: backgroundIconSize,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Gradient app bar with primary colors
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final Gradient gradient;
  final IconData? backgroundIcon;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.expandedHeight = 160,
    this.gradient = AppColors.primaryGradient,
    this.backgroundIcon,
  });

  @override
  Size get preferredSize => Size.fromHeight(expandedHeight);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      leading: leading ?? (Navigator.canPop(context)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null),
      actions: actions?.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: action,
          ),
        );
      }).toList(),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.fromLTRB(
          Navigator.canPop(context) ? 72 : 20,
          0,
          16,
          16,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: backgroundIcon != null
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      backgroundIcon,
                      color: Colors.white.withValues(alpha: 0.15),
                      size: 130,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Compact app bar for simple screens
class CompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CompactAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark 
        ? AppColors.darkSurface 
        : AppColors.lightSurface);
    final fgColor = foregroundColor ?? (isDark 
        ? AppColors.darkText 
        : AppColors.lightText);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      leading: leading ?? (Navigator.canPop(context)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: fgColor,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: fgColor,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions?.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: action,
          ),
        );
      }).toList(),
    );
  }
}

/// Search app bar with integrated search field
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final String hintText;
  final List<Widget>? actions;

  const SearchAppBar({
    super.key,
    required this.title,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search...',
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    widget.onClear?.call();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: isDark 
                        ? AppColors.darkTextMuted 
                        : AppColors.lightTextMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: widget.onSearch,
              )
            : Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSearching
                  ? AppColors.accentRose.withValues(alpha: 0.1)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
              color: _isSearching
                  ? AppColors.accentRose
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
          onPressed: () {
            if (_isSearching) {
              _clearSearch();
            } else {
              setState(() => _isSearching = true);
            }
          },
        ),
        if (widget.actions != null) ...widget.actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}

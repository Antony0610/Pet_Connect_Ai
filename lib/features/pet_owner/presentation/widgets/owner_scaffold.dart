import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_ai_fab.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The shared shell for every top-level Pet Owner screen.
///
/// Composes the floating glass [OwnerBottomNavBar], the [OwnerAiFab] and the
/// screen [body] over a single [Scaffold]. Selecting a tab navigates to that
/// destination via GoRouter (`goNamed`), keeping the router structure stable
/// rather than restructuring it into a shell route.
///
/// Screens supply their own [OwnerGlassAppBar] as [appBar] so each can tailor
/// its header; the scaffold sets `extendBodyBehindAppBar`/`extendBody` so the
/// glass surfaces blur the content beneath them.
class OwnerScaffold extends StatefulWidget {
  const OwnerScaffold({
    required this.currentTab,
    required this.body,
    this.appBar,
    this.showAiFab = true,
    this.floatingActionButton,
    super.key,
  });

  /// The active bottom-nav destination for this screen.
  final OwnerTab currentTab;

  /// The scrollable page content (drawn beneath the glass chrome).
  final Widget body;

  /// The screen's glass app bar, if any.
  final PreferredSizeWidget? appBar;

  /// Whether to show the floating AI Assistant button. Ignored when a custom
  /// [floatingActionButton] is supplied.
  final bool showAiFab;

  /// A screen-specific floating action button that replaces the default AI
  /// Assistant FAB (e.g. the "add pet" action on the My Pets list). It is
  /// lifted above the floating nav bar just like the AI FAB.
  final Widget? floatingActionButton;

  @override
  State<OwnerScaffold> createState() => _OwnerScaffoldState();
}

class _OwnerScaffoldState extends State<OwnerScaffold> {
  bool _isFabVisible = true;

  void _onTabSelected(BuildContext context, OwnerTab tab) {
    if (tab == widget.currentTab) return;
    context.goNamed(tab.routeName);
  }

  void _openAiAssistant(BuildContext context) {
    context.goNamed(RouteNames.ownerAiChat);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(MediaQuery.sizeOf(context).width);
    final fab = widget.floatingActionButton ??
        (widget.showAiFab
            ? RepaintBoundary(
                child: OwnerAiFab(onPressed: () => _openAiAssistant(context)),
              )
            : null);

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          if (_isFabVisible) {
            setState(() => _isFabVisible = false);
          }
        } else if (notification.direction == ScrollDirection.forward) {
          if (!_isFabVisible) {
            setState(() => _isFabVisible = true);
          }
        }
        return false;
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: widget.appBar,
        body: widget.body,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: fab == null
            ? null
            : Padding(
                // Lift the FAB comfortably above the floating bottom nav bar.
                padding: EdgeInsets.only(
                  bottom: isMobile ? 20 : 36,
                  right: isMobile ? 4 : 8,
                ),
                child: AnimatedSlide(
                  offset: _isFabVisible ? Offset.zero : const Offset(0, 1.8),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    opacity: _isFabVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: fab,
                  ),
                ),
              ),
        bottomNavigationBar: OwnerBottomNavBar(
          currentTab: widget.currentTab,
          onTabSelected: (tab) => _onTabSelected(context, tab),
        ),
      ),
    );
  }
}

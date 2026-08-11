import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_paths.dart';
import 'owner_ai_fab.dart';
import 'owner_bottom_nav_bar.dart';

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
class OwnerScaffold extends StatelessWidget {
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

  void _onTabSelected(BuildContext context, OwnerTab tab) {
    if (tab == currentTab) return;
    context.goNamed(tab.routeName);
  }

  void _openAiAssistant(BuildContext context) {
    context.goNamed(RouteNames.ownerAiAssistant);
  }

  @override
  Widget build(BuildContext context) {
    final fab =
        floatingActionButton ??
        (showAiFab
            ? OwnerAiFab(onPressed: () => _openAiAssistant(context))
            : null);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: body,
      floatingActionButton: fab == null
          ? null
          : Padding(
              // Lift the FAB above the floating nav bar.
              padding: const EdgeInsets.only(bottom: 72),
              child: fab,
            ),
      bottomNavigationBar: OwnerBottomNavBar(
        currentTab: currentTab,
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
    );
  }
}

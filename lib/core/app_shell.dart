import 'package:flutter/material.dart';


import 'network/network_banner.dart';
import 'network/network_status.dart';

import '../features/recipes/saved_recipes_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shared/today_page.dart';
import '../features/shared/shopping_list_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // „Heute“ ist der zentrale Einstieg: Die App beantwortet zuerst die Frage,
  // was wir heute gemeinsam machen.
  int index = 0;
  late final NetworkStatusService _network;
  final GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<int> _contentIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _network = NetworkStatusService();
    _network.start();
  }

  void _selectTab(int value) {
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (value != index) {
      setState(() {
        index = value;
        _contentIndex.value = value;
      });
    }
  }

  @override
  void dispose() {
    _network.dispose();
    _contentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NetworkStatus>(
      valueListenable: _network.status,
      builder: (context, status, _) => PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = _contentNavigatorKey.currentState;
        if (navigator?.canPop() == true) {
          navigator!.pop();
          return;
        }
        if (index != 0) {
          setState(() {
            index = 0;
            _contentIndex.value = 0;
          });
        }
      },
      child: Column(
        children: [
          NetworkBanner(status: status),
          Expanded(child: _buildShell(context)),
        ],
      ),
    ),
    );
  }

  Widget _buildShell(BuildContext context) {
    final pages = [
      const TodayPage(),
      SavedRecipesPage(onNavigateToTab: _selectTab),
      const ShoppingListPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Navigator(
        key: _contentNavigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => ValueListenableBuilder<int>(
            valueListenable: _contentIndex,
            builder: (_, selectedIndex, __) => IndexedStack(
              index: selectedIndex,
              children: pages,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Heute'),
          NavigationDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Rezepte'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart_rounded), label: 'Einkauf'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: ''),
        ],
        ),
      ),
    );
  }
}

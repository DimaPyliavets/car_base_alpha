import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:max_baza/add_entry_page.dart';
import 'package:max_baza/home_page/backend/home_logic.dart';
import 'package:max_baza/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeLogic _logic = HomeLogic();
  final TextEditingController _searchController = TextEditingController();

  bool _shouldRebuild = true;

  @override
  void initState() {
    super.initState();
    _logic.initSpeech();
    _logic.addListener(_onLogicChanged);
  }

  void _onLogicChanged() {
    if (mounted && _shouldRebuild) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _shouldRebuild = false;
    _searchController.dispose();
    _logic.removeListener(_onLogicChanged);
    _logic.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _logic.selectedIndex == 0 ? 'Search' : 'Add Entry',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 22,
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 4,
      actions: _logic.selectedIndex == 0 ? _buildAppBarActions() : null,
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _showImportExportMenu,
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.import_export,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _toggleScreenOrientation,
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _logic.isLandscape
                        ? Icons.screen_lock_portrait
                        : Icons.screen_lock_rotation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGlassFAB({
    required VoidCallback onPressed,
    required Widget child,
    required String heroTag,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.white12,
        border: Border.all(color: Colors.white38, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 6)),
        ],
      ),
      child: FloatingActionButton(
        mini: true,
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: child,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return CupertinoTabBar(
      border: Border(top: BorderSide(color: Colors.grey.shade800, width: 1)),
      height: 60.0,
      currentIndex: _logic.selectedIndex,
      onTap: _onDestinationSelected,
      iconSize: 24.0,
      activeColor: CupertinoColors.systemIndigo,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Entry'),
      ],
    );
  }

  void _onDestinationSelected(int index) {
    _logic.selectedIndex = index;
    if (index == 1) {
      _logic.searchQuery = '';
      _logic.stopListening();
    }
  }

  void _toggleScreenOrientation() {
    _logic.toggleScreenOrientation();
  }

  void _startListening() async {
    final result = await _logic.startListening();
    if (result != null && mounted) {
      _showMessage(result);
    }
  }

  void _stopListening() {
    _logic.stopListening();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.blueAccent,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    final result = await _logic.importFromExcel();
    if (result != null && mounted) {
      _showMessage(result);
    }
  }

  Future<void> _exportToExcel() async {
    final result = await _logic.exportToExcel();
    if (result != null && mounted) {
      _showMessage(result);
    }
  }

  void _showSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 280),
        child: Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Search Car',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Car number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  autofocus: true,
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _logic.searchQuery = result;
    }
    _searchController.clear();
  }

  void _showImportExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Data Management',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(
                Icons.file_upload,
                color: Colors.blueAccent,
                size: 24,
              ),
              title: const Text(
                'Import from Excel',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Restore data',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                _importFromExcel();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.file_download,
                color: Colors.greenAccent,
                size: 24,
              ),
              title: const Text(
                'Export to Excel',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Create backup',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Оптимізована побудова FAB
  Widget? _buildFloatingActionButtons() {
    if (_logic.selectedIndex != 0) return null;

    if (_logic.isLandscape) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground
                      .resolveFrom(context)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _showSearchDialog,
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 8),
                    CupertinoButton(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _logic.isListening
                          ? _stopListening
                          : _startListening,
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _logic.isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground
                      .resolveFrom(context)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _showSearchDialog,
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 8),
                    CupertinoButton(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _logic.isListening
                          ? _stopListening
                          : _startListening,
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _logic.isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SearchPage(
        searchQuery: _logic.searchQuery,
        onClearSearch: () => _logic.searchQuery = '',
        onExportToExcel: _exportToExcel,
        onImportFromExcel: _importFromExcel,
      ),
      const AddEntryPage(),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: _logic.isLandscape ? null : _buildAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
            ),
          ),
          child: Stack(
            children: [
              IndexedStack(index: _logic.selectedIndex, children: pages),
              if (_logic.isLandscape)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildGlassFAB(
                    onPressed: _toggleScreenOrientation,
                    child: const Icon(
                      Icons.screen_lock_portrait,
                      color: Colors.white,
                      size: 20,
                    ),
                    heroTag: 'orientationFab',
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButtons(),
        bottomNavigationBar: _logic.isLandscape ? null : _buildBottomNavBar(),
      ),
    );
  }
}

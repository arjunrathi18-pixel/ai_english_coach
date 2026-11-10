import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'practice_tab.dart';
import 'learn_tab.dart';
import 'profile_tab.dart';
import 'chat_screen.dart';
import 'profile_store.dart';

/// Bottom navigation: Home / Practice / AI Friend / Learn / Profile.
/// "AI Friend" opens a conversation directly instead of a tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openFriend() async {
    final profile = await ProfileStore.load();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        initialMode: 'friend',
        initialEstimatedLevel: profile?.overallLevel,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Tab index 2 is the AI Friend action; real tabs map 0,1,3,4.
    const pages = [HomeScreen(), PracticeTab(), SizedBox.shrink(), LearnTab(), ProfileTab()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 2) {
            _openFriend();
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'AI Friend'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

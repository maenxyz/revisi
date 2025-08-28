import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AppBarActions extends StatefulWidget {
  const AppBarActions({super.key});

  @override
  State<AppBarActions> createState() => _AppBarActionsState();
}

class _AppBarActionsState extends State<AppBarActions> {
  String? imageUrl;
  String? username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cache = await AuthService.instance.cachedProfile();
    setState(() {
      imageUrl = cache['imageUrl'];
      username = cache['username'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: _buildAvatar(),
      onSelected: (v) async {
        if (v == 'profile') {
          if (!mounted) return;
          await Navigator.of(context).pushNamed('/profile/edit');
          await _load();
        } else if (v == 'logout') {
          await AuthService.instance.logout();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Text('Edit Profile')),
        const PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
    );
  }

  Widget _buildAvatar() {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    if (hasImage) {
      return CircleAvatar(backgroundImage: NetworkImage(imageUrl!));
    }
    final initial = (username?.isNotEmpty ?? false) ? username![0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: Colors.red,
      child: Text(initial, style: const TextStyle(color: Colors.white)),
    );
  }
}

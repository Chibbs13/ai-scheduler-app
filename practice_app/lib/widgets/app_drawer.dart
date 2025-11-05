import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFF31D8A0) : const Color(0xFF27CE96);
    final textColor = Colors.black;

    return Drawer(
      backgroundColor: primaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 65),
          SizedBox(
            height: 200,
            child: Lottie.asset(
              'assets/animation1.json',
              fit: BoxFit.contain,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: textColor, size: 35),
            title: Text(
              'Profile',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            onTap: () {
              // TODO: Navigate to profile screen
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics_outlined, color: textColor, size: 35),
            title: Text(
              'Analytics',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            onTap: () {
              // TODO: Navigate to analytics screen
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: textColor, size: 35),
            title: Text(
              'Settings',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            onTap: () {
              // TODO: Navigate to settings screen
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

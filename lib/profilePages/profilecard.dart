// ignore_for_file: deprecated_member_use

import 'package:amira_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ProfileSettingCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  const ProfileSettingCard({super.key, required this.text, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.blue.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: mainColor,
        ),
      ),
      title: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: const Icon(
          LineAwesomeIcons.angle_right_solid,
          color: Colors.black87,
          
          size: 18,
        ),
      ),
    );
  }
}
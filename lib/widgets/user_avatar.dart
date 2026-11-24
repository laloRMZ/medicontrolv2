import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

ImageProvider? resolveProfileImage(String? rawImage) {
  if (rawImage == null || rawImage.trim().isEmpty) return null;
  if (rawImage.startsWith('data:image')) {
    final commaIndex = rawImage.indexOf(',');
    if (commaIndex != -1) {
      try {
        final Uint8List bytes = base64Decode(rawImage.substring(commaIndex + 1));
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
  }
  if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
    return NetworkImage(rawImage);
  }
  return null;
}

class UserAvatar extends StatelessWidget {
  final String? profileImage;
  final String fullName;
  final double radius;
  final Color backgroundColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.profileImage,
    required this.fullName,
    this.radius = 28,
    this.backgroundColor = Colors.blue,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = resolveProfileImage(profileImage);
    final initial =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : imageProvider == null
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: radius * 0.64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }
}

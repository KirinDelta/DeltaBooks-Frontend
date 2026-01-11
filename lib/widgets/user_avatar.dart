import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UserAvatar widget that displays user initials in a circular avatar
/// 
/// Takes a user's name (first_name, last_name) or email and extracts initials.
/// Example: 'John Doe' -> 'JD', 'john@example.com' -> 'JE'
class UserAvatar extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? email;
  final double size;
  final String? fallbackText;

  const UserAvatar({
    super.key,
    this.firstName,
    this.lastName,
    this.email,
    this.size = 32,
    this.fallbackText,
  });

  /// Extract initials from first name and last name
  /// If names are not available, extract from email
  /// Falls back to fallbackText or '?' if nothing is available
  String _getInitials() {
    // Try to get initials from first_name and last_name
    if (firstName != null && firstName!.isNotEmpty && 
        lastName != null && lastName!.isNotEmpty) {
      return '${firstName!.substring(0, 1).toUpperCase()}${lastName!.substring(0, 1).toUpperCase()}';
    }
    
    // If only first_name is available
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!.substring(0, 1).toUpperCase();
    }
    
    // If only last_name is available
    if (lastName != null && lastName!.isNotEmpty) {
      return lastName!.substring(0, 1).toUpperCase();
    }
    
    // Fallback to email initials
    if (email != null && email!.isNotEmpty) {
      final emailParts = email!.split('@');
      if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
        final localPart = emailParts[0];
        // If email has dots, get first letter of each part
        if (localPart.contains('.')) {
          final parts = localPart.split('.');
          if (parts.length >= 2) {
            return '${parts[0].substring(0, 1).toUpperCase()}${parts[1].substring(0, 1).toUpperCase()}';
          }
        }
        // Otherwise, get first letter
        if (localPart.length >= 2) {
          return localPart.substring(0, 2).toUpperCase();
        }
        return localPart.substring(0, 1).toUpperCase();
      }
    }
    
    // Ultimate fallback
    return fallbackText ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    // Use smaller font size for more refined look - 35% of avatar size for better proportion
    final fontSize = size * 0.35;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.deepSeaBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            height: 1.0, // Tighter line height for better centering
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

/// Helper utilities for MeetingPageV2
class MeetingHelpers {
  /// Get display name for a user with fallback logic
  /// Priority: Zoom userName → Backend userName → "Participant"
  static String getDisplayName(ZoomVideoSdkUser? user, {String? fallbackName}) {
    if (user == null) return fallbackName ?? 'Unknown';
    
    // 1. Try Zoom SDK userName
    final zoomName = user.userName?.trim() ?? '';
    if (zoomName.isNotEmpty && zoomName.toLowerCase() != 'participant') {
      return zoomName;
    }
    
    // 2. Try fallback name (from backend)
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      return fallbackName.trim();
    }
    
    // 3. Last resort
    return 'Participant';
  }
  
  /// Get short display name (first name only)
  static String getShortName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.first;
  }
  
  /// Check if name is generic/placeholder
  static bool isGenericName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.isEmpty || 
           normalized == 'participant' ||
           normalized == 'student' ||
           normalized == 'user' ||
           normalized == 'guest';
  }
}

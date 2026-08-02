/// Result of a contacts permission check or request.
enum PermissionStatus {
  /// Full access granted.
  granted,

  /// Partial access granted (e.g. iOS limited contacts).
  limited,

  /// Access denied; may be requested again.
  denied,

  /// Access denied and the user must change it in system settings.
  permanentlyDenied,

  /// Access restricted by parental controls or enterprise policy.
  restricted,

  /// Status could not be determined.
  unknown,
}

/// Scope of contacts permission to check or request.
enum PermissionMode {
  /// Read-only access to contacts.
  read,

  /// Read and write access to contacts.
  readWrite,
}

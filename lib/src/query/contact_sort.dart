/// Sort order for contact list and search results.
enum ContactSort {
  /// Alphabetical by display name, ascending (default).
  displayNameAsc,

  /// Alphabetical by display name, descending.
  displayNameDesc,

  /// Most recently updated first when the platform supports it.
  updatedAtDesc,
}

class AppException implements Exception {
  const AppException(
    this.userMessage, {
    this.cause,
    this.stackTrace,
  });

  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (cause != null) {
      return 'AppException: $userMessage (Cause: $cause)';
    }
    return 'AppException: $userMessage';
  }
}

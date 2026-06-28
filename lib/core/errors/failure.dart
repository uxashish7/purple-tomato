class Failure {
  final String message;
  final String? code;
  final Exception? exception;

  Failure(this.message, {this.code, this.exception});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

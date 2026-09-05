/// Thrown when an inbound message cannot be decoded.
class ProtocolError implements Exception {
  const ProtocolError(this.message, {this.type});

  final String message;
  final String? type;

  @override
  String toString() =>
      'ProtocolError: $message${type != null ? ' (type $type)' : ''}';
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Error returned by the API's JSON error envelope.
class ApiException implements Exception {
  const ApiException(
    this.status,
    this.code,
    this.message, {
    this.field,
    this.fields = const [],
  });

  final int status;
  final String code;
  final String message;
  final String? field;
  final List<FieldError> fields;

  @override
  String toString() => 'ApiException($status $code: $message)';
}

class FieldError {
  const FieldError(this.field, this.message);
  final String field;
  final String message;
}

/// Public table info for the join page.
class TableInfoDto {
  const TableInfoDto({
    required this.name,
    required this.state,
    required this.requiresPassword,
    required this.joinPolicy,
    required this.allowSpectators,
    required this.seated,
    required this.maxPlayers,
    required this.smallBlind,
    required this.bigBlind,
    this.takenSeats = const [],
  });

  factory TableInfoDto.fromJson(Map<String, dynamic> json) {
    final blinds = json['blinds'] as Map<String, dynamic>;
    final taken = json['taken_seats'] as List<dynamic>? ?? const [];
    return TableInfoDto(
      name: json['name'] as String,
      state: json['state'] as String,
      requiresPassword: json['requires_password'] as bool,
      joinPolicy: json['join_policy'] as String,
      allowSpectators: json['allow_spectators'] as bool,
      seated: json['seated'] as int,
      maxPlayers: json['max_players'] as int,
      smallBlind: blinds['small_blind'] as int,
      bigBlind: blinds['big_blind'] as int,
      takenSeats: [for (final s in taken) s as int],
    );
  }

  final String name;
  final String state;
  final bool requiresPassword;
  final String joinPolicy;
  final bool allowSpectators;
  final int seated;
  final int maxPlayers;
  final int smallBlind;
  final int bigBlind;

  /// Occupied seats, for the seat picker.
  final List<int> takenSeats;
}

class JoinResultDto {
  const JoinResultDto({
    required this.token,
    required this.playerId,
    required this.seat,
    required this.name,
  });
  final String token;
  final String playerId;
  final int seat;
  final String name;
}

/// Thin JSON client over the REST API.
class RestClient {
  RestClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base = baseUrl ?? AppConfig.restBase;

  final http.Client _client;
  final String _base;

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<Map<String, dynamic>> getJson(String path, {String? token}) async {
    final resp = await _client.get(_uri(path), headers: _headers(token));
    return _decode(resp);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Object? body, {
    String? token,
  }) async {
    final resp = await _client.post(
      _uri(path),
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Object? body, {
    String? token,
  }) async {
    final resp = await _client.patch(
      _uri(path),
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) async {
    final resp = await _client.delete(_uri(path), headers: _headers(token));
    return _decode(resp);
  }

  Map<String, String> _headers(String? token) =>
      token == null ? const {} : {'Authorization': 'Bearer $token'};

  Map<String, dynamic> _decode(http.Response resp) {
    Map<String, dynamic> json = const {};
    if (resp.body.isNotEmpty) {
      try {
        json = jsonDecode(resp.body) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(resp.statusCode, 'bad_response', 'invalid response');
      }
    }
    if (resp.statusCode >= 400) {
      final err = json['error'];
      if (err is Map<String, dynamic>) {
        final fields = <FieldError>[];
        final list = err['fields'];
        if (list is List) {
          for (final f in list) {
            if (f is Map<String, dynamic>) {
              fields.add(
                FieldError(
                  f['field'] as String? ?? '',
                  f['message'] as String? ?? '',
                ),
              );
            }
          }
        }
        throw ApiException(
          resp.statusCode,
          err['code'] as String? ?? 'error',
          err['message'] as String? ?? '',
          field: err['field'] as String?,
          fields: fields,
        );
      }
      throw ApiException(
        resp.statusCode,
        'http_${resp.statusCode}',
        'request failed',
      );
    }
    return json;
  }

  // ---- public endpoints -------------------------------------------------------------

  Future<TableInfoDto> tableInfo(String tableId) async =>
      TableInfoDto.fromJson(await getJson('/api/tables/$tableId/info'));

  /// STUN servers the instance hands to browsers for the voice chat.
  Future<List<String>> voiceStunUrls() async {
    try {
      final json = await getJson('/api/config');
      return [
        for (final u in json['voice_stun_urls'] as List<dynamic>? ?? const [])
          u as String,
      ];
    } on Object catch (_) {
      return const [];
    }
  }

  Future<JoinResultDto> join(
    String tableId, {
    required String name,
    String password = '',
    int? seat,
    int? avatar,
  }) async {
    final json = await postJson('/api/tables/$tableId/join', {
      'name': name,
      'password': password,
      'seat': ?seat,
      'avatar': ?avatar,
    });
    return JoinResultDto(
      token: json['player_token'] as String,
      playerId: json['player_id'] as String,
      seat: json['seat'] as int,
      name: json['name'] as String,
    );
  }

  Future<({String token, String name})> spectate(
    String tableId, {
    required String name,
    String password = '',
  }) async {
    final json = await postJson('/api/tables/$tableId/spectate', {
      'name': name,
      'password': password,
    });
    return (
      token: json['spectator_token'] as String,
      name: json['name'] as String,
    );
  }
}

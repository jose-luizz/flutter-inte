import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Erro com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP único do app: guarda o token e fala com a API Node.js.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Celular físico: coloque o IP do seu PC, ex.: 'http://192.168.0.10:3000'
  /// Em produção: o endereço do seu servidor (de preferência https).
  static const String _urlManual = '';

  String get baseUrl {
    if (_urlManual.isNotEmpty) return _urlManual;
    // Emulador Android enxerga o PC em 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // Chrome, Windows, iOS Simulator...
    return 'http://localhost:3000';
  }

  /// Fica só em memória: ao fechar o app, é preciso entrar de novo.
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) {
    return _send(
      () => http.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 10));
      final data =
          res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode >= 200 && res.statusCode < 300) return data;

      final msg = (data is Map && data['erro'] is String)
          ? data['erro'] as String
          : 'Erro inesperado (${res.statusCode}).';
      throw ApiException(msg);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder.');
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
  }
}

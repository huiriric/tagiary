import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final storage = const FlutterSecureStorage();
  static String get _baseUrl => dotenv.env['API_URL']!;
  static const String accessToken = 'access_token';

  static const String refreshToken = 'refresh_token';
  String? _access;
  String? _refresh;

  String get baseUrl => _baseUrl;
  String? get access => _access;
  String? get refresh => _refresh;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // accessToken 초기화
  Future<String?> getAccessToken() async {
    _access = await storage.read(key: accessToken);
    // print('get access token: $_access');
    return _access;
  }

  // refreshToken 초기화
  Future<void> getRefreshToken() async {
    _refresh = await storage.read(key: refreshToken);
    // print('get refresh_token: $_refresh');
  }

  // accessToken, refreshToken 저장
  Future<void> setTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await storage.write(key: accessToken, value: access);
    await storage.write(key: refreshToken, value: refresh);
    print('set accessToken: ${await storage.read(key: accessToken)}');
    print('set refreshToken: ${await storage.read(key: refreshToken)}');
  }

  Future<void> deleteTokens() async {
    await storage.delete(key: accessToken);
    await storage.delete(key: refreshToken);
    print('deleted accessToken: ${storage.read(key: accessToken)}');
    print('deleted refreshToken: ${storage.read(key: refreshToken)}');
  }

  Future<bool> refreshTokens() async {
    try {
      // Ensure we have the current refresh token
      await getRefreshToken();
      if (_refresh == null) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refresh}),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newAccess != null && newRefresh != null) {
          await setTokens(newAccess, newRefresh);
          return true;
        } else {
          await deleteTokens();
          return false;
        }
      } else {
        // Invalid/expired refresh token or server error -> remove stored tokens
        await deleteTokens();
        return false;
      }
    } catch (e) {
      print('refreshTokens error: $e');
      return false;
    }
  }

  Map<String, String> _getHeaders() {
    // print('_getHeaders: $_access');
    return {
      'Content-Type': 'application/json',
      'Accept-Charset': 'utf-8',
      if (_access != null) 'Authorization': 'Bearer $_access',
    };
  }

  Map<String, String> _getDeleteHeaders() {
    return {
      // 'accept': '*/*',
      if (_access != null) 'Authorization': 'Bearer $_access',
    };
  }

  Map<String, String> _getHeadersFormData() {
    // print('_getHeaders: $_access');
    return {
      'Content-Type': 'multipart/form-data',
      if (_access != null) 'Authorization': 'Bearer $_access',
    };
  }

  // GET 요청
  Future<http.Response> get(String endpoint,
      {Map<String, dynamic>? query}) async {
    Uri url;
    // print(endpoint);
    // print(query);
    if (query != null && query.isNotEmpty) {
      final queryParams =
          query.map((key, value) => MapEntry(key, value.toString()));
      url =
          Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    } else {
      url = Uri.parse('$baseUrl$endpoint');
    }
    print('get | $url');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    print(response.statusCode);

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        // 갱신된 토큰으로 재시도
        return await http.get(
          url,
          headers: _getHeaders(),
        );
      } else {
        print('Token refresh failed');
        return response; // 갱신 실패 시 원래 응답 반환
      }
    }

    // print(json.decode(utf8.decode(response.bodyBytes)));
    return response;
  }

  // POST 요청
  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('post | $url');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        return await http.post(
          url,
          headers: _getHeaders(),
          body: body != null ? json.encode(body) : null,
        );
      } else {
        print('Token refresh failed');
        return response;
      }
    }

    return response;
  }

  // FormData POST 요청
  Future<Response> postFormData(String endpoint, FormData data) async {
    final dio = Dio();
    final url = Uri.parse('$baseUrl$endpoint');
    print('formData post | $url');

    final response = await dio.post(
      '$baseUrl$endpoint',
      data: data,
      options: Options(headers: _getHeadersFormData()),
    );

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        return await dio.post(
          '$baseUrl$endpoint',
          data: data,
          options: Options(headers: _getHeadersFormData()),
        );
      } else {
        print('Token refresh failed');
        return response;
      }
    }

    return response;
  }

  // PATCH 요청
  Future<http.Response> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('patch | $url');

    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        return await http.patch(
          url,
          headers: _getHeaders(),
          body: body != null ? json.encode(body) : null,
        );
      } else {
        print('Token refresh failed');
        return response;
      }
    }

    return response;
  }

  // PUT 요청
  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('put | $url');

    final response = await http.put(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        return await http.put(
          url,
          headers: _getHeaders(),
          body: body != null ? json.encode(body) : null,
        );
      } else {
        print('Token refresh failed');
        return response;
      }
    }

    return response;
  }

  // DELETE 요청
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('delete | $url');

    final response = await http.delete(url, headers: _getDeleteHeaders());

    // 401 Unauthorized - 토큰 갱신 후 재시도
    if (response.statusCode == 401) {
      print('Access token expired, refreshing...');
      final bool refreshRes = await refreshTokens();
      if (refreshRes) {
        print('Token refreshed, retrying request...');
        return await http.delete(url, headers: _getDeleteHeaders());
      } else {
        print('Token refresh failed');
        return response;
      }
    }

    return response;
  }

  // 응답 처리 헬퍼 메소드
  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw HttpException('${response.statusCode}: ${response.body}');
    }
  }
}

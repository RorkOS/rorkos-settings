import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAuthService {
  static const String _clientId = 'YOUR_CLIENT_ID'; 
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  static const String _redirectUri = 'http://localhost:8080';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/contacts',
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/photoslibrary.readonly'
  ];

  static Future<String?> getAuthUrl() async {
    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': _scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
    };

    final queryString = Uri(queryParameters: params).query;
    return 'https://accounts.google.com/o/oauth2/v2/auth?$queryString';
  }

  static Future<Map<String, dynamic>?> exchangeCodeForTokens(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Ошибка получения токенов: $e');
      return null;
    }
  }

  static Future<bool> validateToken(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$accessToken'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_access_token', tokens['access_token']);
    await prefs.setString('google_refresh_token', tokens['refresh_token'] ?? '');
    
    final expiresIn = tokens['expires_in'];
    final expiryTime = DateTime.now().millisecondsSinceEpoch + ((expiresIn is int ? expiresIn : expiresIn.toInt()) * 1000);
    await prefs.setInt('google_token_expiry', expiryTime);
  }

  static Future<Map<String, String>?> getStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('google_access_token');
    final refreshToken = prefs.getString('google_refresh_token');
    final expiry = prefs.getInt('google_token_expiry');

    if (accessToken == null) return null;

    if (expiry != null && DateTime.now().millisecondsSinceEpoch > expiry) {
      if (refreshToken != null) {
        final newTokens = await refreshAccessToken(refreshToken);
        if (newTokens != null) {
          await saveTokens(newTokens);
          return {
            'access_token': newTokens['access_token'],
            'refresh_token': newTokens['refresh_token'] ?? refreshToken,
          };
        }
      }
      return null;
    }

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken ?? '',
    };
  }

  static Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Ошибка обновления токена: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_access_token');
    await prefs.remove('google_refresh_token');
    await prefs.remove('google_token_expiry');
  }

  static Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Ошибка получения информации о пользователе: $e');
      return null;
    }
  }
}

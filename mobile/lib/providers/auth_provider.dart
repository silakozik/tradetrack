import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Uygulama açılışında token var mı diye kontrol eder
  Future<void> tryAutoLogin() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    try {
      await ApiClient.post(
        ApiConstants.register,
        {
          "email": email,
          "password": password,
          "full_name": fullName,
        },
        useAuth: false,
      );
      _errorMessage = null;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final result = await ApiClient.post(
        ApiConstants.login,
        {"email": email, "password": password},
        useAuth: false,
      );

      final token = result["access_token"] as String;
      await SecureStorageService.saveToken(token);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.deleteToken();
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
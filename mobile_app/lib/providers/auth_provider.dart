import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final String? username;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.username,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(isAuthenticated: false, username: null, isLoading: false);
  }

  Future<void> checkAuth() async {
    await apiClient.init();
    if (apiClient.hasTokens()) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Use JWT token endpoint — no CSRF needed
      final response = await apiClient.post('/token/', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;
        if (accessToken != null) {
          await apiClient.setTokens(accessToken, refreshToken);
        }
        state = AuthState(
          isAuthenticated: true,
          username: username,
          isLoading: false,
        );
        return true;
      } else {
        String errorMsg = 'Login failed';
        try {
          final data = jsonDecode(response.body);
          // JWT endpoint returns {"detail": "No active account found..."}
          errorMsg = data['detail'] ?? data['error'] ?? errorMsg;
        } catch (_) {}
        state = AuthState(isLoading: false, isAuthenticated: false, error: errorMsg);
        return false;
      }
    } catch (e) {
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        error: 'Network error: Cannot connect to server.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await apiClient.clearTokens();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

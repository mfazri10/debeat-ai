import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role;
  final int eloRating;
  final int totalPoints;
  final bool isPro;
  final int warningCount;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.eloRating,
    required this.totalPoints,
    required this.isPro,
    required this.warningCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      eloRating: json['elo_rating'] as int? ?? 1000,
      totalPoints: json['total_points'] as int? ?? 0,
      isPro: json['is_pro'] as bool? ?? false,
      warningCount: json['warning_count'] as int? ?? 0,
    );
  }
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfile? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final res = await _apiClient.get(ApiEndpoints.me);
      if (res.statusCode == 200) {
        final user = UserProfile.fromJson(res.data['user']);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final token = res.data['access_token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        final user = UserProfile.fromJson(res.data['user']);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email atau kata sandi tidak valid',
      );
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    state = AuthState();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});

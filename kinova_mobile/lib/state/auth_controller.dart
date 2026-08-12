import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  static const _tokenKey = 'kinova_customer_token';

  final ApiClient _api;
  AppUser? _user;
  bool _booting = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get booting => _booting;
  String? get error => _error;

  Future<void> bootstrap() async {
    await Future<void>.delayed(Duration.zero);
    _booting = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        _user = null;
        return;
      }
      _api.setToken(token);
      final me = await _api.get('/auth/me');
      if (me is Map<String, dynamic>) {
        _user = AppUser.fromJson(me);
      } else if (me is Map) {
        _user = AppUser.fromJson(Map<String, dynamic>.from(me));
      }
    } catch (_) {
      await _clearToken();
      _user = null;
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  /// Connexion par email **ou** numéro de téléphone.
  Future<void> login(String identifier, String password) async {
    _error = null;
    notifyListeners();
    final res = await _api.post('/customer/auth/login', body: {
      'login': identifier.trim(),
      'password': password,
    });
    await _applyAuth(res);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    _error = null;
    notifyListeners();
    final trimmedEmail = email?.trim() ?? '';
    final res = await _api.post('/customer/auth/register', body: {
      'name': name.trim(),
      'phone': phone.trim(),
      'password': password,
      'password_confirmation': password,
      if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
    });
    await _applyAuth(res);
  }

  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;
    final res = await _api.get('/customer/profile');
    final data = res is Map && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : Map<String, dynamic>.from(res as Map);
    _user = AppUser.fromJson(data);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? city,
    String? password,
    String? currentPassword,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'email': (email ?? '').trim().isEmpty ? null : email!.trim(),
      'address': (address ?? '').trim().isEmpty ? null : address!.trim(),
      'city': (city ?? '').trim().isEmpty ? null : city!.trim(),
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = password;
      body['current_password'] = currentPassword ?? '';
    }
    final res = await _api.put('/customer/profile', body: body);
    final data = res is Map && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : Map<String, dynamic>.from(res as Map);
    _user = AppUser.fromJson(data);
    notifyListeners();
  }

  Future<void> uploadAvatar(File file) async {
    final res = await _api.postMultipart(
      '/customer/profile/avatar',
      field: 'avatar',
      file: file,
    );
    final data = res is Map && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : Map<String, dynamic>.from(res as Map);
    _user = AppUser.fromJson(data);
    notifyListeners();
  }

  /// Suppression définitive — le code de confirmation doit être `kinovaci`.
  Future<void> deleteAccount(String confirmationCode) async {
    await _api.post('/customer/profile/delete', body: {
      'confirmation_code': confirmationCode.trim(),
    });
    await _clearToken();
    _user = null;
    notifyListeners();
  }

  Future<List<Order>> fetchOrders() async {
    if (!isLoggedIn) return const [];
    final res = await _api.get('/customer/orders');
    final list = res is Map && res['data'] is List ? res['data'] as List : const [];
    return list
        .whereType<Map>()
        .map((e) => ApiOrderParser.parse(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> logout() async {
    try {
      if (_api.token != null) {
        await _api.post('/auth/logout');
      }
    } catch (_) {
      // ignore network logout errors
    }
    await _clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> _applyAuth(dynamic res) async {
    if (res is! Map) throw Exception('Réponse auth invalide');
    final token = res['token']?.toString();
    final userRaw = res['user'];
    if (token == null || userRaw is! Map) {
      throw Exception('Identifiants incorrects');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.setToken(token);
    _user = AppUser.fromJson(Map<String, dynamic>.from(userRaw));
    notifyListeners();
  }

  Future<void> _clearToken() async {
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

/// Avoid circular import with api_mappers in auth file for orders list.
class ApiOrderParser {
  static Order parse(Map<String, dynamic> json) {
    final items = <CartItem>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        items.add(
          CartItem(
            product: Product(
              id: '${map['product_id'] ?? ''}',
              name: (map['product_name'] ?? '').toString(),
              description: '',
              price: double.tryParse('${map['unit_price']}') ?? 0,
              categoryId: '',
              imageUrl: '',
            ),
            quantity: int.tryParse('${map['quantity']}') ?? 1,
          ),
        );
      }
    }

    String label(String status) => switch (status) {
          'pending' => 'En attente',
          'processing' => 'En préparation',
          'shipped' => 'Expédiée',
          'delivered' => 'Livrée',
          'cancelled' => 'Annulée',
          _ => status,
        };

    return Order(
      id: (json['reference'] ?? json['id'] ?? '').toString(),
      items: items,
      total: double.tryParse('${json['total']}') ?? 0,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      status: label((json['status'] ?? 'pending').toString()),
      trackingNumber: json['tracking_number']?.toString(),
      carrier: json['carrier']?.toString(),
    );
  }
}

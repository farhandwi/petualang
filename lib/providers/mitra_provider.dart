import 'package:flutter/foundation.dart';
import '../services/mitra_service.dart';

class MitraProvider extends ChangeNotifier {
  final MitraService _service = MitraService();
  String? _token;

  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
  }

  Map<String, dynamic>? _vendor;
  Map<String, dynamic>? get vendor => _vendor;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => _orders;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? get stats => _stats;

  int _pendingOrderCount = 0;
  int get pendingOrderCount => _pendingOrderCount;

  /// Hitung order yang masih `pending` agar bisa ditampilkan sebagai badge.
  Future<void> refreshPendingOrderCount() async {
    if (_token == null) return;
    final pending = await _service.getOrders(_token!, status: 'pending');
    _pendingOrderCount = pending.length;
    notifyListeners();
  }

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetchVendor() async {
    if (_token == null) return;
    _setLoading(true);
    _vendor = await _service.getVendor(_token!);
    _setLoading(false);
  }

  Future<bool> updateVendor(Map<String, dynamic> body) async {
    if (_token == null) return false;
    final ok = await _service.updateVendor(_token!, body);
    if (ok) await fetchVendor();
    return ok;
  }

  Future<void> fetchItems() async {
    if (_token == null) return;
    _setLoading(true);
    _items = await _service.getItems(_token!);
    _setLoading(false);
  }

  Future<bool> createItem(Map<String, dynamic> body) async {
    if (_token == null) return false;
    final ok = await _service.createItem(_token!, body);
    if (ok) await fetchItems();
    return ok;
  }

  Future<bool> updateItem(int id, Map<String, dynamic> body) async {
    if (_token == null) return false;
    final ok = await _service.updateItem(_token!, id, body);
    if (ok) await fetchItems();
    return ok;
  }

  Future<bool> deleteItem(int id) async {
    if (_token == null) return false;
    final ok = await _service.deleteItem(_token!, id);
    if (ok) {
      _items.removeWhere((it) => it['id'] == id);
      notifyListeners();
    }
    return ok;
  }

  Future<void> fetchOrders({String status = 'all'}) async {
    if (_token == null) return;
    _setLoading(true);
    _orders = await _service.getOrders(_token!, status: status);
    if (status == 'pending') {
      _pendingOrderCount = _orders.length;
    } else if (status == 'all') {
      _pendingOrderCount = _orders.where((o) => o['status'] == 'pending').length;
    }
    _setLoading(false);
  }

  Future<Map<String, dynamic>?> fetchOrderDetail(int id) async {
    if (_token == null) return null;
    return _service.getOrderDetail(_token!, id);
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    if (_token == null) return false;
    final ok = await _service.updateOrderStatus(_token!, id, status);
    if (ok) {
      final idx = _orders.indexWhere((o) => o['id'] == id);
      if (idx >= 0) {
        _orders[idx]['status'] = status;
      }
      _pendingOrderCount = _orders.where((o) => o['status'] == 'pending').length;
      notifyListeners();
    }
    return ok;
  }

  Future<void> fetchStats() async {
    if (_token == null) return;
    _setLoading(true);
    _stats = await _service.getStats(_token!);
    _setLoading(false);
  }
}

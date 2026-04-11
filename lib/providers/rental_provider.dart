import 'package:flutter/material.dart';
import '../models/mountain_model.dart';
import '../models/rental_model.dart';
import '../services/rental_service.dart';

class RentalProvider extends ChangeNotifier {
  final RentalService _service = RentalService();

  List<RentalItemModel> _items = [];
  List<RentalItemModel> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';

  // Pre-requisites for rental mapping (Mountain, routes, dates)
  MountainModel? _selectedMountain;
  MountainModel? get selectedMountain => _selectedMountain;

  RouteModel? _entryRoute;
  RouteModel? get entryRoute => _entryRoute;

  RouteModel? _exitRoute;
  RouteModel? get exitRoute => _exitRoute;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  double get deliveryFee {
    if (_entryRoute != null && _exitRoute != null && _entryRoute!.id != _exitRoute!.id) {
      return 50000.0; // Biaya beda pos
    }
    return 0.0;
  }

  void setRentalTarget({
    required MountainModel mountain,
    required DateTime start,
    required DateTime end,
    required RouteModel entry,
    required RouteModel exit,
  }) {
    _selectedMountain = mountain;
    _startDate = start;
    _endDate = end;
    _entryRoute = entry;
    _exitRoute = exit;
    notifyListeners();
  }

  void clearRentalTarget() {
    _selectedMountain = null;
    _startDate = null;
    _endDate = null;
    _entryRoute = null;
    _exitRoute = null;
    _items.clear();
    notifyListeners();
  }

  // Cart
  final List<RentalCartItem> _cart = [];
  List<RentalCartItem> get cart => _cart;

  void setCategory(String category) {
    _selectedCategory = category;
    fetchItems();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<RentalItemModel> get filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((item) => item.name.toLowerCase().contains(_searchQuery)).toList();
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _service.getRentalItems(
      category: _selectedCategory,
      mountainId: _selectedMountain?.id,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Cart Actions
  void addToCart(RentalItemModel item, int quantity) {
    final existingIndex = _cart.indexWhere((c) => c.item.id == item.id);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(RentalCartItem(item: item, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(int itemId) {
    _cart.removeWhere((c) => c.item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(int itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(itemId);
      return;
    }
    final existingIndex = _cart.indexWhere((c) => c.item.id == itemId);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  int get totalItemsInCart => _cart.fold(0, (sum, item) => sum + item.quantity);

  Future<Map<String, dynamic>> checkout({
    required String token,
  }) async {
    if (_startDate == null || _endDate == null) {
      return {'success': false, 'message': 'Tanggal sewa belum dipilih.'};
    }

    final days = _endDate!.difference(_startDate!).inDays;
    // minimal sewa dihitung 1 hari walaupun return di hari yg sama
    final validDays = days >= 0 ? days + 1 : 1;

    double total = 0;
    for (var c in _cart) {
      total += c.item.pricePerDay * c.quantity * validDays;
    }
    
    // Add delivery fee
    total += deliveryFee;

    return await _service.checkoutRental(
      token: token,
      startDate: _startDate!,
      endDate: _endDate!,
      totalPrice: total,
      deliveryFee: deliveryFee,
      mountainId: _selectedMountain?.id,
      entryRouteId: _entryRoute?.id,
      exitRouteId: _exitRoute?.id,
      cartItems: _cart,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/mountain_model.dart';
import '../models/rental_model.dart';
import '../models/vendor_model.dart';
import '../services/location_service.dart';
import '../services/rental_service.dart';

enum VendorSortMode { nearest, topRated }

class RentalProvider extends ChangeNotifier {
  final RentalService _service = RentalService();

  List<VendorModel> _vendors = [];
  /// Only show vendors within 100km radius (green zone)
  static const double _maxRadiusKm = 100.0;

  // ── Vendor sort & filter state ──
  VendorSortMode _vendorSortMode = VendorSortMode.nearest;
  VendorSortMode get vendorSortMode => _vendorSortMode;

  bool _showOpenOnly = true; // default: hanya tampilkan yang buka
  bool get showOpenOnly => _showOpenOnly;

  void setVendorSortMode(VendorSortMode mode) {
    _vendorSortMode = mode;
    _resetVendorPagination();
    notifyListeners();
  }

  void toggleShowOpenOnly() {
    _showOpenOnly = !_showOpenOnly;
    _resetVendorPagination();
    notifyListeners();
  }

  List<VendorModel> get vendors {
    // 1. Filter radius — HANYA aktif saat mode Terdekat
    //    Mode Rating Tertinggi: tampilkan SEMUA vendor tanpa batas jarak
    var list = _vendorSortMode == VendorSortMode.nearest
        ? _vendors
            .where((v) => v.distance == null || v.distance! < _maxRadiusKm)
            .toList()
        : List<VendorModel>.from(_vendors);

    // 2. Filter buka sekarang (jika aktif)
    if (_showOpenOnly) {
      list = list.where((v) => v.isOpen).toList();
    }

    // 3. Sort
    switch (_vendorSortMode) {
      case VendorSortMode.nearest:
        list.sort((a, b) {
          final da = a.distance ?? double.infinity;
          final db = b.distance ?? double.infinity;
          return da.compareTo(db);
        });
        break;
      case VendorSortMode.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return list;
  }

  VendorModel? _selectedVendor;
  VendorModel? get selectedVendor => _selectedVendor;

  List<RentalItemModel> _items = [];
  List<RentalItemModel> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Lazy loading vendor ──
  static const int _pageSize = 20;
  int _vendorPage = 1;
  bool _isLoadingMore = false;

  bool get isLoadingMore => _isLoadingMore;

  /// Vendor yang ditampilkan — slice dari daftar lengkap yang sudah di-sort/filter
  List<VendorModel> get vendorsPage {
    final all = vendors;
    final end = (_vendorPage * _pageSize).clamp(0, all.length);
    return all.sublist(0, end);
  }

  bool get hasMoreVendors {
    final all = vendors;
    return (_vendorPage * _pageSize) < all.length;
  }

  void loadMoreVendors() {
    if (_isLoadingMore || !hasMoreVendors) return;
    _isLoadingMore = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 400), () {
      _vendorPage++;
      _isLoadingMore = false;
      notifyListeners();
    });
  }

  void _resetVendorPagination() {
    _vendorPage = 1;
  }


  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';

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
      return 50000.0;
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
    _selectedVendor = null;
    _items.clear();
    notifyListeners();
  }

  void setRentalDates(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
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

    try {
      _items = await _service.getRentalItems(
        category: _selectedCategory,
        mountainId: _selectedMountain?.id,
        vendorId: _selectedVendor?.id,
      );
    } catch (e) {
      print('fetchItems error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Location
  String _currentLocationName = 'Jakarta Pusat';
  String get currentLocationName => _currentLocationName;
  double _userLat = -6.2088;
  double _userLng = 106.8456;

  bool _vendorsFetched = false;

  Future<void> fetchVendors({String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Always fetch with current coords (defaults to Jakarta)
      _vendors = await _service.getVendors(
        lat: _userLat,
        lng: _userLng,
        query: query ?? (_searchQuery.isNotEmpty ? _searchQuery : null),
      );
    } catch (e) {
      print('fetchVendors error: $e');
      _vendors = [];
    }

    _isLoading = false;
    _vendorsFetched = true;
    _resetVendorPagination();
    notifyListeners();

    // Try GPS in background, only once
    if (!_vendorsFetched || query == null) {
      _tryUpdateLocationInBackground();
    }
  }

  Future<void> _tryUpdateLocationInBackground() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final newLat = position.latitude;
      final newLng = position.longitude;

      // Update name via Nominatim
      final name = await LocationService.reverseGeocode(newLat, newLng);

      _userLat = newLat;
      _userLng = newLng;
      _currentLocationName = name ?? 'Lokasi Terkini';

      // Refetch vendors with real GPS coords
      final updated = await _service.getVendors(lat: newLat, lng: newLng);
      _vendors = updated;
      notifyListeners();
    } catch (e) {
      print('GPS background update failed: $e');
    }
  }

  void setLocationFromSearch(LocationResult loc) {
    _userLat = loc.lat;
    _userLng = loc.lng;
    _currentLocationName = loc.shortName;
    fetchVendors();
  }

  void selectVendor(VendorModel vendor) {
    _selectedVendor = vendor;
    _selectedCategory = 'Semua';
    fetchItems();
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

  Future<Map<String, dynamic>> checkout({required String token}) async {
    if (_startDate == null || _endDate == null) {
      return {'success': false, 'message': 'Tanggal sewa belum dipilih.'};
    }

    final days = _endDate!.difference(_startDate!).inDays;
    final validDays = days >= 0 ? days + 1 : 1;

    double total = 0;
    for (var c in _cart) {
      total += c.item.pricePerDay * c.quantity * validDays;
    }
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


import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final _db = FirebaseDatabase.instance.ref();
  final _uuid = const Uuid();

  String get _newId => _uuid.v4().replaceAll('-', '').substring(0, 8);

  // ──────────────────────────── OWNER ────────────────────────────────────────

  Future<bool> validateOwner(String username, String password) async {
    final snap = await _db.child('owner').get();
    if (!snap.exists) {
      // First-time setup: create owner with default credentials
      await _db.child('owner').set({
        'username': 'HamzaOwner',
        'password': 'Hamza@1234',
      });
      // Check if entered credentials match the defaults
      return username == 'HamzaOwner' && password == 'Hamza@1234';
    }
    final data = snap.value as Map<dynamic, dynamic>;
    return data['username'] == username && data['password'] == password;
  }

  Future<void> updateOwnerCredentials({
    required String username,
    required String password,
  }) async {
    await _db.child('owner').update({
      'username': username,
      'password': password,
    });
  }

  Stream<Map<String, dynamic>> ownerCredentialsStream() {
    return _db.child('owner').onValue.map((event) {
      if (!event.snapshot.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  // ──────────────────────────── CUSTOMERS ────────────────────────────────────

  /// Returns existing customer or creates new one
  Future<Customer> loginOrRegisterCustomer(String name, String phone) async {
    final snap = await _db
        .child('customers')
        .orderByChild('phone')
        .equalTo(phone)
        .get();

    if (snap.exists) {
      final map = snap.value as Map<dynamic, dynamic>;
      final entry = map.entries.first;
      return Customer.fromMap(entry.key as String, entry.value as Map);
    }

    // New customer
    final id = _newId;
    final customer = Customer(
      id: id,
      name: name,
      phone: phone,
      totalDue: 0,
      memberSince: DateTime.now(),
    );
    await _db.child('customers/$id').set(customer.toMap());
    return customer;
  }

  Stream<Customer> customerStream(String customerId) {
    return _db.child('customers/$customerId').onValue.map((event) {
      if (!event.snapshot.exists) throw Exception('Customer not found');
      return Customer.fromMap(
          customerId, event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  Future<Customer?> getCustomer(String customerId) async {
    final snap = await _db.child('customers/$customerId').get();
    if (!snap.exists) return null;
    return Customer.fromMap(customerId, snap.value as Map<dynamic, dynamic>);
  }

  Stream<List<Customer>> customersStream() {
    return _db.child('customers').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => Customer.fromMap(
          e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> updateCustomerDue(String customerId, double delta) async {
    final snap = await _db.child('customers/$customerId/totalDue').get();
    final current = (snap.value as num?)?.toDouble() ?? 0;
    await _db.child('customers/$customerId/totalDue').set(current + delta);
  }

  Future<int> getTotalCustomers() async {
    final snap = await _db.child('customers').get();
    if (!snap.exists) return 0;
    return (snap.value as Map).length;
  }

  // ──────────────────────────── ORDERS ───────────────────────────────────────

  Future<StoreOrder> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String itemsText,
    String? notes,
  }) async {
    final id = _newId;
    final order = StoreOrder(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      itemsText: itemsText,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
    );
    await _db.child('orders/$id').set(order.toMap());
    return order;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.child('orders/$orderId/status').set(status.index);
  }

  Future<void> updateOrderWithAmount(
      String orderId, double amount, PaymentMethod? method) async {
    await _db.child('orders/$orderId').update({
      'status': OrderStatus.delivered.index,
      'totalAmount': amount,
    });
  }

  Stream<List<StoreOrder>> ordersStream() {
    return _db.child('orders').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => StoreOrder.fromMap(
          e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<StoreOrder>> customerOrdersStream(String customerId) {
    return _db
        .child('orders')
        .orderByChild('customerId')
        .equalTo(customerId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => StoreOrder.fromMap(
          e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<StoreOrder?> orderStream(String orderId) {
    return _db.child('orders/$orderId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return StoreOrder.fromMap(
          orderId, event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  Future<int> getPendingCount() async {
    final snap = await _db
        .child('orders')
        .orderByChild('status')
        .equalTo(0)
        .get();
    if (!snap.exists) return 0;
    return (snap.value as Map).length;
  }

  Future<int> getTotalOrders() async {
    final snap = await _db.child('orders').get();
    if (!snap.exists) return 0;
    return (snap.value as Map).length;
  }

  // ──────────────────────────── TRANSACTIONS ─────────────────────────────────

  Future<KhataTransaction> addTransaction({
    required String customerId,
    required TransactionType type,
    required double amount,
    required String reason,
    String? orderId,
    PaymentMethod? paymentMethod,
  }) async {
    final id = _newId;
    final tx = KhataTransaction(
      id: id,
      customerId: customerId,
      type: type,
      amount: amount,
      reason: reason,
      date: DateTime.now(),
      orderId: orderId,
      paymentMethod: paymentMethod,
    );
    await _db.child('transactions/$id').set(tx.toMap());
    return tx;
  }

  Stream<List<KhataTransaction>> customerTransactionsStream(
      String customerId) {
    return _db
        .child('transactions')
        .orderByChild('customerId')
        .equalTo(customerId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => KhataTransaction.fromMap(
          e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<double> getTotalDueAmount() async {
    final snap = await _db.child('customers').get();
    if (!snap.exists) return 0;
    final map = snap.value as Map<dynamic, dynamic>;
    double total = 0;
    for (final v in map.values) {
      total += ((v as Map)['totalDue'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ──────────────────────────── DASHBOARD STREAMS ────────────────────────────

  Stream<Map<String, dynamic>> dashboardStream() {
    return _db.onValue.map((event) {
      if (!event.snapshot.exists) {
        return {
          'totalCustomers': 0,
          'totalOrders': 0,
          'pendingOrders': 0,
          'totalDue': 0.0,
          'recentOrders': <StoreOrder>[],
        };
      }
      final root = event.snapshot.value as Map<dynamic, dynamic>;

      final customers = root['customers'] as Map? ?? {};
      final orders = root['orders'] as Map? ?? {};

      final allOrders = orders.entries
          .map((e) => StoreOrder.fromMap(
          e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final pendingCount =
          allOrders.where((o) => o.status == OrderStatus.pending).length;

      double totalDue = 0;
      for (final v in customers.values) {
        totalDue += ((v as Map)['totalDue'] as num?)?.toDouble() ?? 0;
      }

      return {
        'totalCustomers': customers.length,
        'totalOrders': orders.length,
        'pendingOrders': pendingCount,
        'totalDue': totalDue,
        'recentOrders': allOrders.take(5).toList(),
      };
    });
  }
}
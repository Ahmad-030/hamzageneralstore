import 'package:flutter/material.dart';

// ─── ENUMS ───────────────────────────────────────────────────────────────────

enum OrderStatus { pending, accepted, preparing, delivered, rejected }

enum TransactionType { order, payment }

enum PaymentMethod { cash, easypaisa, jazzcash, bankTransfer }

// ─── CUSTOMER ────────────────────────────────────────────────────────────────

class Customer {
  final String id;
  String name;
  String phone;
  double totalDue;
  final DateTime memberSince;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.totalDue = 0,
    required this.memberSince,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'totalDue': totalDue,
        'memberSince': memberSince.toIso8601String(),
      };

  factory Customer.fromMap(String id, Map<dynamic, dynamic> m) => Customer(
        id: id,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        totalDue: (m['totalDue'] as num?)?.toDouble() ?? 0,
        memberSince: DateTime.tryParse(m['memberSince'] ?? '') ?? DateTime.now(),
      );
}

// ─── ORDER ───────────────────────────────────────────────────────────────────

class StoreOrder {
  final String id;
  final String customerId;
  String customerName;
  String customerPhone;
  final String itemsText;
  OrderStatus status;
  final DateTime createdAt;
  double? totalAmount;
  String? notes;

  StoreOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.itemsText,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.totalAmount,
    this.notes,
  });

  List<String> get itemsList => itemsText
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  String get orderNumber {
    final short = id.length > 4 ? id.substring(id.length - 4) : id;
    return '#${short.toUpperCase()}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'itemsText': itemsText,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'totalAmount': totalAmount,
        'notes': notes,
      };

  factory StoreOrder.fromMap(String id, Map<dynamic, dynamic> m) => StoreOrder(
        id: id,
        customerId: m['customerId'] ?? '',
        customerName: m['customerName'] ?? '',
        customerPhone: m['customerPhone'] ?? '',
        itemsText: m['itemsText'] ?? '',
        status: OrderStatus.values[(m['status'] as int?) ?? 0],
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
        totalAmount: (m['totalAmount'] as num?)?.toDouble(),
        notes: m['notes'],
      );
}

// ─── TRANSACTION ─────────────────────────────────────────────────────────────

class KhataTransaction {
  final String id;
  final String customerId;
  final TransactionType type;
  final double amount;
  final String reason;
  final DateTime date;
  final String? orderId;
  final PaymentMethod? paymentMethod;

  KhataTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.date,
    this.orderId,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'type': type.index,
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String(),
        'orderId': orderId,
        'paymentMethod': paymentMethod?.index,
      };

  factory KhataTransaction.fromMap(String id, Map<dynamic, dynamic> m) =>
      KhataTransaction(
        id: id,
        customerId: m['customerId'] ?? '',
        type: TransactionType.values[(m['type'] as int?) ?? 0],
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        reason: m['reason'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        orderId: m['orderId'],
        paymentMethod: m['paymentMethod'] != null
            ? PaymentMethod.values[m['paymentMethod'] as int]
            : null,
      );
}

// ─── EXTENSIONS ──────────────────────────────────────────────────────────────

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:   return 'Pending';
      case OrderStatus.accepted:  return 'Accepted';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.rejected:  return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:   return const Color(0xFFF59E0B);
      case OrderStatus.accepted:  return const Color(0xFF2563EB);
      case OrderStatus.preparing: return const Color(0xFFF97316);
      case OrderStatus.delivered: return const Color(0xFF22C55E);
      case OrderStatus.rejected:  return const Color(0xFFEF4444);
    }
  }
}

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.easypaisa:    return 'EasyPaisa';
      case PaymentMethod.jazzcash:     return 'JazzCash';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:         return Icons.payments_rounded;
      case PaymentMethod.easypaisa:    return Icons.phone_android_rounded;
      case PaymentMethod.jazzcash:     return Icons.phone_android_rounded;
      case PaymentMethod.bankTransfer: return Icons.account_balance_rounded;
    }
  }
}

// lib/orders/order_list_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'order_detail_screen.dart';
import 'profile_screen.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('orders');
  late TabController _tabController;
  StreamSubscription<DatabaseEvent>? _orderSubscription;
  Map<String, int> orderCounts = {
    'Chờ xác nhận': 0,
    'Chờ lấy hàng': 0,
    'Chờ giao hàng': 0,
    'Đánh giá': 0,
  };
  List<Map<String, dynamic>>? cachedOrders; // Lưu trữ danh sách đơn hàng để giữ dữ liệu

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders(); // Tải danh sách đơn hàng khi khởi tạo
  }

  void _loadOrders() {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Hủy subscription cũ để tránh lỗi "Stream has already been listened to"
    _orderSubscription?.cancel();
    Stream<DatabaseEvent> orderStream = _database
        .orderByChild('userId')
        .equalTo(user.uid)
        .onValue;

    _orderSubscription = orderStream.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        setState(() {
          cachedOrders = [];
          orderCounts.updateAll((key, value) => 0);
        });
        print("No orders found for user ${user.uid}");
        return;
      }

      Map<dynamic, dynamic> orders = event.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> orderList = [];
      orderCounts.updateAll((key, value) => 0); // Reset counts

      orders.forEach((key, value) {
        if (value is Map && value['status'] is String) {
          String status = value['status'] as String;
          orderList.add(Map<String, dynamic>.from(value)..['id'] = key);
          orderCounts.update(status, (value) => value + 1, ifAbsent: () => 1);
        } else {
          print("Invalid order data for key $key: $value");
        }
      });

      // Sắp xếp đơn hàng theo ngày đặt (mới nhất trước)
      orderList.sort((a, b) => (b['date'] ?? 0).compareTo(a['date'] ?? 0));

      setState(() {
        cachedOrders = orderList;
      });
    }, onError: (error) {
      print("Error listening to order stream: $error");
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel(); // Hủy subscription khi dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text('Đơn hàng của tôi', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _buildTab("🕒 Chờ xác nhận", orderCounts['Chờ xác nhận'] ?? 0),
            _buildTab("📦 Chờ lấy hàng", orderCounts['Chờ lấy hàng'] ?? 0),
            _buildTab("🚚 Chờ giao hàng", orderCounts['Chờ giao hàng'] ?? 0),
            _buildTab("⭐ Đánh giá", orderCounts['Đánh giá'] ?? 0),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('Chờ xác nhận'),
          _buildOrderList('Chờ lấy hàng'),
          _buildOrderList('Chờ giao hàng'),
          _buildOrderList('Đánh giá'),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    if (cachedOrders == null) {
      return Center(child: CircularProgressIndicator()); // Hiển thị loading nếu chưa tải dữ liệu
    }

    List<Map<String, dynamic>> filteredOrders = cachedOrders!.where((order) {
      return order['status'] == status;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Bạn chưa có đơn hàng nào ở trạng thái '$status'.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              child: Text("Mua sắm ngay"),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: filteredOrders.map((order) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(_getIconForStatus(order['status']), color: Colors.amber, size: 30),
            title: Text("Đơn hàng #${order['id']}", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "Ngày đặt: ${DateTime.fromMillisecondsSinceEpoch(order['date'])} - Trạng thái: ${order['status']}",
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Icons.pending_actions;
      case 'Chờ lấy hàng':
        return Icons.store;
      case 'Chờ giao hàng':
        return Icons.local_shipping;
      case 'Đánh giá':
        return Icons.star_border;
      default:
        return Icons.help_outline;
    }
  }
}
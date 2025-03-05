
import 'package:app_selling_shoes/orders/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  int pendingOrders = 0;
  int readyToShipOrders = 0;
  int shippingOrders = 0;
  int reviewOrders = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getOrderCounts();
  }

  void _getOrderCounts() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('orders').where('userId', isEqualTo: user.uid).snapshots().listen((snapshot) {
        int pending = 0;
        int readyToShip = 0;
        int shipping = 0;
        int review = 0;

        for (var doc in snapshot.docs) {
          String status = doc['status'];
          if (status == 'Chờ xác nhận') pending++;
          if (status == 'Chờ lấy hàng') readyToShip++;
          if (status == 'Chờ giao hàng') shipping++;
          if (status == 'Đánh giá') review++;
        }

        setState(() {
          pendingOrders = pending;
          readyToShipOrders = readyToShip;
          shippingOrders = shipping;
          reviewOrders = review;
        });
      });
    }
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
        title: const Text('Đơn hàng của tôi', style: TextStyle(color: Colors.white)),
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
            _buildTab("🕒 Chờ xác nhận", pendingOrders),
            _buildTab("📦 Chờ lấy hàng", readyToShipOrders),
            _buildTab("🚚 Chờ giao hàng", shippingOrders),
            _buildTab("⭐ Đánh giá", reviewOrders),
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
    User? user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('userId', isEqualTo: user?.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có đơn hàng nào"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.docs.map((doc) {
            final order = doc.data() as Map<String, dynamic>;
            order['id'] = doc.id;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(_getIconForStatus(order['status']), color: Colors.amber, size: 30),
                title: Text("Đơn hàng #${order['id']}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Ngày đặt: ${order['date'].toDate()}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
      },
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

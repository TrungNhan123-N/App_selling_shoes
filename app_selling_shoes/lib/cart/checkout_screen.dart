// lib/cart/checkout_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../orders/order_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double totalPrice = 0.0;
  List<Map<String, dynamic>> checkoutItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    DataSnapshot cartSnapshot = await _database.child('carts').child(user.uid).child('items').get();
    if (cartSnapshot.exists) {
      Map<dynamic, dynamic> items = cartSnapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> cartList = [];
      items.forEach((key, value) {
        cartList.add(Map<String, dynamic>.from(value)..['key'] = key);
      });

      setState(() {
        checkoutItems = cartList;
        totalPrice = cartList.fold(0.0, (sum, item) {
          return sum + (double.tryParse(item['price'].toString()) ?? 0.0) * item['quantity'];
        });
      });
    }
  }

  Future<void> _placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String orderKey = _database.child('orders').push().key!;
    await _database.child('orders').child(orderKey).set({
      'id': orderKey,
      'userId': user.uid,
      'items': checkoutItems,
      'totalPrice': totalPrice,
      'status': 'Chờ xác nhận',
      'date': ServerValue.timestamp,
    });

    // Xóa giỏ hàng
    await _database.child('carts').child(user.uid).child('items').remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đặt hàng thành công!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OrderListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: checkoutItems.length,
              itemBuilder: (context, index) {
                var item = checkoutItems[index];
                return ListTile(
                  leading: Image.network(
                    item['image_url'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50),
                  ),
                  title: Text(item['name']),
                  subtitle: Text("Số lượng: ${item['quantity']} - Giá: \$${item['price']}"),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng tiền:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$${totalPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Xác nhận đặt hàng", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
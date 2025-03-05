import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../orders/order_list_screen.dart';



class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

    final cartSnapshot = await _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .get();

    final items = cartSnapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      checkoutItems = items;
      totalPrice = items.fold(0.0, (sum, item) {
        return sum + (double.tryParse(item['price'].toString()) ?? 0.0) * item['quantity'];
      });
    });
  }

  Future<void> _placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final orderRef = _firestore.collection('orders').doc();
    await orderRef.set({
      'id': orderRef.id,
      'userId': user.uid,
      'items': checkoutItems,
      'totalPrice': totalPrice,
      'status': 'Chờ xác nhận',
      'date': Timestamp.now(),
    });

    await _firestore.collection('carts').doc(user.uid).collection('items').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

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

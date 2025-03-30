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

    QuerySnapshot cartSnapshot = await _firestore
        .collection('carts')
        .where('user_id', isEqualTo: user.uid)
        .get();

    if (cartSnapshot.docs.isNotEmpty) {
      List<Map<String, dynamic>> cartList = cartSnapshot.docs.map((doc) {
        return {'cart_id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng đăng nhập để thanh toán")),
      );
      return;
    }

    if (checkoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giỏ hàng trống, không thể đặt hàng")),
      );
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        for (var item in checkoutItems) {
          DocumentReference productRef = _firestore.collection('products').doc(item['product_id']);
          DocumentSnapshot productDoc = await transaction.get(productRef);
          if (!productDoc.exists) {
            throw Exception("${item['name']} không tồn tại");
          }
          int currentStock = (productDoc.data() as Map<String, dynamic>)['stock'] ?? 0;
          if (currentStock < item['quantity']) {
            throw Exception("${item['name']} không đủ hàng trong kho");
          }
          transaction.update(productRef, {'stock': currentStock - item['quantity']});
        }

        DocumentReference orderRef = await _firestore.collection('orders').add({
          'user_id': user.uid,
          'items': checkoutItems,
          'total_price': totalPrice,
          'status': 'Chờ xác nhận',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });

        transaction.update(orderRef, {'order_id': orderRef.id});

        QuerySnapshot cartSnapshot = await _firestore
            .collection('carts')
            .where('user_id', isEqualTo: user.uid)
            .get();
        for (var doc in cartSnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đặt hàng thành công!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderListScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi đặt hàng: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán')),
      body: checkoutItems.isEmpty
          ? Center(child: Text("Giỏ hàng trống, vui lòng thêm sản phẩm trước khi thanh toán"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: checkoutItems.length,
              itemBuilder: (context, index) {
                var item = checkoutItems[index];
                return ListTile(
                  leading: Image.network(
                    item['image_url'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50),
                  ),
                  title: Text(item['name'] ?? 'Không có tên'),
                  subtitle: Text("Số lượng: ${item['quantity'] ?? 0} - Giá: \$${item['price'] ?? 0}"),
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
                    Text("\$${totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
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
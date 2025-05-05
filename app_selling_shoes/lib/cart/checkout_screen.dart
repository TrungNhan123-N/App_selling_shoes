import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<void> _placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar("Vui lòng đăng nhập để thanh toán");
      return;
    }

    if (checkoutItems.isEmpty) {
      _showSnackBar("Giỏ hàng trống, không thể đặt hàng");
      return;
    }

    try {
      // Xóa tất cả sản phẩm trong giỏ hàng
      QuerySnapshot cartSnapshot = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: user.uid)
          .get();
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      // Cập nhật giao diện
      setState(() {
        checkoutItems = [];
        totalPrice = 0.0;
      });

      // Hiển thị thông báo thành công
      _showSnackBar("Thanh toán thành công!", isSuccess: true);
    } catch (e) {
      _showSnackBar("Lỗi khi thanh toán: $e");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
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
                    Text(
                      "\$${totalPrice.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
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
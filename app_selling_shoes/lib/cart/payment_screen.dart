import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main_screen.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _addressController = TextEditingController();
  String _selectedPaymentMethod = "COD";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _placeOrder() async {
    String uid = _auth.currentUser!.uid;
    String address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập địa chỉ giao hàng!")));
      return;
    }

    QuerySnapshot cartSnapshot = await _firestore.collection('users').doc(uid).collection('cart').get();
    if (cartSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Giỏ hàng của bạn đang trống!")));
      return;
    }

    double totalAmount = 0.0;
    List<Map<String, dynamic>> orderItems = [];

    for (var doc in cartSnapshot.docs) {
      var item = doc.data() as Map<String, dynamic>;
      totalAmount += item['price'] * item['quantity'];
      orderItems.add(item);
    }

    // Lưu đơn hàng vào Firestore
    String orderId = _firestore.collection('orders').doc().id; // Tạo ID duy nhất
    await _firestore.collection('orders').doc(orderId).set({
      'id': orderId,
      'userId': uid,
      'items': orderItems,
      'totalAmount': totalAmount,
      'paymentMethod': _selectedPaymentMethod,
      'address': address,
      'orderTime': DateTime.now(),
      'status': 'Chờ xác nhận',
    });

    // Xóa giỏ hàng trong Firestore sau khi đặt hàng
    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đặt hàng thành công!")));

    // Quay về OrderListScreen trong tab "Tôi"
    Navigator.popUntil(context, (route) => route.isFirst);
    final mainScreenState = MainScreen.globalKey.currentState;
    // mainScreenState?._onItemTapped(2); // Chuyển sang tab "Tôi" (ProfileScreen) để xem đơn hàng
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text("COD (Thanh toán khi nhận hàng)"),
              leading: Radio(
                value: "COD",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            ListTile(
              title: Text("Thẻ ngân hàng"),
              leading: Radio(
                value: "Bank Card",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            ListTile(
              title: Text("Ví điện tử"),
              leading: Radio(
                value: "E-Wallet",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Text("Địa chỉ giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(hintText: "Nhập địa chỉ của bạn", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.all(15)),
              child: Center(
                child: Text("Xác nhận đơn hàng", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
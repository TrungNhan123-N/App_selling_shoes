import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double totalPrice = 0.0;

  Future<void> _updateQuantity(String docId, int quantity) async {
    if (quantity <= 0) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('cart').doc(docId).delete();
    } else {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('cart').doc(docId).update({
        'quantity': quantity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng')),
      body: StreamBuilder(
        stream: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('cart').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Giỏ hàng trống.'));
          }

          final cartItems = snapshot.data!.docs;

          totalPrice = cartItems.fold(0.0, (sum, item) {
            var data = item.data() as Map<String, dynamic>;
            return sum + (data['price'] * data['quantity']);
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    var data = item.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        leading: Image.network(data['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(data['name']),
                        subtitle: Text("Giá: \$${data['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _updateQuantity(item.id, data['quantity'] - 1),
                            ),
                            Text("${data['quantity']}"),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _updateQuantity(item.id, data['quantity'] + 1),
                            ),
                          ],
                        ),
                      ),
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
                      onPressed: () {
                        Navigator.pushNamed(context, '/payment'); // Chuyển đến PaymentScreen
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Thanh toán", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
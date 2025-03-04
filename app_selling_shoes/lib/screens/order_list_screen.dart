import 'package:app_selling_shoes/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? avatarUrl;
  String userName = "Nguyễn Trung Nhân";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          avatarUrl = doc['avatarUrl'];
          userName = doc['name'] ?? "Nguyễn Trung Nhân";
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = _auth.currentUser;
      if (user != null) {
        Reference ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
        await ref.putFile(imageFile);
        String newAvatarUrl = await ref.getDownloadURL();
        await _firestore.collection('users').doc(user.uid).update({'avatarUrl': newAvatarUrl});
        setState(() {
          avatarUrl = newAvatarUrl;
        });
      }
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
        backgroundColor: Colors.lightBlueAccent[100],
        title: Text('Danh sách Đơn hàng'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent[100],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple[100],
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null ? Icon(Icons.person, size: 40, color: Colors.grey) : null,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đơn mua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {}, // Có thể thêm logic lịch sử mua hàng sau
                  child: const Row(
                    children: [
                      Text("Xem lịch sử mua hàng", style: TextStyle(color: Colors.blue)),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').where('userId', isEqualTo: user.uid).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Chưa có đơn hàng"));
                }

                final orders = snapshot.data!.docs.map((doc) {
                  final order = doc.data() as Map<String, dynamic>;
                  order['id'] = doc.id; // Lấy orderId từ document ID
                  order['icon'] = _getIconForStatus(order['status']);
                  return order;
                }).toList();

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(order['icon'], size: 40, color: Colors.orange),
                            SizedBox(height: 8),
                            Text(order['status'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(order['date'], style: TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Icons.article;
      case 'Chờ lấy hàng':
        return Icons.inventory;
      case 'Chờ giao hàng':
      case 'Đang giao':
        return Icons.local_shipping;
      case 'Đánh giá':
      case 'Hoàn thành':
        return Icons.star;
      default:
        return Icons.help;
    }
  }
}
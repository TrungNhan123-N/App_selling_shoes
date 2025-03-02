import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SavedAddressesScreen extends StatefulWidget {
  @override
  _SavedAddressesScreenState createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm để thêm địa chỉ mới vào Firestore
  void _addAddress() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddAddressDialog(),
    );
    if (result != null) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .add({
            'title': result['title'],
            'address': result['address'],
            'createdAt': FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm địa chỉ mới')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi thêm địa chỉ: $e')),
          );
        }
      }
    }
  }

  // Hàm để chỉnh sửa địa chỉ trong Firestore
  void _editAddress(String docId, String currentTitle, String currentAddress) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddAddressDialog(
        initialTitle: currentTitle,
        initialAddress: currentAddress,
      ),
    );
    if (result != null) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .doc(docId)
              .update({
            'title': result['title'],
            'address': result['address'],
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật địa chỉ')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi cập nhật địa chỉ: $e')),
          );
        }
      }
    }
  }

  // Hàm để xóa địa chỉ từ Firestore
  void _deleteAddress(String docId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa địa chỉ')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa địa chỉ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Địa chỉ đã lưu')),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem địa chỉ.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Địa chỉ đã lưu'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addAddress,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Chưa có địa chỉ nào được lưu.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final addresses = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addressData = addresses[index].data() as Map<String, dynamic>;
              final docId = addresses[index].id;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    addressData['title'] ?? 'Không có tiêu đề',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(addressData['address'] ?? 'Không có địa chỉ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editAddress(
                          docId,
                          addressData['title'] ?? '',
                          addressData['address'] ?? '',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAddress(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget dialog để thêm hoặc chỉnh sửa địa chỉ
class AddAddressDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialAddress;

  AddAddressDialog({this.initialTitle, this.initialAddress});

  @override
  _AddAddressDialogState createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  late TextEditingController titleController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    addressController = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Tên địa chỉ (ví dụ: Nhà riêng)'),
          ),
          TextField(
            controller: addressController,
            decoration: InputDecoration(labelText: 'Địa chỉ chi tiết'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty && addressController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'address': addressController.text.trim(),
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
              );
            }
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
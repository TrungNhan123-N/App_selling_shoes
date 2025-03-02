import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLogin = true;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isLogin) {
        // Đăng nhập
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // Đăng ký
        UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;

        // Lưu thông tin vào Firestore
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'name': name,
          'createdAt': DateTime.now(),
        });
      }

      // Chuyển sang màn hình chính
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => HomeScreen()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${error.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isLogin)
              TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Tên')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

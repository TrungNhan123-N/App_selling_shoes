import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser(); // Kiểm tra trạng thái đăng nhập khi màn hình khởi động
  }

  void _checkCurrentUser() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Nếu người dùng đã đăng nhập từ phiên trước, chuyển hướng hoặc xử lý tùy ý
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bạn đã đăng nhập từ trước!")),
        );
        // Ví dụ: Chuyển sang màn hình chính thay vì màn hình đăng ký
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      });
    }
  }

  void register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Lưu thông tin vào Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng ký thành công!")),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng ký: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng ký tài khoản")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Tên"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: register,
              child: Text("Đăng ký"),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
              child: Text("Đã có tài khoản? Đăng nhập"),
            ),
          ],
        ),
      ),
    );
  }
}
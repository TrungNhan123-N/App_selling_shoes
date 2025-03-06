// lib/authentications/login_screen.dart
import 'package:app_selling_shoes/authentications/register_screen.dart';
import 'package:app_selling_shoes/transfer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../admin_screen/admin_dash_board_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isLoading = false;

  final String adminUsername = "admin";
  final String adminPassword = "1";

  void _login() async {
    String emailOrUsername = emailController.text.trim();
    String password = passwordController.text.trim();

    setState(() => _isLoading = true);

    if (emailOrUsername == adminUsername && password == adminPassword) {
      AuthStatus.isAdmin = true;
      await _initializeSampleProducts();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
      );
      setState(() => _isLoading = false);
      return;
    }

    AuthStatus.isAdmin = false;
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailOrUsername,
        password: password,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TransferScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng nhập: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeSampleProducts() async {
    DataSnapshot productSnapshot = await _database.child('products').get();
    if (!productSnapshot.exists || productSnapshot.value == null) {
      await _database.child('products').set({
        '-N123456789': {
          'id': '-N123456789',
          'name': 'Sneaker X',
          'price': 50.0,
          'image_url': 'https://example.com/sneaker.jpg',
          'description': 'A cool sneaker',
          'category_id': 'Sneakers',
        },
        '-N123456790': {
          'id': '-N123456790',
          'name': 'Formal Shoe Y',
          'price': 80.0,
          'image_url': 'https://example.com/formal.jpg',
          'description': 'Elegant formal shoe',
          'category_id': 'Formal',
        },
        '-N123456791': {
          'id': '-N123456791',
          'name': 'Casual Z',
          'price': 40.0,
          'image_url': 'https://example.com/casual.jpg',
          'description': 'Comfortable casual shoe',
          'category_id': 'Casual',
        },
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên build method
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/1.png",
                height: 120,
              ),
              SizedBox(height: 20),
              Text(
                "Chào mừng đến với ShoeStore",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email hoặc Tài khoản",
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Đăng nhập",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                ),
                child: Text("Quên mật khẩu?", style: TextStyle(color: Colors.black)),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                ),
                child: Text("Chưa có tài khoản? Đăng ký", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
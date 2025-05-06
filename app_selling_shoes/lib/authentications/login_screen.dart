import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../admin_screen/admin_dash_board_screen.dart';
import 'forgot_password_screen.dart';
import '../transfer_screen.dart';
import 'package:app_selling_shoes/authentications/register_screen.dart';

class LoginScreen extends StatefulWidget {
    @override
    _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    bool _isLoading = false;
    bool _obscureText = true;

    Future<void> _showErrorDialog(String message) async {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                title: Text("Thông báo lỗi"),
                content: Text(message),
                actions: [
                    TextButton(
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                        child: Text("Đóng"),
                    ),
                ],
            ),
        );
    }

    Future<void> _login() async {
        String email = emailController.text.trim();
        String password = passwordController.text.trim();

        if (email.isEmpty || password.isEmpty) {
            _showErrorDialog("Vui lòng nhập email và mật khẩu");
            return;
        }

        if (mounted) {
            setState(() => _isLoading = true);
        }
        print("Bắt đầu quá trình đăng nhập...");

        try {
            // Đăng nhập với Firebase Authentication
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
            );
            print("Đăng nhập thành công với UID: ${userCredential.user!.uid}");

            String? token = await userCredential.user!.getIdToken();
            print("Token: $token");

            // Truy vấn Firestore
            DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userCredential.user!.uid).get();
            print("Kiểm tra dữ liệu người dùng trong Firestore...");

            String role;
            if (userSnapshot.exists) {
                Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
                role = userData['role'] ?? 'user';
                print("Vai trò từ Firestore: $role");
            } else {
                print("Người dùng không tồn tại trong Firestore, tạo mới với vai trò user...");
                await _firestore.collection('users').doc(userCredential.user!.uid).set({
                    'uid': userCredential.user!.uid,
                    'email': email,
                    'role': 'user',
                    'created_at': FieldValue.serverTimestamp(),
                });
                role = 'user';
            }

            // Điều hướng dựa trên vai trò
            if (role == 'admin') {
                AuthStatus.isAdmin = true;
                print("Điều hướng đến AdminDashboardScreen...");
                if (mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
                    );
                }
            } else {
                AuthStatus.isAdmin = false;
                print("Điều hướng đến TransferScreen...");
                if (mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TransferScreen()),
                    );
                }
            }
        } on FirebaseAuthException catch (e) {
            print("Lỗi trong quá trình đăng nhập: $e");
            String errorMessage;
            switch (e.code) {
                case 'user-not-found':
                    errorMessage = "Tài khoản không tồn tại";
                    break;
                case 'wrong-password':
                    errorMessage = "Mật khẩu không đúng, vui lòng kiểm tra lại";
                    break;
                case 'invalid-email':
                    errorMessage = "Email không hợp lệ";
                    break;
                case 'user-disabled':
                    errorMessage = "Tài khoản đã bị vô hiệu hóa";
                    break;
                case 'too-many-requests':
                    errorMessage = "Quá nhiều yêu cầu, vui lòng thử lại sau";
                    break;
                default:
                    errorMessage = "Đã xảy ra lỗi, vui lòng thử lại";
            }
            _showErrorDialog(errorMessage);
        } catch (e) {
            print("Lỗi không xác định: $e");
            String errorMessage = "Đã xảy ra lỗi, vui lòng thử lại sau";
            if (e is FirebaseException) {
                errorMessage = e.message ?? errorMessage;
            }
            _showErrorDialog(errorMessage);
        } finally {
            if (mounted) {
                setState(() => _isLoading = false);
            }
            print("Kết thúc quá trình đăng nhập");
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Center(
                                child: Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue[50],
                                        boxShadow: [
                                            BoxShadow(
                                                color: Colors.blue.withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: Offset(0, 6),
                                            ),
                                        ],
                                    ),
                                    padding: EdgeInsets.all(20.0),
                                    child: ClipOval(
                                        child: Image.asset(
                                            "assets/images/1.png",
                                            height: 160,
                                            width: 160,
                                            fit: BoxFit.cover,
                                        ),
                                    ),
                                ),
                            ),
                            SizedBox(height: 30),
                            Text(
                                "Đăng Nhập",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                ),
                            ),
                            SizedBox(height: 10),
                            Text(
                                "Chào mừng bạn đến với ShoeStore",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                ),
                            ),
                            SizedBox(height: 40),
                            TextField(
                                controller: emailController,
                                decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle: TextStyle(color: Colors.blue),
                                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.blue, width: 2),
                                    ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 20),
                            TextField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                    labelText: "Mật khẩu",
                                    labelStyle: TextStyle(color: Colors.blue),
                                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                                    suffixIcon: IconButton(
                                        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () {
                                            setState(() {
                                                _obscureText = !_obscureText;
                                            });
                                        },
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.blue, width: 2),
                                    ),
                                ),
                                obscureText: _obscureText,
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                    ),
                                ),
                            ),
                            SizedBox(height: 20),
                            TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                                ),
                                child: Text(
                                    "Quên mật khẩu?",
                                    style: TextStyle(color: Colors.blue, fontSize: 16),
                                ),
                            ),
                            SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text(
                                        "Chưa có tài khoản? ",
                                        style: TextStyle(color: Colors.blue[700]),
                                    ),
                                    GestureDetector(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => RegisterScreen(isAdmin: false)),
                                        ),
                                        child: Text(
                                            "Đăng ký ngay",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                            SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text(
                                        "Bạn là quản trị viên? ",
                                        style: TextStyle(color: Colors.blue[700]),
                                    ),
                                    GestureDetector(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => RegisterScreen(isAdmin: true)),
                                        ),
                                        child: Text(
                                            "Đăng ký Admin",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

class AuthStatus {
    static bool isAdmin = false;
}
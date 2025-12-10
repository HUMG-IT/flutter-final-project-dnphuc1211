import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Biến để lấy dữ liệu từ ô nhập
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Biến xác định đang ở chế độ Đăng nhập hay Đăng ký
  bool isLogin = true; 
  bool isLoading = false;

  // Hàm xử lý chính
  Future<void> _submit() async {
    setState(() => isLoading = true); // Hiện vòng quay loading
    try {
      if (isLogin) {
        // --- ĐĂNG NHẬP ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // --- ĐĂNG KÝ ---
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      // Nếu thành công:
      if(mounted) {
        // 1. Thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isLogin ? "Đăng nhập thành công!" : "Đăng ký thành công!")),
        );

        // 2. Chuyển sang trang chủ 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomePage())
        );
      }
    } on FirebaseAuthException catch (e) {
      // Nếu lỗi (sai pass, email trùng...), hiện thông báo lỗi
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Có lỗi xảy ra"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => isLoading = false); // Tắt loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Đăng nhập" : "Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ô nhập Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            // Ô nhập Password
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
              obscureText: true, // Ẩn password
            ),
            const SizedBox(height: 20),
            
            // Nút bấm xác nhận
            isLoading 
            ? const CircularProgressIndicator() 
            : ElevatedButton(
                onPressed: _submit,
                child: Text(isLogin ? "Đăng Nhập" : "Đăng Ký"),
              ),
            
            // Nút chuyển đổi qua lại giữa Đăng nhập/Đăng ký
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin 
                ? "Chưa có tài khoản? Đăng ký ngay" 
                : "Đã có tài khoản? Đăng nhập"),
            )
          ],
        ),
      ),
    );
  }
}
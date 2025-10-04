// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ✅ Login function
  Future<void> _login() async {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final String input = _inputController.text.trim();
    final String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showMessage(isArabic
          ? "يجب إدخال رقم الهاتف أو اسم المستخدم وكلمة المرور."
          : "ژمارەی مۆبایل یان ناوی بەکارەوەر و وشەی نهێنی پێویستە.");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('https://legaryan.heama-soft.com/login.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"input": input, "password": password}),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          // ✅ Set user data in Provider
          Provider.of<UserModel>(context, listen: false).setUser(
            responseData['name'],
            responseData['phone_number'],
            responseData['role'],
          );

          // ✅ Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', responseData['name']);
          await prefs.setString('phoneNumber', responseData['phone_number']);
          await prefs.setString('role', responseData['role']);

          // ✅ Save user_id (required for Delete Account)
          if (responseData.containsKey('id')) {
            await prefs.setInt(
                'user_id', int.parse(responseData['id'].toString()));
          }

          _showMessage(responseData['message']);
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showMessage(responseData['message']);
        }
      } else {
        _showMessage(isArabic
            ? "استجابة غير صالحة من الخادم."
            : "Invalid response from server.");
      }
    } catch (e) {
      _showMessage(isArabic
          ? "حدث خطأ: يرجى المحاولة مرة أخرى."
          : "هەڵە ڕویدا: تکایە دوبارە هەوڵ بدە.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'NotoKufi'),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: Text(
            isArabic ? "تسجيل الدخول" : 'چوونەژوورەوە',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'NotoKufi',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', height: 100),
                  const SizedBox(height: 30),

                  // Subtitle
                  Text(
                    isArabic
                        ? "يرجى إدخال رقم الهاتف أو اسم المستخدم وكلمة المرور"
                        : 'تکایە ژمارەی مۆبایل یان ناو و وشەی نهێنی داخڵ بکە',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'NotoKufi',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Username / Phone
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? "رقم الهاتف أو اسم المستخدم"
                          : 'ژمارەی مۆبایل یان ناو',
                      labelStyle: const TextStyle(fontFamily: 'NotoKufi'),
                      prefixIcon:
                          const Icon(Icons.person, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: isArabic ? "كلمة المرور" : 'وشەی نهێنی',
                      labelStyle: const TextStyle(fontFamily: 'NotoKufi'),
                      prefixIcon:
                          const Icon(Icons.lock, color: Colors.deepPurple),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            isArabic ? "تسجيل الدخول" : 'چوونەژوورەوە',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'NotoKufi',
                            ),
                          ),
                  ),

                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forget_password');
                    },
                    child: Text(
                      isArabic
                          ? "هل نسيت كلمة المرور؟"
                          : 'وشەی نهێنی لەبیرت چووە؟',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontFamily: 'NotoKufi',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Register button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    child: Text(
                      isArabic
                          ? "لم تقم بالتسجيل بعد؟ سجل الآن"
                          : 'هێشتا خۆتۆمار نەبوویت؟ خۆتۆمارکردن',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontFamily: 'NotoKufi',
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

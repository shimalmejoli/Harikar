// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../screens/AboutUsPage.dart';
import '../screens/FeedbackPage.dart';
import '../screens/feedback_screen.dart';
import '../screens/profile_screen.dart';
import '../main.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    List<Widget> menuItems = [];

    /// helper: delete account permanently
    Future<void> _deleteAccount() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title:
              Text(isArabic ? "تأكيد الحذف" : "دڵنیایت لە سڕینەوەی ئەکاونت؟"),
          content: Text(isArabic
              ? "سيتم حذف حسابك وجميع بياناتك نهائيًا."
              : "ئەکاونتەکەت و هەموو زانیاریەکان بە تەواوی دەسڕدرێن."),
          actions: [
            TextButton(
              child: Text(isArabic ? "إلغاء" : "پاشگەزبوونەوە"),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(isArabic ? "حذف" : "سڕینەوە"),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic
                  ? "تعذر تحديد المستخدم."
                  : "نەیتوانرا ئەکاونتەکەت بدۆزرێتەوە"),
            ),
          );
          return;
        }

        final response = await http.post(
          Uri.parse('https://legaryan.heama-soft.com/delete_account.php'),
          body: {'user_id': userId.toString()},
        );

        if (response.statusCode == 200 &&
            response.body.contains('"success":true')) {
          Provider.of<UserModel>(context, listen: false).clearUser();
          await prefs.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic
                  ? "تم حذف الحساب بنجاح"
                  : "ئەکاونتەکەت بە سەرکەوتوویی سڕدرایەوە"),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic
                  ? "فشل حذف الحساب."
                  : "هەڵەیەک ڕویدا لە سڕینەوەی ئەکاونت."),
            ),
          );
        }
      }
    }

    // ========================== MENU ITEMS ==========================
    if (user.role == 'admin') {
      menuItems = [
        _buildMenuItem(
          icon: Icons.home,
          title: isArabic ? "الصفحة الرئيسية" : 'پەڕەی سەرەکی',
          onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        _buildMenuItem(
          icon: Icons.person,
          title: isArabic ? "الملف الشخصي" : 'پەڕەی کەسی',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userName: user.name,
                  phoneNumber: user.phoneNumber,
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.category,
          title: isArabic ? "إضافة وظيفة" : 'زیادکردنی کار',
          onTap: () => Navigator.pushNamed(context, '/add_category'),
        ),
        _buildMenuItem(
          icon: Icons.subdirectory_arrow_right,
          title: isArabic ? "إضافة مركز عمل" : 'زیادکردنی ناوەندی کار',
          onTap: () => Navigator.pushNamed(context, '/add_subcategory'),
        ),
        _buildMenuItem(
          icon: Icons.app_registration,
          title: isArabic ? "التسجيل" : 'خو توماربکە',
          onTap: () => Navigator.pushReplacementNamed(context, '/register'),
        ),
        Divider(),
        _buildMenuItem(
          icon: Icons.people,
          title: isArabic ? "عرض المستخدمين" : 'بینینی بەکارهێنەرەکان',
          onTap: () => Navigator.pushNamed(context, '/view_users'),
        ),
        _buildMenuItem(
          icon: Icons.add_box,
          title: isArabic ? "إضافة معلومات" : 'زیادکردنی زانیاری',
          onTap: () => Navigator.pushNamed(context, '/insert_details'),
        ),
        _buildMenuItem(
          icon: Icons.list,
          title: isArabic ? "عرض المعلومات" : 'پیشاندانی زانیاریەکان',
          onTap: () => Navigator.pushNamed(context, '/show_details'),
        ),
        _buildMenuItem(
          icon: Icons.list,
          title: isArabic ? "تعديل مستخدم" : 'ئاپدتکرنا کارهێنەرا',
          onTap: () => Navigator.pushNamed(context, '/user2'),
        ),
        _buildMenuItem(
          icon: Icons.list,
          title: isArabic ? "تعديل اعلانات" : 'ئاپدتکرنا ریکلام',
          onTap: () => Navigator.pushNamed(context, '/ads'),
        ),
        Divider(),
        _buildMenuItem(
          icon: Icons.settings,
          title: isArabic ? "الإبلاغ" : 'سکالا',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => FeedbackScreen())),
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: isArabic ? "قسم الإبلاغ" : 'بەشێ سکالا',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => FeedbackPage())),
        ),
        _buildMenuItem(
          icon: Icons.info,
          title: isArabic ? "حول" : 'دەربارە',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AboutUsPage())),
        ),
        Divider(),

        /// ✅ NEW Delete Account
        _buildMenuItem(
          icon: Icons.delete_forever,
          title: isArabic ? "حذف الحساب" : 'سڕینەوەی ئەکاونت',
          onTap: _deleteAccount,
        ),

        _buildMenuItem(
          icon: Icons.exit_to_app,
          title: isArabic ? "تسجيل الخروج" : 'چوونا دەرێ',
          onTap: () async {
            Provider.of<UserModel>(context, listen: false).clearUser();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ];
    } else if (user.role == 'user') {
      menuItems = [
        _buildMenuItem(
          icon: Icons.home,
          title: isArabic ? "الصفحة الرئيسية" : 'پەڕەی سەرەکی',
          onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        _buildMenuItem(
          icon: Icons.person,
          title: isArabic ? "الملف الشخصي" : 'پەڕەی کەسی',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userName: user.name,
                  phoneNumber: user.phoneNumber,
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: isArabic ? "الإبلاغ" : 'سکالا',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => FeedbackScreen())),
        ),
        _buildMenuItem(
          icon: Icons.info,
          title: isArabic ? "حول" : 'دەربارە',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AboutUsPage())),
        ),
        Divider(),

        /// ✅ Delete Account for normal user
        _buildMenuItem(
          icon: Icons.delete_forever,
          title: isArabic ? "حذف الحساب" : 'سڕینەوەی ئەکاونت',
          onTap: _deleteAccount,
        ),

        _buildMenuItem(
          icon: Icons.exit_to_app,
          title: isArabic ? "تسجيل الخروج" : 'چوونا دەرێ',
          onTap: () async {
            Provider.of<UserModel>(context, listen: false).clearUser();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ];
    } else {
      menuItems = [
        _buildMenuItem(
          icon: Icons.home,
          title: isArabic ? "الصفحة الرئيسية" : 'پەڕەی سەرەکی',
          onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        _buildMenuItem(
          icon: Icons.app_registration,
          title: isArabic ? "التسجيل" : 'خو توماربکە',
          onTap: () => Navigator.pushReplacementNamed(context, '/register'),
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: isArabic ? "الإبلاغ" : 'سکالا',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => FeedbackScreen())),
        ),
        _buildMenuItem(
          icon: Icons.info,
          title: isArabic ? "حول" : 'دەربارە',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AboutUsPage())),
        ),
        Divider(),
        _buildMenuItem(
          icon: Icons.login,
          title: isArabic ? "تسجيل الدخول" : 'چوونا ژور',
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ];
    }

    // ========================== LANGUAGE SELECTOR ==========================
    menuItems.add(Divider());
    menuItems.add(_buildMenuItem(
      icon: Icons.language,
      title: isArabic ? "تغيير اللغة" : 'گهورینا زمانی',
      onTap: () => _showLanguageDialog(context),
    ));

    // ========================== DRAWER ==========================
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 40,
                child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
              ),
              accountName: Text(
                user.name.isNotEmpty
                    ? user.name
                    : (isArabic ? "مرحبا" : 'خێر هاتی'),
                style: TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                user.phoneNumber.isNotEmpty ? user.phoneNumber : '',
                style: TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            ...menuItems,
          ],
        ),
      ),
    );
  }

  // ========================== LANGUAGE DIALOG ==========================
  void _showLanguageDialog(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isArabic ? "اختر اللغة" : "زمان هەلبژێرە"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('کوردی'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedLanguage', 'ku');
                Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale(Locale('ku', 'IQ'));
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
            ),
            ListTile(
              title: Text('العربية'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedLanguage', 'ar');
                Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale(Locale('ar', ''));
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========================== MENU ITEM BUILDER ==========================
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}

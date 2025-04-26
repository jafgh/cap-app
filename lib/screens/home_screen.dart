import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/account_card.dart'; // ستحتاج لإنشاء هذا الويدجت
import '../widgets/captcha_view.dart'; // ستحتاج لإنشاء هذا الويدجت

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // دالة لعرض مربع حوار إضافة حساب
  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final appState = Provider.of<AppState>(context, listen: false);
        return AlertDialog(
          title: Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true, // لإخفاء كلمة المرور
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _usernameController.clear();
                _passwordController.clear();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                final username = _usernameController.text.trim();
                final password = _passwordController.text.trim();
                if (username.isNotEmpty && password.isNotEmpty) {
                  appState.addAccount(username, password); // استدعاء الدالة في الـ Provider
                  Navigator.of(context).pop();
                  _usernameController.clear();
                  _passwordController.clear();
                } else {
                  // عرض رسالة خطأ بسيطة داخل الحوار
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter both username and password.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للاستماع للتغيرات في AppState وإعادة بناء الواجهة
    return Scaffold(
      appBar: AppBar(
        title: Text('Captcha Solver (Flutter)'),
      ),
      body: Consumer<AppState>( // الاستماع إلى AppState
        builder: (context, appState, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                // منطقة الإشعارات
                if (appState.notificationMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      appState.notificationMessage,
                      style: TextStyle(color: appState.notificationColor),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // زر إضافة حساب
                ElevatedButton(
                  onPressed: () => _showAddAccountDialog(context),
                  child: Text('Add Account'),
                ),
                SizedBox(height: 10),

                // قائمة الحسابات المضافة
                Expanded(
                  child: ListView.builder(
                    itemCount: appState.accounts.length,
                    itemBuilder: (context, index) {
                      final account = appState.accounts[index];
                      // استخدام ويدجت مخصص لعرض كل حساب وعملياته
                      return AccountCard(account: account);
                    },
                  ),
                ),

                 // منطقة عرض الكابتشا والتنبؤ
                 CaptchaView(), // ويدجت مخصص لعرض الكابتشا

                // منطقة عرض سرعة المعالجة والتنبؤ
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Text(
                     'Preprocess: ${appState.preprocessTimeMs} ms | Predict: ${appState.predictTimeMs} ms',
                     style: TextStyle(fontSize: 12, color: Colors.grey),
                   ),
                 ),
              ],
            ),
          );
        },
      ),
    );
  }

   @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

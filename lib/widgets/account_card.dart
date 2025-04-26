import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/app_state.dart';
import 'process_button.dart'; // ستحتاج لإنشائه

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<AppState>(context, listen: false); // للوصول للدوال

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account: ${account.username}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // عرض أزرار العمليات
            if (account.processes.isEmpty)
              Text('No processes found for this account.')
            else
              Wrap( // استخدام Wrap لترتيب الأزرار تلقائيًا
                spacing: 8.0, // المسافة الأفقية بين الأزرار
                runSpacing: 4.0, // المسافة العمودية بين الأسطر
                children: account.processes.map((process) {
                  // استخدام ويدجت زر مخصص لكل عملية
                  return ProcessButton(
                    processName: process.centerName ?? 'Unknown Process',
                    onPressed: () {
                       // استدعاء الدالة لبدء عملية جلب الكابتشا
                       Provider.of<AppState>(context, listen: false)
                           .handleCaptchaRequest(account.username, process.processId);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

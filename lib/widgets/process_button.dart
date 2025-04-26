import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart'; // للاستماع لحالة التحميل

class ProcessButton extends StatelessWidget {
  final String processName;
  final VoidCallback onPressed;

  const ProcessButton({
    Key? key,
    required this.processName,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // يمكنك إضافة مؤشر تحميل هنا إذا أردت بناءً على الحالة في AppState
    // final isLoading = Provider.of<AppState>(context).captchaStatus == CaptchaStatus.loading || ... ;

    return ElevatedButton(
      onPressed: onPressed, // ربط الدالة الممررة
      child: Text(processName),
      // يمكنك تعطيل الزر أثناء التحميل
      // style: ElevatedButton.styleFrom(
      //   onSurface: isLoading ? Colors.grey : null,
      // ),
    );
  }
}

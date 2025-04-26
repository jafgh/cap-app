import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CaptchaView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // عرض مختلف بناءً على حالة الكابتشا
        switch (appState.captchaStatus) {
          case CaptchaStatus.idle:
             return SizedBox.shrink(); // لا تعرض شيئًا عندما تكون خاملة
          case CaptchaStatus.loading:
          case CaptchaStatus.predicting:
          case CaptchaStatus.submitting:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 10),
                   Text(appState.captchaStatus.toString().split('.').last + '...'), // عرض الحالة الحالية
                ],
              ),
            );
          case CaptchaStatus.loaded:
          case CaptchaStatus.success: // اعرضها أيضًا بعد النجاح لفترة وجيزة
          case CaptchaStatus.error: // اعرضها أيضًا عند الخطأ لإظهار ما تم التنبؤ به
            if (appState.currentCaptchaImage != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  children: [
                    Text('Processed CAPTCHA:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    // عرض الصورة المعالجة
                    Image.memory(
                      appState.currentCaptchaImage!,
                      height: 90, // ارتفاع مناسب
                      width: 160, // عرض مناسب
                      gaplessPlayback: true, // لمنع الوميض عند التحديث
                    ),
                    SizedBox(height: 5),
                    if (appState.predictedCaptcha != null)
                       Text('Prediction: ${appState.predictedCaptcha}', style: TextStyle(fontSize: 16, color: Colors.blue)),
                     if (appState.captchaStatus == CaptchaStatus.error && appState.notificationMessage.contains("Submit Failed"))
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text('Submission Failed!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    if (appState.captchaStatus == CaptchaStatus.success)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text('Submission Successful!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                  ],
                ),
              );
            } else {
               // حالة غير متوقعة
               return SizedBox.shrink();
            }
        }
      },
    );
  }
}

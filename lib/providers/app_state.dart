import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/api_process.dart';
import '../services/api_service.dart';
import '../services/captcha_service.dart';
import 'dart:typed_data'; // For Uint8List

// تعريف حالة الكابتشا
enum CaptchaStatus { idle, loading, loaded, predicting, submitting, success, error }

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CaptchaService _captchaService = CaptchaService();

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  String _notificationMessage = "";
  String get notificationMessage => _notificationMessage;
  Color _notificationColor = Colors.black;
  Color get notificationColor => _notificationColor;

  CaptchaStatus _captchaStatus = CaptchaStatus.idle;
  CaptchaStatus get captchaStatus => _captchaStatus;

  Uint8List? _currentCaptchaImage; // الصورة المعالجة للعرض
  Uint8List? get currentCaptchaImage => _currentCaptchaImage;

  String? _predictedCaptcha;
  String? get predictedCaptcha => _predictedCaptcha;

  int _preprocessTimeMs = 0;
  int get preprocessTimeMs => _preprocessTimeMs;
  int _predictTimeMs = 0;
  int get predictTimeMs => _predictTimeMs;

  // معلومات الكابتشا الحالية للتقديم
  String? _currentProcessId;
  String? _currentAccountUsername;


  AppState() {
    // تحميل نموذج ONNX عند بدء التشغيل
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
        await _captchaService.loadModel();
        _setNotification("Model loaded.", Colors.green);
    } catch (e) {
        _setNotification("Failed to load ONNX model: $e", Colors.red);
    }
  }

  void _setNotification(String message, Color color) {
    _notificationMessage = message;
    _notificationColor = color;
    print("$color: $message"); // طباعة في الكونسول أيضًا
    notifyListeners(); // إخطار الواجهة بالتغيير
  }

  void _setCaptchaStatus(CaptchaStatus status) {
    _captchaStatus = status;
    notifyListeners();
  }

   // دالة لإضافة حساب وتسجيل الدخول وجلب العمليات
  Future<void> addAccount(String username, String password) async {
     _setNotification("Logging in $username...", Colors.blue);
     final loginResult = await _apiService.login(username, password);

     if (loginResult['success'] == true) {
        _setNotification("Login successful for $username. Fetching processes...", Colors.green);
        final String? cookies = loginResult['cookies']; // الحصول على الكوكيز
        final processes = await _apiService.fetchProcessIds(cookies);

        if (processes.isNotEmpty) {
             final newAccount = Account(
                username: username,
                password: password, // تخزين كلمة المرور قد لا يكون آمنًا، فكر في بدائل
                cookies: cookies,
                processes: processes,
             );
             _accounts.add(newAccount);
             _setNotification("Account $username added with ${processes.length} processes.", Colors.green);
        } else {
            _setNotification("Login successful for $username, but failed to fetch processes.", Colors.orange);
             // قد ترغب في إضافة الحساب بدون عمليات هنا
        }

     } else {
         _setNotification("Login failed for $username: ${loginResult['error'] ?? 'Unknown error'}", Colors.red);
     }
     notifyListeners(); // تحديث الواجهة لإظهار الحساب الجديد أو رسالة الخطأ
  }

  // دالة لجلب الكابتشا، معالجتها، والتنبؤ بها
  Future<void> handleCaptchaRequest(String username, String processId) async {
    final account = _accounts.firstWhere((acc) => acc.username == username, orElse: () => Account(username: 'error', password: '', cookies: null, processes: [])); // التعامل مع حالة عدم وجود الحساب
    if (account.cookies == null) {
        _setNotification("Cannot get captcha: Account $username not found or missing session.", Colors.red);
        return;
    }

    _setNotification("Getting captcha for process $processId...", Colors.blue);
    _setCaptchaStatus(CaptchaStatus.loading);
    _currentCaptchaImage = null; // مسح الصورة القديمة
    _predictedCaptcha = null; // مسح التنبؤ القديم

    final base64Data = await _apiService.getCaptcha(processId, account.cookies!);

    if (base64Data != null) {
        _setNotification("Captcha received. Processing and predicting...", Colors.blue);
        _setCaptchaStatus(CaptchaStatus.predicting);

        final result = await _captchaService.processAndPredict(base64Data);

        if (result != null) {
             _currentCaptchaImage = result['processedImage'];
             _predictedCaptcha = result['prediction'];
             _preprocessTimeMs = result['preprocessTime'];
             _predictTimeMs = result['predictTime'];
             _currentAccountUsername = username;
             _currentProcessId = processId;

            _setNotification("Predicted: $_predictedCaptcha", Colors.blue);
             _setCaptchaStatus(CaptchaStatus.loaded); // جاهز للعرض والتقديم

            // *** إرسال الحل تلقائيًا ***
            await submitCaptchaSolution();

        } else {
            _setNotification("Failed to process or predict captcha.", Colors.red);
            _setCaptchaStatus(CaptchaStatus.error);
        }

    } else {
         _setNotification("Failed to get captcha for process $processId.", Colors.red);
         _setCaptchaStatus(CaptchaStatus.error);
    }
  }

  // دالة لإرسال الحل
  Future<void> submitCaptchaSolution() async {
    if (_predictedCaptcha == null || _currentProcessId == null || _currentAccountUsername == null) {
         _setNotification("No captcha solution or context to submit.", Colors.orange);
         return;
    }

     final account = _accounts.firstWhere((acc) => acc.username == _currentAccountUsername, orElse: () => Account(username: 'error', password: '', cookies: null, processes: []));
      if (account.cookies == null) {
        _setNotification("Cannot submit captcha: Account $_currentAccountUsername not found or missing session.", Colors.red);
        return;
    }

    _setNotification("Submitting solution '$_predictedCaptcha' for process $_currentProcessId...", Colors.blue);
    _setCaptchaStatus(CaptchaStatus.submitting);

    final result = await _apiService.submitCaptcha(_currentProcessId!, _predictedCaptcha!, account.cookies!);

    if (result['success'] == true) {
         _setNotification("Submit Success: ${result['body']}", Colors.green);
         _setCaptchaStatus(CaptchaStatus.success);
    } else {
         _setNotification("Submit Failed (${result['statusCode']}): ${result['body'] ?? result['error']}", Colors.red);
         _setCaptchaStatus(CaptchaStatus.error);
    }

    // مسح الحالة بعد الإرسال (اختياري)
    _currentCaptchaImage = null;
    _predictedCaptcha = null;
    _currentProcessId = null;
    _currentAccountUsername = null;
    // يمكنك إعادة الحالة إلى idle أو تركها success/error
     Future.delayed(Duration(seconds: 3), () => _setCaptchaStatus(CaptchaStatus.idle));

  }

}

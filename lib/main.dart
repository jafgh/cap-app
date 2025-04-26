import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:arabic/arabic.dart'; // for reshaping and bidi

void main() {
  runApp(const CaptchaApp());
}

class CaptchaApp extends StatelessWidget {
  const CaptchaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حل الكابتشا', // تم تعديل العنوان ليكون بالعربية
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoNaskhArabic', // استخدام الخط المحدد
      ),
      home: const MainPage(),
    );
  }
}

class AccountProcess {
  final String id;
  final String name;
  double progress;

  AccountProcess({required this.id, required this.name, this.progress = 0});
}

class Account {
  final String username;
  final String password;
  List<AccountProcess> processes;
  http.Client client;

  Account({
    required this.username,
    required this.password,
    required this.client,
    this.processes = const [], // استخدم const [] بدلاً من [] فقط
  });
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Account> _accounts = [];
  String _notification = '';
  String _speedText = '';
  Uint8List? _captchaImage;
  late OrtEnvironment _env;
  late OrtSession _session;
  bool _modelLoaded = false; // لتتبع حالة تحميل النموذج

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    // تحرير الموارد عند إغلاق الصفحة لتجنب تسرب الذاكرة
    _session.release();
    _env.release();
    // إغلاق جلسات http لكل حساب
    for (var account in _accounts) {
      account.client.close();
    }
    super.dispose();
  }


  Future<void> _loadModel() async {
    try {
      _env = await OrtEnvironment.create();
      // تأكد من تطابق اسم الملف والمسار هنا مع pubspec.yaml ومكان الملف الفعلي
      _session = await _env.createSession('assets/holako-bag.onnx',
          options: SessionOptions()..setIntraOpNumThreads(1));
      setState(() {
         _modelLoaded = true; // تم تحميل النموذج بنجاح
      });
      _showNotification('تم تحميل النموذج بنجاح', success: true);
    } catch (e) {
       setState(() {
         _modelLoaded = false; // فشل تحميل النموذج
      });
      _showNotification('فشل تحميل النموذج: $e', success: false);
      // قد ترغب في إضافة تعامل أكثر قوة مع الخطأ هنا
    }
  }

  void _showNotification(String msg, {bool success = true}) {
    // التأكد من أن الواجهة لا تزال موجودة قبل تحديث الحالة
    if (mounted) {
       setState(() {
        _notification = ArabicHelper.reshape(msg);
      });
    }
    // يمكنك إضافة SnackBar لعرض الإشعار بشكل أفضل
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(ArabicHelper.reshape(msg), textAlign: TextAlign.right),
    //   backgroundColor: success ? Colors.green : Colors.red,
    // ));
  }

  // Helper function for Arabic text reshaping and Bidi
  String _arabic(String text) {
    return ArabicHelper.reshape(text);
  }

  String _generateUserAgent() {
    // قائمة وكلاء المستخدم تبقى كما هي
    const uaList = [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Mobile Safari/537.36",
      "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
    ];
    // استخدام ..shuffle()..first لتبسيط الكود
    return (uaList..shuffle()).first;
  }

  http.Client _createSession() {
    // استخدام Client العادي، ثم إضافة المعدل إليه
    final client = http.Client();
    // استخدام الامتداد (extension) ليبقى الكود أنظف
    client.addRequestModifier((request) async {
      request.headers.addAll({
        'User-Agent': _generateUserAgent(),
        'Host': 'api.ecsc.gov.sy:8443',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'ar,en-US;q=0.7,en;q=0.3',
        'Referer': 'https://ecsc.gov.sy/login', // تأكد من صحة الرابط
        'Content-Type': 'application/json',
        'Source': 'WEB',
        'Origin': 'https://ecsc.gov.sy', // تأكد من صحة الرابط
        'Connection': 'keep-alive',
        // قد تحتاج لإضافة ترويسات أخرى مثل الـ Cookie إذا لزم الأمر بعد تسجيل الدخول
      });
      return request;
    });
    return client;
  }

  Future<bool> _login(Account account) async {
    const url = 'https://api.ecsc.gov.sy:8443/secure/auth/login';
    // إعادة المحاولة 3 مرات كافية
    for (int i = 0; i < 3; i++) {
      try {
        final r = await account.client.post(Uri.parse(url),
            headers: {
              // Content-Type يضاف تلقائياً من المعدل إذا كان jsonEncode مستخدماً
            },
            body: jsonEncode({
              'username': account.username,
              'password': account.password
            }));
        if (r.statusCode == 200) {
          // قد تحتاج لاستخراج توكن أو كوكي من الاستجابة هنا وتخزينها
          // لاستخدامها في الطلبات اللاحقة إذا تطلب الأمر ذلك
          // final responseData = jsonDecode(r.body);
          // final token = responseData['token']; // مثال
          return true; // تسجيل دخول ناجح
        } else {
          // التعامل مع رموز الحالة الأخرى مثل 401 (غير مصرح به)
          _showNotification('فشل تسجيل الدخول (المحاولة ${i+1}): ${r.statusCode}', success: false);
          // لا داعي للمتابعة إذا فشل تسجيل الدخول بشكل واضح
          return false;
        }
      } catch (e) {
        _showNotification('خطأ في الشبكة أثناء تسجيل الدخول (المحاولة ${i+1}): $e', success: false);
        // انتظر قليلاً قبل إعادة المحاولة في حالة خطأ الشبكة
        if (i < 2) await Future.delayed(const Duration(seconds: 1));
      }
    }
    _showNotification('فشل تسجيل الدخول بعد عدة محاولات', success: false);
    return false; // فشل بعد كل المحاولات
  }

  Future<List<AccountProcess>> _fetchProcesses(Account account) async {
    const url = 'https://api.ecsc.gov.sy:8443/dbm/db/execute';
    try {
      final r = await account.client.post(Uri.parse(url),
          headers: {
            // Content-Type يضاف تلقائياً
            'Alias': 'OPkUVkYsyq', // تأكد من صحة هذا الرمز
            'Referer': 'https://ecsc.gov.sy/requests', // تأكد من صحة الرابط
            'Origin': 'https://ecsc.gov.sy' // تأكد من صحة الرابط
            // قد تحتاج لإضافة ترويسة Authorization إذا كان تسجيل الدخول يعيد توكن
            // 'Authorization': 'Bearer $token'
          },
          body: jsonEncode({
            'ALIAS': 'OPkUVkYsyq',
            'P_USERNAME': 'WebSite', // هل هذا صحيح أم يجب أن يكون اسم المستخدم؟
            'P_PAGE_INDEX': 0,
            'P_PAGE_SIZE': 100 // جلب حتى 100 عملية
          }));

      if (r.statusCode == 200) {
        // تأكد من أن الاستجابة ليست فارغة وأن المفتاح P_RESULT موجود
        final decodedBody = jsonDecode(r.body);
        if (decodedBody != null && decodedBody['P_RESULT'] != null) {
            final data = decodedBody['P_RESULT'] as List;
            return data
                .map((e) => AccountProcess(
                    id: e['PROCESS_ID']?.toString() ?? 'unknown_id', // التعامل مع القيم الفارغة
                    name: e['ZCENTER_NAME'] ?? 'عملية غير معروفة' // التعامل مع القيم الفارغة
                 ))
                .toList();
        } else {
           _showNotification('استجابة جلب العمليات غير صالحة أو فارغة', success: false);
           return [];
        }
      } else {
        _showNotification('خطأ في جلب العمليات: ${r.statusCode}', success: false);
        // إذا كان الخطأ 401 أو 403، قد تحتاج لإعادة تسجيل الدخول
        if (r.statusCode == 401 || r.statusCode == 403) {
            _showNotification('جلسة المستخدم غير صالحة، حاول تسجيل الدخول مرة أخرى.', success: false);
            // يمكنك محاولة إعادة تسجيل الدخول هنا تلقائياً
        }
        return [];
      }
    } catch (e) {
      _showNotification('خطأ في الشبكة أثناء جلب العمليات: $e', success: false);
      return [];
    }
  }

 Future<void> _addAccountDialog() async {
    final userController = TextEditingController();
    final pwdController = TextEditingController();
    // استخدام context الآمن داخل العمليات غير المتزامنة
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false, // منع الإغلاق بالضغط خارج المربع
      builder: (context) {
        // استخدام StatefulWidget داخل Dialog لإدارة الحالة (مثل مؤشر التحميل)
        return StatefulBuilder(
           builder: (context, setDialogState) {
            bool isLoading = false; // حالة التحميل الخاصة بالمربع الحواري

            return AlertDialog(
              title: Text(_arabic('إضافة حساب'), textAlign: TextAlign.right),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: userController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(hintText: _arabic('اسم المستخدم')),
                    enabled: !isLoading, // تعطيل الحقل أثناء التحميل
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pwdController,
                    textAlign: TextAlign.right,
                    obscureText: true,
                    decoration: InputDecoration(hintText: _arabic('كلمة المرور')),
                    enabled: !isLoading, // تعطيل الحقل أثناء التحميل
                  ),
                  if (isLoading) ...[ // عرض مؤشر التحميل
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ]
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween, // توزيع الأزرار
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(), // زر إلغاء
                  child: Text(_arabic('إلغاء')),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async {
                    final user = userController.text.trim();
                    final pwd = pwdController.text.trim();
                    if (user.isNotEmpty && pwd.isNotEmpty) {
                       setDialogState(() => isLoading = true); // بدء التحميل

                      final client = _createSession();
                      final tempAccount = Account(username: user, password: pwd, client: client);
                      final loggedIn = await _login(tempAccount);

                      if (loggedIn && mounted) { // التحقق من mounted مرة أخرى
                        _showNotification('تم تسجيل الدخول بنجاح: $user', success: true);
                        final processes = await _fetchProcesses(tempAccount);
                        // تحديث حالة الواجهة الرئيسية وإضافة الحساب
                        setState(() {
                          _accounts.add(Account(
                            username: user,
                            password: pwd, // لا تخزن كلمة المرور إذا لم تكن بحاجة لها بعد الآن
                            client: client, // الاحتفاظ بالجلسة
                            processes: processes,
                          ));
                        });
                        if (mounted) Navigator.of(context).pop(); // إغلاق المربع الحواري بنجاح
                      } else {
                        _showNotification('فشل تسجيل الدخول للحساب: $user', success: false);
                        tempAccount.client.close(); // أغلق الجلسة إذا فشل الدخول
                        if(mounted) setDialogState(() => isLoading = false); // إيقاف التحميل
                      }
                    } else {
                        _showNotification('يرجى إدخال اسم المستخدم وكلمة المرور', success: false);
                    }
                  },
                  child: Text(_arabic('تسجيل الدخول')),
                ),
              ],
            );
          }
        );
      },
    );
  }


  Future<void> _handleCaptcha(Account account, AccountProcess proc) async {
    // التأكد من تحميل النموذج أولاً
    if (!_modelLoaded) {
      _showNotification('النموذج غير جاهز بعد، يرجى الانتظار أو المحاولة مرة أخرى.', success: false);
      return;
    }

    // إعادة تعيين شريط التقدم وإظهار مؤشر تحميل بسيط
    setState(() {
      proc.progress = -1; // استخدام قيمة سالبة للإشارة إلى التحميل
      _captchaImage = null; // مسح الصورة القديمة
      _speedText = ''; // مسح معلومات السرعة
    });

    final b64 = await _getCaptcha(account, proc.id);
    if (b64 == null || !mounted) {
       setState(() {
         proc.progress = 0; // إعادة التعيين إلى الصفر عند الفشل
       });
       return; // الخروج إذا فشل جلب الكابتشا أو تم إغلاق الواجهة
    }
    // تم جلب الكابتشا بنجاح، الآن عرضها ومعالجتها
    await _showAndProcessCaptcha(b64, account, proc);
  }


 Future<String?> _getCaptcha(Account account, String pid) async {
    final url = 'https://api.ecsc.gov.sy:8443/captcha/get/$pid';
    int retries = 0;
    const maxRetries = 5; // تحديد أقصى عدد محاولات

    while (retries < maxRetries) {
      try {
        final r = await account.client.get(Uri.parse(url));

        if (r.statusCode == 200) {
          // التأكد من أن الاستجابة تحتوي على المفتاح 'file'
           final decodedBody = jsonDecode(r.body);
           if (decodedBody != null && decodedBody['file'] is String) {
               return decodedBody['file'] as String;
           } else {
              _showNotification('استجابة جلب الكابتشا غير صالحة.', success: false);
              return null;
           }
        } else if (r.statusCode == 429) { // Too Many Requests
           retries++;
           _showNotification('تم تجاوز الحد الأقصى للطلبات، الانتظار والمحاولة مرة أخرى (${retries}/${maxRetries})...', success: false);
           await Future.delayed(Duration(milliseconds: 200 * retries)); // زيادة فترة الانتظار
        } else if (r.statusCode == 401 || r.statusCode == 403) { // Unauthorized or Forbidden
           _showNotification('الجلسة غير صالحة، محاولة إعادة تسجيل الدخول...', success: false);
           final reLoggedIn = await _login(account);
           if (!reLoggedIn) {
              _showNotification('فشل إعادة تسجيل الدخول، لا يمكن جلب الكابتشا.', success: false);
              return null; // فشل إعادة الدخول، لا يمكن المتابعة
           }
           // إذا نجحت إعادة الدخول، ستستمر الحلقة للمحاولة مرة أخرى
           _showNotification('تمت إعادة تسجيل الدخول، محاولة جلب الكابتشا مرة أخرى...', success: true);
           // لا تزد عدد المحاولات هنا لأننا أعدنا تسجيل الدخول
        } else {
           // أخطاء أخرى في الخادم
           _showNotification('خطأ غير متوقع من الخادم عند جلب الكابتشا: ${r.statusCode}', success: false);
           return null;
        }
      } catch (e) {
         _showNotification('خطأ في الشبكة أثناء جلب الكابتشا: $e', success: false);
         return null; // خطأ شبكة، لا يمكن المتابعة
      }
    }
     _showNotification('فشل جلب الكابتشا بعد $maxRetries محاولات.', success: false);
    return null; // فشل بعد كل المحاولات
  }


 Future<void> _showAndProcessCaptcha(String b64data, Account account, AccountProcess proc) async {
    try {
      final stopwatchTotal = Stopwatch()..start(); // لقياس الوقت الكلي

      // 1. فك التشفير وعرض الصورة الأولية (اختياري)
      final String b64 = b64data.contains(',') ? b64data.split(',')[1] : b64data;
      final Uint8List rawBytes = base64Decode(b64);
      // يمكنك عرض الصورة الخام أولاً إذا أردت
      // setState(() { _captchaImage = rawBytes; });

      // 2. معالجة الصورة باستخدام مكتبة image
      final stopwatchPre = Stopwatch()..start();
      final img.Image? baseImage = img.decodeImage(rawBytes);
      if (baseImage == null) {
        _showNotification('فشل في فك ترميز صورة الكابتشا.', success: false);
        setState(() => proc.progress = 0);
        return;
      }

      // ----- بدء المعالجة المسبقة -----
      // يمكنك تجربة طرق معالجة مختلفة هنا
      // مثال 1: تحويل لرمادي ثم تطبيق حد للعتبة (Thresholding)
      img.Image processedImage = img.grayscale(baseImage); // تحويل إلى التدرج الرمادي
      processedImage = img.threshold(processedImage, threshold: 128, thresholdMethod: img.ThresholdMethod.binary); // تحويل إلى أبيض وأسود

      // مثال 2: (بديل) زيادة التباين قبل Thresholding
      // processedImage = img.adjustColor(baseImage, contrast: 150); // زيادة التباين
      // processedImage = img.grayscale(processedImage);
      // processedImage = img.threshold(processedImage, threshold: 128, thresholdMethod: img.ThresholdMethod.binary);

      // ----- نهاية المعالجة المسبقة -----

      final Uint8List processedBytes = Uint8List.fromList(img.encodePng(processedImage));
      stopwatchPre.stop();

       if (!mounted) return; // التحقق مرة أخرى قبل تحديث الواجهة
      // عرض الصورة المعالجة
      setState(() {
        _captchaImage = processedBytes;
      });


      // 3. تجهيز المدخلات للنموذج (ONNX)
      final stopwatchPreModel = Stopwatch()..start();
      // تأكد أن طريقة المعالجة هذه تتوافق مع ما تم تدريب النموذج عليه
      final Tensor inputTensor = _preprocessForModel(processedImage); // استخدم الصورة المعالجة
      stopwatchPreModel.stop();


      // 4. التنبؤ باستخدام النموذج
      final stopwatchPred = Stopwatch()..start();
      final String prediction = await _predictCaptcha(inputTensor);
      stopwatchPred.stop();

      stopwatchTotal.stop(); // إيقاف المؤقت الكلي

      if (!mounted) return;

      setState(() {
        // عرض أوقات المعالجة والتنبؤ
        _speedText = _arabic('معالجة الصورة: ${stopwatchPre.elapsedMilliseconds}ms | تجهيز للنموذج: ${stopwatchPreModel.elapsedMilliseconds}ms | التنبؤ: ${stopwatchPred.elapsedMilliseconds}ms | الإجمالي: ${stopwatchTotal.elapsedMilliseconds}ms');
      });

      _showNotification(_arabic('تم التنبؤ بالكابتشا: ') + prediction, success: true);

      // 5. إرسال الحل
      await _submitCaptcha(account, proc.id, prediction);

      // 6. تحديث شريط التقدم للإشارة إلى الاكتمال
       if (!mounted) return;
      setState(() {
        proc.progress = 1.0; // اكتمل بنجاح
      });

    } catch (e) {
      _showNotification('حدث خطأ أثناء معالجة أو التنبؤ بالكابتشا: $e', success: false);
       if (mounted) {
         setState(() {
           proc.progress = 0; // فشل، إعادة التعيين
           _speedText = _arabic('فشل في معالجة الكابتشا');
         });
       }
    }
 }

  // يجب أن تتوافق هذه الدالة تماماً مع كيفية تدريب نموذج ONNX
  Tensor _preprocessForModel(img.Image image) {
    // الأبعاد التي يتوقعها النموذج (مثال: 224x224 بـ 3 قنوات لونية RGB)
    const int modelInputWidth = 224;
    const int modelInputHeight = 224;
    const int channels = 3; // RGB

    // 1. تغيير الحجم (Resize)
    // استخدم خوارزمية استيفاء مناسبة، مثل LINEAR أو CUBIC
    final img.Image resizedImage = img.copyResize(
        image,
        width: modelInputWidth,
        height: modelInputHeight,
        interpolation: img.Interpolation.linear // أو .cubic
    );

    // 2. إنشاء مصفوفة المدخلات (Float32List)
    // الحجم: [batch_size, channels, height, width] أو [batch_size, height, width, channels]
    // يعتمد على تنسيق الإدخال الذي يتوقعه نموذج ONNX الخاص بك.
    // هذا المثال يفترض [1, 3, 224, 224] وهو تنسيق شائع (NCHW)
    final inputList = Float32List(1 * channels * modelInputHeight * modelInputWidth);
    int pixelIndex = 0;

    // 3. التطبيع (Normalization)
    // يجب أن يتطابق تماماً مع التطبيع المستخدم أثناء التدريب.
    // المثال الشائع هو تطبيع القيم لتكون بين [0, 1] أو [-1, 1] أو استخدام متوسط وانحراف معياري معينين (مثل ImageNet).

    // مثال: تطبيع إلى [0, 1] ثم إلى [-1, 1]
    // (value / 255.0) ثم ((value / 255.0) - 0.5) / 0.5
    const double mean = 0.5; // أو المتوسط المستخدم في التدريب
    const double std = 0.5;  // أو الانحراف المعياري المستخدم في التدريب

    for (int y = 0; y < modelInputHeight; y++) {
      for (int x = 0; x < modelInputWidth; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // استخراج قنوات الألوان (حتى لو كانت الصورة رمادية، كرر القيمة 3 مرات إذا كان النموذج يتوقع RGB)
        double red = img.getRed(pixel) / 255.0;
        double green = img.getGreen(pixel) / 255.0;
        double blue = img.getBlue(pixel) / 255.0;

        // تطبيق التطبيع (مثال: [-1, 1])
        // تأكد من أن ترتيب القنوات (RGB أو BGR) يطابق ما يتوقعه النموذج
        inputList[pixelIndex] = (red - mean) / std;         // القناة الحمراء
        inputList[pixelIndex + modelInputHeight * modelInputWidth] = (green - mean) / std; // القناة الخضراء
        inputList[pixelIndex + 2 * modelInputHeight * modelInputWidth] = (blue - mean) / std; // القناة الزرقاء

        pixelIndex++; // انتقل إلى البيكسل التالي في ترتيب HWC الداخلي للمصفوفة
      }
    }

    // إنشاء Tensor بالشكل الصحيح [batch_size, channels, height, width]
    final shape = [1, channels, modelInputHeight, modelInputWidth];
    return OrtValueTensor.createTensorValueFromList(inputList, shape);
  }

  // يجب أن تتوافق هذه الدالة مع مخرجات نموذج ONNX الخاص بك
  Future<String> _predictCaptcha(Tensor inputTensor) async {
    try {
      // 1. تشغيل النموذج (Run Inference)
      // تأكد من أن اسم 'input' يطابق اسم طبقة الإدخال في نموذج ONNX
      final outputs = await _session.run(['output'], {'input': inputTensor}); // استبدل 'output' و 'input' بالأسماء الصحيحة من نموذجك

      // 2. معالجة المخرجات (Post-processing)
      final outputValue = outputs[0];
      if (outputValue == null) {
          throw Exception("Output from model is null");
      }

      // الحصول على البيانات والشكل من الـ Tensor الناتج
      // قد يكون الناتج Float32List أو List<dynamic> حسب النموذج
      final outputData = outputValue.value; // يمكن أن يكون List<double> أو List<List<double>> الخ
      final outputShape = outputValue.shape; // شكل المصفوفة الناتجة

      await outputValue.release(); // تحرير الذاكرة للناتج

      // ----- بدء تحليل المخرجات -----
      // يعتمد بشكل كبير على كيفية بناء النموذج وماذا يمثل الناتج.
      // المثال هنا يفترض أن الناتج هو مصفوفة احتمالات لكل حرف في كل موقع.
      // الشكل المتوقع للناتج قد يكون مثل: [batch_size, sequence_length, num_classes]
      // أو [batch_size, num_classes * sequence_length]

      // مثال افتراضي: الناتج هو [1, 5 * 36] حيث 5 هو طول الكابتشا و 36 عدد الأحرف الممكنة
      if (outputData is List<double> && outputShape.length == 2 && outputShape[0] == 1) {
          const String charset = '0123456789abcdefghijklmnopqrstuvwxyz'; // الأحرف المتوقعة
          final int numPositions = outputShape[1] ~/ charset.length; // حساب عدد المواقع (طول الكابتشا)
          final StringBuffer result = StringBuffer();

          for (int i = 0; i < numPositions; i++) {
              // استخراج جزء الاحتمالات الخاص بالموقع الحالي
              final int startIndex = i * charset.length;
              final List<double> segment = outputData.sublist(startIndex, startIndex + charset.length);

              // البحث عن الحرف ذو الاحتمال الأعلى (Argmax)
              double maxProb = -double.infinity;
              int maxIndex = -1;
              for (int j = 0; j < segment.length; j++) {
                  if (segment[j] > maxProb) {
                      maxProb = segment[j];
                      maxIndex = j;
                  }
              }

              if (maxIndex != -1) {
                 result.write(charset[maxIndex]);
              } else {
                 result.write('?'); // علامة استفهام إذا لم يتم العثور على احتمال
              }
          }
           return result.toString();
      } else {
         // إذا كان شكل الناتج أو نوعه مختلفًا، تحتاج لتعديل هذه المعالجة
         throw Exception("Unexpected model output format. Shape: $outputShape, Type: ${outputData.runtimeType}");
      }
      // ----- نهاية تحليل المخرجات -----

    } catch (e) {
        print("Error during prediction: $e"); // طباعة الخطأ للمساعدة في التصحيح
        return "error"; // أو رمي استثناء ليتم التقاطه في الدالة المستدعية
    }
  }


  Future<void> _submitCaptcha(Account account, String pid, String solution) async {
    final url = 'https://api.ecsc.gov.sy:8443/rs/reserve?id=$pid&captcha=$solution';
    try {
      _showNotification('جاري إرسال الحل: $solution', success: true);
      final r = await account.client.get(Uri.parse(url)
          // قد تحتاج لإضافة ترويسات هنا أيضاً إذا لزم الأمر
          // headers: { 'Authorization': 'Bearer $token' }
          );

      if (r.statusCode == 200) {
        // نجح الإرسال - تحقق من نص الاستجابة إذا كان مهماً
        _showNotification('تم التثبيت بنجاح: ${r.body}', success: true);
      } else {
         // فشل الإرسال - تحقق من رمز الحالة ونص الاستجابة
         _showNotification('فشل إرسال الكابتشا: ${r.statusCode} - ${r.body}', success: false);
      }
    } catch (e) {
      _showNotification('خطأ في الشبكة أثناء إرسال الكابتشا: $e', success: false);
    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_arabic('حل الكابتشا الآلي')),
        actions: [
          // زر لإعادة تحميل النموذج إذا فشل
          if (!_modelLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: _arabic('إعادة تحميل النموذج'),
              onPressed: _loadModel,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // لجعل العناصر تمتد بعرض الشاشة
          children: [
            // منطقة الإشعارات
            if (_notification.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.grey[200],
                child: Text(
                  _notification,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            // زر إضافة حساب
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(_arabic('إضافة حساب جديد')),
              onPressed: _addAccountDialog, // استدعاء دالة المربع الحواري
            ),
            const SizedBox(height: 10),

            // قائمة الحسابات والعمليات
            Expanded(
              child: _accounts.isEmpty
                  ? Center(child: Text(_arabic('لم تتم إضافة أي حسابات بعد.')))
                  : ListView.separated(
                      itemCount: _accounts.length,
                      separatorBuilder: (context, index) => const Divider(height: 20, thickness: 1),
                      itemBuilder: (context, accountIndex) {
                        final account = _accounts[accountIndex];
                        return Card( // استخدام Card لتحسين المظهر
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _arabic('الحساب: ') + account.username,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (account.processes.isEmpty)
                                   Text(_arabic('لا توجد عمليات متاحة لهذا الحساب.'), textAlign: TextAlign.right)
                                else
                                  ...account.processes.map((proc) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          // زر تشغيل العملية
                                          ElevatedButton(
                                            // تعطيل الزر إذا كان النموذج غير جاهز أو العملية قيد التشغيل
                                            onPressed: (!_modelLoaded || proc.progress == -1)
                                              ? null
                                              : () => _handleCaptcha(account, proc),
                                            child: Text(_arabic(proc.name)),
                                          ),
                                          const SizedBox(width: 12),
                                          // شريط التقدم أو مؤشر التحميل
                                          Expanded(
                                            child: proc.progress == -1 // حالة التحميل
                                              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                              : LinearProgressIndicator(
                                                  value: proc.progress < 0 ? 0 : proc.progress, // تأكد أن القيمة بين 0 و 1
                                                  minHeight: 10, // جعل الشريط أكثر وضوحاً
                                                  backgroundColor: Colors.grey[300],
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    proc.progress == 1.0 ? Colors.green : Colors.blue,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // منطقة عرض الكابتشا وسرعة المعالجة
            if (_captchaImage != null)
              Padding(
                 padding: const EdgeInsets.symmetric(vertical: 10.0),
                 child: Column(
                   children: [
                     Text(_arabic("الصورة المعالجة:"), style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 5),
                     Image.memory(
                       _captchaImage!,
                       fit: BoxFit.contain,
                       height: 100, // تحديد ارتفاع مناسب
                       gaplessPlayback: true, // لمنع الوميض عند التحديث
                     ),
                   ],
                 ),
              ),
            if (_speedText.isNotEmpty)
              Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(
                  _speedText,
                  textAlign: TextAlign.center, // أو right
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// امتداد (Extension) لإضافة معدل الطلبات إلى http.Client بسهولة
extension HttpClientRequestModifier on http.Client {
  // هذه الطريقة تعدل سلوك الدالة send الأصلية
  void addRequestModifier(
      FutureOr<http.BaseRequest> Function(http.BaseRequest) modifier) {
    // نحتفظ بمرجع للدالة send الأصلية
    final originalSend = send;

    // نعيد تعريف الدالة send لهذا الكائن (instance)
    send = (http.BaseRequest request) async {
      // نطبق التعديل على الطلب قبل إرساله
      final modifiedRequest = await modifier(request);
      // نستدعي الدالة send الأصلية مع الطلب المعدل
      return originalSend(modifiedRequest);
    };
  }
}

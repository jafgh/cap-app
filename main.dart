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
      title: 'حل الكابتشا',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoNaskhArabic',
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
    this.processes = const [],
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

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _env = await OrtEnvironment.create();
      _session = await _env.createSession('assets/holako-bag.onnx',
          options: SessionOptions()..setIntraOpNumThreads(1));
      _showNotification('تم تحميل النموذج بنجاح', success: true);
    } catch (e) {
      _showNotification('فشل تحميل النموذج: \$e', success: false);
    }
  }

  void _showNotification(String msg, {bool success = true}) {
    setState(() {
      _notification = ArabicHelper.reshape(msg);
    });
    // Optionally change color based on success
  }

  String _arabic(String text) {
    // reshape and bidi
    return ArabicHelper.reshape(text);
  }

  String _generateUserAgent() {
    const uaList = [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Mobile Safari/537.36",
      "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
    ];
    return (uaList..shuffle()).first;
  }

  http.Client _createSession() {
    final client = http.Client();
    client.addRequestModifier((request) async {
      request.headers.addAll({
        'User-Agent': _generateUserAgent(),
        'Host': 'api.ecsc.gov.sy:8443',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'ar,en-US;q=0.7,en;q=0.3',
        'Referer': 'https://ecsc.gov.sy/login',
        'Content-Type': 'application/json',
        'Source': 'WEB',
        'Origin': 'https://ecsc.gov.sy',
        'Connection': 'keep-alive',
      });
      return request;
    });
    return client;
  }

  Future<bool> _login(Account account) async {
    const url = 'https://api.ecsc.gov.sy:8443/secure/auth/login';
    for (int i = 0; i < 3; i++) {
      try {
        final r = await account.client.post(Uri.parse(url),
            body: jsonEncode({
              'username': account.username,
              'password': account.password
            }));
        if (r.statusCode == 200) return true;
        return false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<List<AccountProcess>> _fetchProcesses(Account account) async {
    const url = 'https://api.ecsc.gov.sy:8443/dbm/db/execute';
    try {
      final r = await account.client.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Alias': 'OPkUVkYsyq',
            'Referer': 'https://ecsc.gov.sy/requests',
            'Origin': 'https://ecsc.gov.sy'
          },
          body: jsonEncode({
            'ALIAS': 'OPkUVkYsyq',
            'P_USERNAME': 'WebSite',
            'P_PAGE_INDEX': 0,
            'P_PAGE_SIZE': 100
          }));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['P_RESULT'] as List;
        return data
            .map((e) => AccountProcess(
                id: e['PROCESS_ID'].toString(), name: e['ZCENTER_NAME'] ?? 'غير معروف'))
            .toList();
      }
    } catch (e) {
      _showNotification('خطأ في جلب العمليات: \$e', success: false);
    }
    return [];
  }

  Future<void> _addAccountDialog() async {
    final userController = TextEditingController();
    final pwdController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_arabic('إضافة حساب'), textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: userController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(hintText: _arabic('اسم المستخدم')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pwdController,
              textAlign: TextAlign.right,
              obscureText: true,
              decoration: InputDecoration(hintText: _arabic('كلمة المرور')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final user = userController.text.trim();
              final pwd = pwdController.text.trim();
              if (user.isNotEmpty && pwd.isNotEmpty) {
                Navigator.of(context).pop();
                final client = _createSession();
                final account = Account(
                    username: user, password: pwd, client: client);
                final ok = await _login(account);
                if (ok) {
                  _showNotification('تم تسجيل الدخول: \$user', success: true);
                  final procs = await _fetchProcesses(account);
                  setState(() {
                    _accounts.add(Account(
                        username: user,
                        password: pwd,
                        client: client,
                        processes: procs));
                  });
                } else {
                  _showNotification('فشل تسجيل الدخول', success: false);
                }
              }
            },
            child: Text(_arabic('تسجيل الدخول')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCaptcha(Account account, AccountProcess proc) async {
    setState(() {
      proc.progress = 0;
    });
    final b64 = await _getCaptcha(account, proc.id);
    if (b64 == null) return;
    await _showCaptcha(b64, account, proc);
  }

  Future<String?> _getCaptcha(Account account, String pid) async {
    final url = 'https://api.ecsc.gov.sy:8443/captcha/get/\$pid';
    try {
      while (true) {
        final r = await account.client.get(Uri.parse(url));
        if (r.statusCode == 200) {
          return jsonDecode(r.body)['file'] as String;
        } else if (r.statusCode == 429) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        } else if (r.statusCode == 401 || r.statusCode == 403) {
          final ok = await _login(account);
          if (!ok) return null;
        } else {
          _showNotification('خطأ في الخادم: \${r.statusCode}', success: false);
          return null;
        }
      }
    } catch (e) {
      _showNotification('خطأ في جلب الكابتشا: \$e', success: false);
    }
    return null;
  }

  Future<void> _showCaptcha(String b64data, Account account, AccountProcess proc) async {
    final b64 = b64data.contains(',') ? b64data.split(',')[1] : b64data;
    final raw = base64Decode(b64);
    final image = img.decodeImage(raw)!;
    // simple processing: convert to grayscale and threshold
    final gray = img.grayscale(image);
    final binary = img.threshold(gray, threshold: 128);
    final procBytes = Uint8List.fromList(img.encodePng(binary));
    setState(() {
      _captchaImage = procBytes;
    });
    final stopwatchPre = Stopwatch()..start();
    final input = _preprocessForModel(binary);
    stopwatchPre.stop();
    final stopwatchPred = Stopwatch()..start();
    final pred = await _predictCaptcha(input);
    stopwatchPred.stop();
    setState(() {
      _speedText = _arabic('المعالجة: \${stopwatchPre.elapsedMilliseconds} ملليثانية | التنبؤ: \${stopwatchPred.elapsedMilliseconds} ملليثانية');
    });
    _showNotification(_arabic('الناتج المتوقع للكابتشا: ') + pred, success: true);
    await _submitCaptcha(account, proc.id, pred);
    setState(() {
      proc.progress = 1;
    });
  }

  Tensor _preprocessForModel(img.Image image) {
    // resize to 224x224 and normalize
    final resized = img.copyResize(image, width: 224, height: 224);
    final Float32List input = Float32List(1 * 3 * 224 * 224);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = resized.getPixel(x, y);
        final r = ((p >> 16) & 0xFF) / 255.0;
        final g = ((p >> 8) & 0xFF) / 255.0;
        final b = (p & 0xFF) / 255.0;
        // normalize to [-1,1]
        input[idx++] = (r - 0.5) / 0.5;
        input[idx++] = (g - 0.5) / 0.5;
        input[idx++] = (b - 0.5) / 0.5;
      }
    }
    return Tensor.fromList([1, 3, 224, 224], input);
  }

  Future<String> _predictCaptcha(Tensor input) async {
    final outputs = await _session.run({ 'input': input });
    final out = outputs.first.data as List<double>;
    // reshape and argmax
    const charset = '0123456789abcdefghijklmnopqrstuvwxyz';
    const numPos = 5;
    final buffer = StringBuffer();
    for (int i = 0; i < numPos; i++) {
      final segment = out.skip(i * charset.length).take(charset.length).toList();
      final idx = segment.indexWhere((d) => d == segment.reduce((a, b) => a > b ? a : b));
      buffer.write(charset[idx]);
    }
    return buffer.toString();
  }

  Future<void> _submitCaptcha(Account account, String pid, String solution) async {
    final url = 'https://api.ecsc.gov.sy:8443/rs/reserve?id=\$pid&captcha=\$solution';
    try {
      final r = await account.client.get(Uri.parse(url));
      _showNotification('تم التثبيت: \${r.body}', success: r.statusCode == 200);
    } catch (e) {
      _showNotification('خطأ في الإرسال: \$e', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_arabic('حل الكابتشا')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (_notification.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(
                  _notification,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ElevatedButton(
              onPressed: _addAccountDialog,
              child: Text(_arabic('إضافة حساب')),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _accounts.length,
                itemBuilder: (context, ai) {
                  final account = _accounts[ai];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _arabic('الحساب: ') + account.username,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 18),
                      ),
                      ...account.processes.map((proc) {
                        return Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _handleCaptcha(account, proc),
                              child: Text(_arabic(proc.name)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(value: proc.progress),
                            ),
                          ],
                        );
                      }).toList(),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
            if (_captchaImage != null)
              Image.memory(_captchaImage!, fit: BoxFit.contain, height: 200),
            if (_speedText.isNotEmpty)
              Text(
                _speedText,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

// Extension to add request modifier for http.Client
extension RequestModifier on http.Client {
  void addRequestModifier(
      FutureOr<http.BaseRequest> Function(http.BaseRequest) modifier) {
    final innerSend = send;
    send = (http.BaseRequest request) async {
      final modified = await modifier(request);
      return innerSend(modified);
    };
  }
}

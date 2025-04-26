import 'dart:convert';
import 'dart:io'; // For HttpClient and badCertificateCallback
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // For IOClient
import '../utils/constants.dart';
import '../models/account.dart'; // ستحتاج لإنشاء هذا الملف
import '../models/api_process.dart'; // ستحتاج لإنشاء هذا الملف
import 'dart:math'; // For Random

class ApiService {
  // استخدام IOClient لتجاوز مشاكل شهادة SSL (مثل verify=False في Python)
  // تحذير: هذا يجعل الاتصال أقل أمانًا. استخدمه فقط إذا كنت متأكدًا.
  http.Client createHttpClient() {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  String generateUserAgent() {
    const uaList = [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 15_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Mobile Safari/537.36",
      "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0"
    ];
    return uaList[Random().nextInt(uaList.length)];
  }

  // دالة لتسجيل الدخول
  Future<Map<String, dynamic>> login(String username, String password) async {
    final client = createHttpClient();
    final headers = {
      "User-Agent": generateUserAgent(),
      "Host": "api.ecsc.gov.sy:8443",
      "Accept": "application/json, text/plain, */*",
      "Accept-Language": "ar,en-US;q=0.7,en;q=0.3",
      "Referer": "https://ecsc.gov.sy/login",
      "Content-Type": "application/json",
      "Source": "WEB",
      "Origin": "https://ecsc.gov.sy",
      "Connection": "keep-alive",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-site",
    };
    final body = jsonEncode({"username": username, "password": password});

    try {
      final response = await client.post(
        Uri.parse(loginUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // محاولة استخراج الكوكيز من الرد لتمريرها في الطلبات اللاحقة
        String? rawCookie = response.headers['set-cookie'];
        // قد تحتاج لمعالجة الكوكيز بشكل أفضل
        return {'success': true, 'cookies': rawCookie, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'statusCode': response.statusCode, 'error': response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      client.close();
    }
  }

  // دالة لجلب قائمة العمليات
  Future<List<ApiProcess>> fetchProcessIds(String? cookies) async {
     if (cookies == null) return []; // لا يمكن المتابعة بدون كوكيز الجلسة

    final client = createHttpClient();
    final headers = {
        "User-Agent": generateUserAgent(),
        "Host": "api.ecsc.gov.sy:8443",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "ar,en-US;q=0.7,en;q=0.3",
        "Referer": "https://ecsc.gov.sy/requests",
        "Content-Type": "application/json",
        "Source": "WEB",
        "Origin": "https://ecsc.gov.sy",
        "Connection": "keep-alive",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-site",
        "Alias": "OPkUVkYsyq", // Alias required by the API
        'Cookie': cookies, // استخدام الكوكيز من تسجيل الدخول
    };
    final payload = {
      "ALIAS": "OPkUVkYsyq",
      "P_USERNAME": "WebSite", // قد تحتاج لتمرير اسم المستخدم الفعلي هنا؟
      "P_PAGE_INDEX": 0,
      "P_PAGE_SIZE": 100
    };

    try {
        final response = await client.post(
            Uri.parse(processListUrl),
            headers: headers,
            body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final results = data['P_RESULT'] as List?;
            if (results != null) {
              // تحويل البيانات الخام إلى قائمة من كائنات ApiProcess
              return results.map((item) => ApiProcess.fromJson(item)).toList();
            }
            return [];
        } else {
            print("Fetch IDs failed: ${response.statusCode}");
            return [];
        }
    } catch (e) {
        print("Error fetching IDs: $e");
        return [];
    } finally {
        client.close();
    }
  }

  // دالة لجلب الكابتشا (تحتاج لمعرف العملية وكوكيز الجلسة)
  Future<String?> getCaptcha(String processId, String cookies) async {
    final client = createHttpClient();
    final url = Uri.parse("$baseApiUrl/captcha/get/$processId");
     final headers = {
        "User-Agent": generateUserAgent(),
        "Host": "api.ecsc.gov.sy:8443",
        "Accept": "application/json, text/plain, */*",
        "Referer": "https://ecsc.gov.sy/", // قد تحتاج لتحديثه
        "Origin": "https://ecsc.gov.sy",
        "Connection": "keep-alive",
        'Cookie': cookies,
    };

    try {
      // قد تحتاج لإعادة المحاولة عند الخطأ 429 كما في كود Python
      final response = await client.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['file']; // يحتوي على بيانات الصورة base64
      } else {
         print("Get Captcha failed: ${response.statusCode}");
         // قد تحتاج لمعالجة 401/403 بإعادة تسجيل الدخول
        return null;
      }
    } catch (e) {
       print("Get Captcha error: $e");
      return null;
    } finally {
      client.close();
    }
  }

  // دالة لإرسال حل الكابتشا
 Future<Map<String, dynamic>> submitCaptcha(String processId, String solution, String cookies) async {
    final client = createHttpClient();
    final url = Uri.parse("$baseApiUrl/rs/reserve?id=$processId&captcha=$solution");
     final headers = {
        "User-Agent": generateUserAgent(),
        "Host": "api.ecsc.gov.sy:8443",
        "Accept": "*/*", // قد يختلف القبول هنا
        "Referer": "https://ecsc.gov.sy/", // قد تحتاج لتحديثه
        "Origin": "https://ecsc.gov.sy",
        "Connection": "keep-alive",
        'Cookie': cookies,
    };

    try {
      final response = await client.get(url, headers: headers);
      return {
        'statusCode': response.statusCode,
        'body': response.body,
        'success': response.statusCode == 200
        };
    } catch (e) {
       print("Submit Captcha error: $e");
       return {'success': false, 'error': e.toString()};
    } finally {
      client.close();
    }
  }
}

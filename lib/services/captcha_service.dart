import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'onnx_service.dart'; // ستحتاج لإنشاء هذا الملف
import '../utils/constants.dart';

class CaptchaService {
  final OnnxService _onnxService = OnnxService(); // تحميل خدمة ONNX

  Future<void> loadModel() async {
    // استدعاء دالة تحميل النموذج في OnnxService
    await _onnxService.loadModel();
  }

  // دالة المعالجة المسبقة والتنبؤ
  Future<Map<String, dynamic>?> processAndPredict(String base64Data) async {
    try {
      Stopwatch stopwatch = Stopwatch()..start();

      // 1. فك تشفير Base64
      final String b64 = base64Data.contains(',') ? base64Data.split(',')[1] : base64Data;
      final Uint8List imageBytes = base64Decode(b64);

      // 2. التعامل مع GIF واستخراج الإطارات (باستخدام مكتبة image)
      final animation = img.decodeGif(imageBytes);
      if (animation == null || animation.isEmpty) {
        print("Could not decode GIF or GIF is empty");
        return null;
      }

      // 3. حساب الصورة الوسيطة (Median Background) - يتطلب تنفيذًا مخصصًا!
      // هذا مثال مبسط جدًا وقد لا يكون دقيقًا أو فعالًا
      // للحصول على نتيجة أفضل، يجب حساب الوسيط لكل بكسل عبر جميع الإطارات.
      // حاليًا، سنستخدم الإطار الأول فقط للتبسيط.
      final firstFrame = animation.frames.first.image;

      // --- بداية الجزء الصعب جدًا للترجمة المباشرة ---

      // 4. تحويل لرمادي (Grayscale)
      final grayscaleImage = img.grayscale(firstFrame);

      // 5. تطبيق CLAHE (غير متوفر مباشرة في مكتبة image)
      // **تحتاج لتنفيذ خوارزمية CLAHE يدويًا أو استخدام مكتبة أخرى أو تخطي هذه الخطوة**
      // مثال: لنفترض أننا تخطينا CLAHE حاليًا
      img.Image enhancedImage = grayscaleImage; // بدون CLAHE

      // 6. تطبيق Otsu Thresholding (غير متوفر مباشرة في مكتبة image)
      // **تحتاج لتنفيذ خوارزمية Otsu يدويًا أو استخدام مكتبة أخرى أو تخطي هذه الخطوة**
      // مثال: تطبيق حد ثنائي بسيط كبديل مؤقت
      // img.Image binaryImage = img.threshold(enhancedImage, threshold: 128); // قيمة الحد تحتاج لضبط
      // بما أن الكود الأصلي يستخدم Otsu، سنتركها كصورة رمادية محسنة (إذا طبقنا CLAHE)
      // أو فقط صورة رمادية حاليًا
       img.Image binaryImage = enhancedImage; // بدون Otsu فعلي

      // --- نهاية الجزء الصعب ---

       final preprocessTime = stopwatch.elapsedMilliseconds;
       stopwatch.reset();

      // 7. تجهيز الصورة للنموذج (Resize, Normalize)
      // يجب أن تطابق الأبعاد والتحويلات المستخدمة في تدريب النموذج ONNX
      final resizedImage = img.copyResize(binaryImage, width: 224, height: 224);

      // تحويل لصيغة الإدخال المتوقعة من النموذج (قد تكون Float32List)
      // يجب أن تطابق تحويلات torchvision (Normalize [0.5, 0.5, 0.5], [0.5, 0.5, 0.5])
      // هذا الجزء يعتمد بشدة على كيفية عمل مكتبة ONNX التي ستستخدمها وكيف تتوقع المدخلات.
      // المثال التالي هو تخمين عام وقد يحتاج لتعديل كبير.
      final inputData = _prepareInputForOnnx(resizedImage);

      // 8. تشغيل التنبؤ باستخدام ONNX Service
      final output = await _onnxService.runInference(inputData);
      final predictTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      if (output == null) {
        print("ONNX inference failed");
        return null;
      }

      // 9. فك تشفير المخرجات
      final predictedString = _decodeOutput(output);

      // 10. إعادة الصورة المعالجة (للغرض العرض) كـ Uint8List
      // قد ترغب في عرض الصورة الرمادية أو الثنائية
       final processedImageBytes = Uint8List.fromList(img.encodePng(binaryImage));

      return {
        'prediction': predictedString,
        'processedImage': processedImageBytes, // الصورة بعد المعالجة
        'preprocessTime': preprocessTime,
        'predictTime': predictTime,
      };

    } catch (e) {
      print("Error processing captcha: $e");
      return null;
    }
  }

  // --- دوال مساعدة تحتاج لتنفيذ دقيق ---

  // لتحويل الصورة من مكتبة `image` إلى تنسيق المدخلات المناسب لنموذج ONNX
  // يعتمد على النموذج والمكتبة المستخدمة (قد يكون Float32List أو غيره)
  // يجب أن يطبق الـ Normalization [0.5, 0.5, 0.5], [0.5, 0.5, 0.5]
  // ويحول الصورة الرمادية إلى 3 قنوات كما في الكود الأصلي
  dynamic _prepareInputForOnnx(img.Image image) {
    // --- هذا التنفيذ مجرد مثال تخطيطي ---
    // يحتاج لتفاصيل دقيقة بناءً على مكتبة ONNX ومتطلبات النموذج
    var inputTensor = Float32List(1 * 3 * 224 * 224); // Shape [1, 3, H, W]
    int pixelIndex = 0;
    for (int y = 0; y < 224; ++y) {
      for (int x = 0; x < 224; ++x) {
        var pixel = image.getPixel(x, y);
        // الحصول على القيمة الرمادية (نفترض أن img.grayscale تعطي قيمة واحدة)
        double grayValue = img.getLuminance(pixel) / 255.0; // قيمة بين 0.0 و 1.0
        // تطبيق Normalization وتكرارها لـ 3 قنوات
        double normalizedValue = (grayValue - 0.5) / 0.5;

        inputTensor[pixelIndex] = normalizedValue; // القناة 1 (R)
        inputTensor[224 * 224 + pixelIndex] = normalizedValue; // القناة 2 (G)
        inputTensor[2 * 224 * 224 + pixelIndex] = normalizedValue; // القناة 3 (B)
        pixelIndex++;
      }
    }
    // قد تحتاج لإعادة تشكيل القائمة لتطابق أبعاد الإدخال المتوقعة بالضبط
    // مثلاً: return [ [ [ inputTensor ] ] ]; إذا كانت المكتبة تتوقع قائمة من القوائم
    return inputTensor; // أو أي شكل آخر تتطلبه مكتبة ONNX
  }

  // لفك تشفير مخرجات نموذج ONNX
  // المخرجات في Python كانت [1, NUM_POS * NUM_CLASSES] ثم أعيد تشكيلها
  String _decodeOutput(dynamic output) {
    // --- هذا التنفيذ مجرد مثال تخطيطي ---
    // يعتمد على شكل المخرجات الفعلي من مكتبة ONNX
    if (output is! List || output.isEmpty) return "Error";

    // افتراض أن المخرجات هي قائمة مسطحة من الاحتمالات
     if (output is List<double> || output is List<num> || output is Float32List) {
        final flattenedOutput = (output as List).map((e) => e.toDouble()).toList();

        if(flattenedOutput.length != numPos * numClasses) {
             print("Output length mismatch: ${flattenedOutput.length}");
             return "LenErr";
        }

        StringBuffer prediction = StringBuffer();
        for (int i = 0; i < numPos; ++i) {
            // تحديد بداية ونهاية احتمالات الحرف الحالي
            int start = i * numClasses;
            int end = start + numClasses;
            List<double> charProbs = flattenedOutput.sublist(start, end);

            // إيجاد الفئة ذات الاحتمال الأعلى (argmax)
            double maxProb = -1.0;
            int bestClassIndex = -1;
            for (int j = 0; j < numClasses; ++j) {
                if (charProbs[j] > maxProb) {
                    maxProb = charProbs[j];
                    bestClassIndex = j;
                }
            }

            if (bestClassIndex != -1 && idx2char.containsKey(bestClassIndex)) {
                prediction.write(idx2char[bestClassIndex]);
            } else {
                prediction.write('?'); // حرف غير معروف
            }
        }
        return prediction.toString();

     } else {
         print ("Unexpected output type: ${output.runtimeType}");
         return "TypeErr";
     }
  }
}

[app]

# (str) عنوان تطبيقك
title = CaptchaApp

# (str) اسم الحزمة
package.name = captchaapp

# (str) نطاق الحزمة (مطلوب لتغليف android/ios)
package.domain = com.yourdomain

# (str) مجلد الكود المصدري حيث يوجد main.py
source.dir = .

# (list) امتدادات الملفات التي تريد تضمينها
source.include_exts = py,kv,ttf,onnx,png,jpg

# (list) الأنماط الإضافية للتضمين
source.include_patterns = assets/*

# (str) إصدار التطبيق
version = 0.1

# (list) متطلبات التطبيق
requirements = python3,kivy,hostpython3,onnxruntime,opencv-python-headless,numpy,pillow,requests,arabic-reshaper,python-bidi,torch,torchvision

# (bool) تفعيل دعم AndroidX (مهم إذا Kivy ≥ 2.0.0)
android.enable_androidx = True

# (bool) ملء الشاشة
fullscreen = 0

# (list) الاتجاهات المدعومة (اختياري)
# orientation = portrait

# ------------------------------------------------------------------
#                        إعدادات Android
# ------------------------------------------------------------------

# (list) الأذونات
android.permissions = INTERNET

# (int) واجهة برمجة تطبيقات Android المستهدفة (Target API)
android.api = 31

# (int) الحد الأدنى لـ API
android.minapi = 21

# (str) نسخة NDK
android.ndk = 23b

# (str) نسخة Build Tools
android.build_tools_version = 31.0.0

# (str) نسخة Command-line Tools (لفك مشكلة sdkmanager)
android.cmdline_tools_version = 9123335

# (list) المعماريات المراد البناء لها
android.archs = arm64-v8a, armeabi-v7a

# ------------------------------------------------------------------
#               ضبط python-for-android branch إلى develop
# ------------------------------------------------------------------

# (str) استخدم فرع develop لـ python-for-android لتوافق أفضل
p4a.branch = develop


# ==================================================================
#                     قسم [buildozer] العام
# ==================================================================
[buildozer]

# (int) مستوى السجل (0=أخطاء فقط،1=معلومات،2=تصحيح)
log_level = 2

# (int) تحكم في تحذيرات root (-1=لا،0=سطح المكتب فقط،1=الكل)
warn_on_root = 1

# (str) (اختياري) مسارات مخصصة
# buildozer_dir = .buildozer
# bin_dir = ./bin
# cache_dir = %(buildozer_dir)s/cache
# build_dir = %(buildozer_dir)s/build

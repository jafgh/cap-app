[app]

# (str) عنوان تطبيقك
title = CaptchaApp

# (str) اسم الحزمة
package.name = captchaapp

# (str) نطاق الحزمة (مطلوب لتغليف android/ios)
package.domain = com.yourdomain

# (str) مجلد الكود المصدري حيث يوجد main.py
source.dir = .

# (list) ملفات المصدر لتضمينها (دع buildozer يكتشفها)
source.include_exts = py,kv,ttf,onnx,png,jpg

# (list) قائمة التضمينات باستخدام مطابقة الأنماط
source.include_patterns = assets/*

# (str) إصدار التطبيق
version = 0.1

# (list) متطلبات التطبيق
requirements = python3,kivy,hostpython3,onnxruntime,opencv-python-headless,numpy,pillow,requests,arabic-reshaper,python-bidi,torch,torchvision

# (str) تفعيل دعم AndroidX. يجب تفعيله إذا كنت تستخدم Kivy >= 2.0.0
android.enable_androidx = True

# (bool) هل التطبيق بملء الشاشة أم لا
fullscreen = 0

# (list) الاتجاهات المدعومة
# orientation = portrait

# (str) اسم ملف الأيقونة
# icon.filename = %(source.dir)s/data/icon.png

# (str) مسار Presplash (شاشة البداية)
# presplash.filename = %(source.dir)s/data/presplash.png
# presplash.background_color = #FFFFFF


# ------------------------------------------------------------------
#                          إعدادات Android
# ------------------------------------------------------------------

# (list) الأذونات المطلوبة
android.permissions = INTERNET

# (int) واجهة برمجة تطبيقات Android المستهدفة (Target API)
android.api = 31

# (int) الحد الأدنى المطلوب لواجهة برمجة التطبيقات (Minimum API)
android.minapi = 21

# (str) إصدار Android NDK للاستخدام
android.ndk = 23b

# (str) إصدار أدوات بناء Android (Build Tools)
android.build_tools_version = 31.0.0

# (str) إصدار أدوات سطر أوامر Android (Command-line Tools)
android.cmdline_tools_version = 9123335

# (list) المعماريات المراد البناء لها
android.archs = arm64-v8a, armeabi-v7a

# (bool) نسخ المكتبات إلى مجلد البيانات العام
# android.copy_libs = 1

# (list) مكتبات Android المشتركة (إن وجدت)
# android.add_libs_arm64_v8a = libs/arm64-v8a/libpango.so
# android.add_libs_armeabi_v7a = libs/armeabi-v7a/libpango.so

# (str) سمة تطبيق Android
# android.manifest.theme = "@android:style/Theme.NoTitleBar"


# ==================================================================
#                         قسم [buildozer] العام
# ==================================================================
[buildozer]

# مستوى السجل (0 = أخطاء فقط، 1 = معلومات، 2 = تصحيح)
log_level = 2

# عرض رسائل التحذير (-1 = لا، 0 = سطح المكتب فقط، 1 = الكل)
warn_on_root = 1

# مسارات مخصصة (خيارية)
# buildozer_dir = .buildozer
# bin_dir = ./bin
# cache_dir = %(buildozer_dir)s/cache
# build_dir = %(buildozer_dir)s/build

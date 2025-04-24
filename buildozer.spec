[app]
# (str) عنوان تطبيقك
title = CaptchaApp

# (str) اسم الحزمة
package.name = captchaapp

# (str) النطاق العكسي (لتوليد الـ package id)
package.domain = com.yourdomain

# (str) مسار الكود المصدري (حيث يوجد main.py)
source.dir = .

# (list) امتدادات الملفات التي تريد تضمينها
source.include_exts = py,kv,ttf,onnx,png,jpg

# (list) أنماط إضافية (لملفّات الأصول)
source.include_patterns = assets/*

# (str) إصدار التطبيق
version = 0.1

# (list) المتطلبات (Python packages)
requirements = python3,kivy,onnxruntime,opencv-python-headless,numpy,pillow,requests,arabic-reshaper,python-bidi,torch,torchvision

# (bool) تشغيل على كامل الشاشة؟
fullscreen = 0

# (bool) دعم AndroidX
android.enable_androidx = True

# (list) اتجاهات الواجهة
# orientation = portrait

# ------------------------------------------------------------------
#                        إعدادات Android
# ------------------------------------------------------------------

# (list) الأذونات
android.permissions = INTERNET

# (int) Target API level
android.api = 31

# (int) Minimum API level
android.minapi = 21

# (str) NDK version
android.ndk = 23b

# (str) Build Tools version
android.build_tools_version = 31.0.0

# (list) المعماريات
android.archs = arm64-v8a,armeabi-v7a

# ------------------------------------------------------------------
#            استخدام develop branch لـ python-for-android
# ------------------------------------------------------------------
p4a.branch = develop

# ------------------------------------------------------------------
#                إعدادات log و root warnings
# ------------------------------------------------------------------
[buildozer]
# (int) log_level: 0 = errors only, 1 = info, 2 = debug
log_level = 2
# (int) warn_on_root: -1 = no, 0 = warn only, 1 = root warnings
warn_on_root = 1

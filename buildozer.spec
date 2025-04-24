[app]

# معلومات التطبيق
title = CaptchaApp
package.name = captchaapp
package.domain = com.yourdomain
version = 1.0.0

# مصدر الشيفرة والأصول
source.dir = .
source.include_exts = py,kv,ttf,onnx,png,jpg
source.include_patterns = assets/*

# المتطلبات
requirements = python3,kivy,onnxruntime,torch,torchvision,opencv-python,numpy,pillow,requests,arabic-reshaper,python-bidi

# صلاحيات أندرويد
android.permissions = INTERNET

# إعدادات SDK/API
android.api = 31
android.minapi = 21
android.target = 31

# NDK و Build Tools
android.ndk = 23b
android.build_tools_version = 31.0.0

# خيارات إضافية
# android.ndk_path =
# android.sdk_path =

# التوجيه لواجهة رسومية بدلًا من سطر الأوامر
fullscreen = 1
orientation = portrait

# أيقونات وشاشة البداية (اختياري)
# icon.filename = %(source.dir)s/icon.png
# presplash.filename = %(source.dir)s/splash.png

# توقيع التطبيق (release)
# android.release = 1
# android.keystore = myapp.keystore
# android.keyalias = mykey
# android.keyalias_password = password
# android.keystore_password = password

[buildozer]

# مسار مجلد البناء
# buildozer_dir = .buildozer
log_level = 2
warn_on_root = 1

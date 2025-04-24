[app]

# ----------------------------------------
# معلومات التطبيق
# ----------------------------------------
title = CaptchaApp
package.name = captchaapp
package.domain = com.yourdomain

# ----------------------------------------
# مصدر الشيفرة والأصول
# ----------------------------------------
source.dir = .
source.include_exts = py,kv,ttf,onnx,png,jpg
source.include_patterns = assets/*

# ----------------------------------------
# المتطلبات
# ----------------------------------------
requirements = python3,kivy,onnxruntime,torch,torchvision,opencv-python,numpy,pillow,requests,arabic-reshaper,python-bidi

# ----------------------------------------
# صلاحيات أندرويد
# ----------------------------------------
android.permissions = INTERNET

# ----------------------------------------
# إعدادات SDK/API
# ----------------------------------------
android.api = 31
android.minapi = 21
android.target = 31

# ----------------------------------------
# NDK و Build Tools
# ----------------------------------------
android.ndk = 23b
android.build_tools_version = 31.0.0

# ----------------------------------------
# وضع البناء
# ----------------------------------------
# debug للإختبار، release للتوزيع
# android.release = True

[buildozer]

# يمكنك ضبط مسار buildozer محليًا إن أردت
# buildozer_dir = .buildozer

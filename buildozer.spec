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
# source.include_exts = py,png,jpg,kv,atlas
source.include_exts = py,kv,ttf,onnx,png,jpg

# (list) قائمة التضمينات باستخدام مطابقة الأنماط
# source.include_patterns = assets/*,images/*.png
source.include_patterns = assets/*

# (list) ملفات المصدر لاستبعادها (دع buildozer يكتشفها)
# source.exclude_exts = spec

# (list) قائمة المجلدات لاستبعادها (دع buildozer يكتشفها)
# source.exclude_dirs = tests, bin

# (list) قائمة الاستبعادات باستخدام مطابقة الأنماط
# source.exclude_patterns = license,images/*/*.jpg

# (str) إصدار التطبيق (الطريقة 1)
version = 0.1

# (str) إصدار التطبيق (الطريقة 2)
# version.regex = __version__ = ['"](.*)['"]
# version.filename = %(source.dir)s/main.py

# (list) متطلبات التطبيق
# مفصولة بفواصل، مثال: requirements = sqlite3,kivy
# تأكد من وجود python3, kivy, hostpython3 لتطبيقات Kivy.
# أضف تبعياتك الخاصة هنا. كن على علم بأن المكتبات المعقدة مثل
# torch, torchvision, onnxruntime, و opencv قد تتطلب وصفات مخصصة (recipes)
# أو قد لا تكون مدعومة مباشرة بواسطة python-for-android.
# ابدأ بالأساسيات وأضف الأخرى تدريجيًا إذا لزم الأمر.
requirements = python3,kivy,hostpython3,onnxruntime,opencv-python-headless,numpy,pillow,requests,arabic-reshaper,python-bidi,torch,torchvision
# ملاحظة: تم استخدام opencv-python-headless لأنه غالبًا ما يكون أسهل في البناء على Android.
# ملاحظة: قد تكون torch و torchvision إشكالية وتتطلب إعدادًا متقدمًا.

# (str) مجلدات مصدر مخصصة للمتطلبات
# requirements.source.kivymd = ../../kivymd

# (str) لون خلفية شاشة البداية (presplash) (يستخدم مع presplash.png)
# presplash.background_color = #FFFFFF

# (str) اسم ملف صورة شاشة البداية (presplash)
# presplash.filename = %(source.dir)s/data/presplash.png

# (str) اسم ملف الأيقونة
# icon.filename = %(source.dir)s/data/icon.png

# (list) الاتجاهات المدعومة
# orientation = landscape
# orientation = portrait
# orientation = all

# (list) قائمة الخدمات للإعلان عنها
# services = NAME:ENTRYPOINT_TO_PY,NAME2:ENTRYPOINT2_TO_PY


# ==================================================================
#                         خيارات خاصة بنظام Android
# ==================================================================

# (bool) تحديد ما إذا كان التطبيق يجب أن يكون بملء الشاشة أم لا
fullscreen = 0

# (string) لون خلفية شاشة البداية (presplash) (يستخدم مع presplash.png)
# android.presplash_color = #FFFFFF

# (str) لون خلفية الأيقونة التكيفية السداسي (مثال: #FFFFFF)
# android.adaptive_icon_background = #(hex)

# (str) ملف مقدمة الأيقونة التكيفية (مثال: assets/icon_fg.png - ألفا فقط)
# android.adaptive_icon_foreground = %(source.dir)s/assets/adaptive_icon_fg.png

# (list) الأذونات المطلوبة
android.permissions = INTERNET

# (list) الميزات المستخدمة بواسطة التطبيق.
# android.features = android.hardware.usb.host

# (int) واجهة برمجة تطبيقات Android المستهدفة (Target API)، يجب أن تتوافق مع متطلبات Google Play
android.api = 31

# (int) الحد الأدنى المطلوب لواجهة برمجة التطبيقات (Minimum API)
android.minapi = 21

# (int) إصدار Android SDK للاستخدام (عادةً ما يتم تحديده تلقائيًا)
# android.sdk = 24

# (str) إصدار Android NDK للاستخدام
android.ndk = 23b

# (str) مجلد Android NDK (إذا كان مخصصًا وغير موجود في المسار الافتراضي)
# android.ndk_path =

# (str) إصدار أدوات بناء Android (إذا كان مخصصًا)
android.build_tools_version = 31.0.0

# (str) إصدار أدوات سطر أوامر Android (إذا كان مخصصًا)
# android.cmdline_tools_version = latest

# (str) تحديد المعماريات (architectures) المراد البناء لها
android.archs = arm64-v8a, armeabi-v7a

# (list) مشاريع مكتبات Android للإضافة (غير مدعوم حاليًا)
# android.library_references =

# (list) مكتبات Android المشتركة للإضافة (عادةً لتجاوز الوصفات)
# android.add_libs_arm64_v8a = libs/arm64-v8a/libpango.so
# android.add_libs_armeabi_v7a = libs/armeabi-v7a/libpango.so

# (bool) نسخ المكتبات إلى مجلد البيانات العام (مُوصى به للمشاريع الجديدة)
# android.copy_libs = 1

# (str) سمة تطبيق Android (إما "Light" أو "Dark")
# android.manifest.theme = "@android:style/Theme.NoTitleBar"

# (list) نمط القائمة البيضاء لـ webview الداخلي
# android.whitelist =

# (str) مسار إلى مخزن المفاتيح (keystore) للتوقيع (يستخدم فقط في وضع الإصدار release)
# android.keystore.path =

# (str) اسم مستعار لمخزن المفاتيح (keystore alias) (يستخدم فقط في وضع الإصدار release)
# android.keystore.alias =

# (str) كلمة مرور مخزن المفاتيح (keystore password) (يستخدم فقط في وضع الإصدار release)
# android.keystore.password =

# (str) كلمة مرور المفتاح (key password) (يستخدم فقط في وضع الإصدار release)
# android.key.password =

# (bool) تفعيل دعم AndroidX. يجب تفعيله إذا كنت تستخدم Kivy >= 2.0.0
android.enable_androidx = True

# (str) مسار إلى ملف بناء Gradle الإضافي (.gradle)، نسبي إلى مجلد البناء
# android.gradle_extra_build_file =

# (str) وسيطات JVM لتمريرها إلى Gradle
# android.gradle_jvm_args = -Xmx2048m

# (list) تبعيات Gradle للإضافة
# android.gradle_dependencies =

# (bool) توقيع APK باستخدام apksigner بدلاً من jarsigner (يستخدم لـ SDK 24+)
# android.enable_apksigner = False

# (str) تحديد موقع ملف تكوين مفتاح التوقيع
# (يستخدم فقط إذا تم تفعيل android.enable_apksigner)
# android.apksigner_args_path = %(source.dir)s/apksigner.json

# (str) فرع python-for-android المخصص للاستخدام، الافتراضي هو "master"
# استخدام فرع 'develop' غالبًا ما يحل مشاكل التوافق مع أدوات SDK الحديثة
p4a.branch = develop


# ==================================================================
#                         خيارات خاصة بـ Buildozer
# ==================================================================

# (str) مستوى السجل (0 = أخطاء فقط، 1 = معلومات، 2 = تصحيح (مع إخراج الأوامر))
log_level = 2

# (int) عرض رسائل التحذير (-1 = لا، 0 = سطح المكتب فقط، 1 = الكل)
warn_on_root = 1

# يمكنك إلغاء التعليق وتعيين هذه إذا لزم الأمر، ولكن الافتراضيات عادة ما تكون جيدة
# buildozer_dir = .buildozer
# bin_dir = ./bin
# cache_dir = %(buildozer_dir)s/cache
# build_dir = %(buildozer_dir)s/build


# ==================================================================
#                         خيارات خاصة بـ iOS (غير ذات صلة هنا ولكن مدرجة للاكتمال)
# ==================================================================

# (str) Path to Kivy-iOS project
# ios.kivy_ios_dir = ../kivy-ios
# Automaticly remove the build folder (used to reset the cache)
# ios.clean_build = 0
# Show Xcode project after build
# ios.open_xcode = 0
# (str) Kivy-iOS branch to use, defaults to "master"
# ios.branch = master
# Another optional setting to select the directory where kivy-ios is located
# ios.ios_deploy_dir = ~/.ios-deploy


# ==================================================================
#                         قسم [buildozer] العام
# ==================================================================
[buildozer]

# (int) مستوى السجل (0 = أخطاء فقط، 1 = معلومات، 2 = تصحيح (مع إخراج الأوامر))
log_level = 2

# (int) عرض رسائل التحذير (-1 = لا، 0 = سطح المكتب فقط، 1 = الكل)
warn_on_root = 1

# يمكنك إلغاء التعليق وتعيين هذه إذا كنت بحاجة إلى مسارات مخصصة
# buildozer_dir = .buildozer
# bin_dir = ./bin
# cache_dir = %(buildozer_dir)s/cache
# build_dir = %(buildozer_dir)s/build

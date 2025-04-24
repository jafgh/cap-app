```ini
[app]
# (str) Title of your application
title = CAPTCHA Solver
# (str) Package name
package.name = captcha_solver
# (str) Package domain (reverse DNS style)
package.domain = org.example
# (str) Source code directory
source.dir = .
# (list) List of inclusions using pattern matching
source.include_exts = py,kv,ttf,png,jpg
# (str) Application versioning (method 1)
version = 0.1

# (list) Application requirements
requirements = python3,kivy,requests,pillow,opencv-python-headless,onnxruntime,torch,torchvision,numpy

# (str) Supported orientation (portrait, landscape or all)
orientation = portrait

# (bool) Indicate if the application should be fullscreen
fullscreen = 0

# (int) Android API to use
android.api = 28
# (int) Minimum Android API required
android.minapi = 21
# (int) Android SDK version to use
android.sdk = 20
# (str) Android NDK version to use
android.ndk = 19b
# (str) Android NDK path (if required)
#android.ndk_path = /home/runner/Android/Sdk/ndk/19.2.5345600

# (list) Permissions
android.permissions = INTERNET

# (str) Supported architectures
android.arch = armeabi-v7a

# (bool) Use --private data storage (True) or --dir public storage (False)
android.private_storage = True

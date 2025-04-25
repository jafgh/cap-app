[app]

# (str) Title of your application
title = تطبيق الكابتشا

# (str) Package name - *** غيّر هذا إلى اسم حزمة فريد ***
package.name = captchasolver

# (str) Package domain (needed for Android/iOS) - *** غيّر هذا ***
package.domain = org.example

# (str) Source code where the main.py live
source.dir = .

# (str) Filename of the main application
source.main_py = main.py

# (list) List of inclusions/exclusions
# source.include_exts = py,png,jpg,kv,atlas
# source.exclude_dirs = tests, bin
# source.exclude_patterns = license,images/*/*.jpg

# (str) Application versioning (method 1)
version = 0.1

# (list) Requirements - Needs careful tuning!
# Add all necessary Python packages. OpenCV and ONNX Runtime can be tricky.
# Ensure versions are compatible if needed.
requirements = python3,kivy,numpy,opencv-python-headless,onnxruntime,requests,pillow,python-bidi,arabic_reshaper,torchvision,cython

# (str) Custom source folders for requirements
# requirements.source.kivymd = ../../kivymd

# (str) Presplash background color (name or # RRGGBB)
# presplash.color = #FFFFFF

# (str) Icon filename
# icon.filename = %(source.dir)s/data/icon.png

# (str) Supported orientation (landscape, portrait, all)
orientation = portrait

# (list) List of service descriptions
# services = NAME:ENTRYPOINT_TO_PY,NAME2:ENTRYPOINT2_TO_PY

#
# Android specific options
#

# (list) Permissions
android.permissions = INTERNET, WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE

# (int) Android API level minimum - Android 7.0 Nougat
android.minapi = 24

# (int) Android API level target - Android 14
android.api = 34

# (str) Android SDK version to use (corresponding to API 34)
android.sdk = 34

# (str) Android Build Tools version to use (a stable version for SDK 34)
android.build_tools = 34.0.0

# (str) Android NDK version to use (e.g., 25c or 26c are common recent choices)
android.ndk = 26c

# (list) The Android archs to build for, choices: armeabi-v7a, arm64-v8a, x86, x86_64
android.archs = arm64-v8a, armeabi-v7a

# (bool) Copy library files to project (useful for debugging)
# android.copy_libs = 1

# (bool) Pattern to include files or directories. Relative to source directory.
# Note: Use this to include your 'assets' folder
android.add_patterns = assets/*

# (list) Path to jars to include, relative to source directory
# android.add_jars = libs/android/*

# (bool) Indicate if the application should be fullscreen or not
# android.fullscreen = 0

# (bool) Prevent app from turning screen off
# android.wakelock = 0

# (str) Minimum NDK API level to use (uses android.minapi if not set)
# android.ndk_api = 24

# (str) Python for android branch to use, defaults to master
# p4a.branch = master

# (bool) Let p4a update itself (required for first build or when changing branch)
p4a.allow_update = True

#
# Buildozer specific options
#

# (int) Log level (0 = error only, 1 = info, 2 = debug (with command output))
log_level = 2

# (int) Display warning messages (0 = no warnings, 1 = default warnings, 2 = all warnings)
warning_mode = 1

[app]

# (str) Title of your application
title = تطبيق الكابتشا

# (str) Package name
package.name = captchasolver

# (str) Package domain (needed for Android/iOS)
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
# Use 'opencv-python-headless' for mobile builds usually.
# Ensure versions are compatible if needed.
requirements = python3,kivy,numpy,opencv-python-headless,onnxruntime,requests,pillow,python-bidi,arabic_reshaper,torchvision,cython

# (str) Custom source folders for requirements
# requirements.source.kivymd = ../../kivymd

# (str) Presplash background color (name or # RRGGBB)
# presplash.color = #FFFFFF

# (str) Presplash image filename (used along with presplash.color)
# presplash.filename = %(source.dir)s/data/presplash.png

# (str) Presplash animation filename (overrides presplash.filename if exists)
# presplash.filename_animated = %(source.dir)s/data/presplash_animated.gif

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

# (int) Android API level minimum
# android.minapi = 21

# (int) Android API level target
# android.api = 33 # Target a recent API level like 33 or 34

# (str) Android NDK version to use
# android.ndk = 25b

# (str) Android SDK version to use
# android.sdk = 33

# (list) The Android archs to build for, choices: armeabi-v7a, arm64-v8a, x86, x86_64
android.archs = arm64-v8a, armeabi-v7a

# (bool) Copy library files to project (useful for debugging)
# android.copy_libs = 1

# (str) The Android Splash image path (relative to the source directory)
# android.presplash = %(source.dir)s/data/android_presplash.png

# (str) The filename of the launch image
# android.launcher_filename = %(source.dir)s/data/launch_image.png

# (str) The icon filename path (relative to the source directory)
# android.icon = %(source.dir)s/data/icon.png

# (bool) Pattern to include files or directories. Relative to source directory.
# Note: Use this to include your 'assets' folder
android.add_patterns = assets/*

# (list) List of Java files to add to the android project (can be java or jar).
# android.add_src =

# (list) Path to jars to include, relative to source directory
# android.add_jars = libs/android/*

# (list) List of Java files to add to the android project (can be java or jar).
# android.add_libs_armeabi = libs/android-armeabi/*

# (list) Android AAR dependencies (currently not supported)
# android.add_aars =

# (bool) Indicate if the application should be fullscreen or not
# android.fullscreen = 0

# (bool) Prevent app from turning screen off
# android.wakelock = 0

# (list) Android application meta-data (key=value format)
# android.meta_data =

# (list) Android library project dependencies (required by mapview)
# android.library_references =

# (list) Android shared libraries dependencies (needed by websockets)
# android.add_libs_arm64_v8a = libs/android-arm64-v8a/*

# (str) Minimum NDK API level to use
# android.ndk_api = 21

# (bool) Use --enable-shared argument in configure. Requires NDK 21+
# android.enable_shared = 0

# (str) If you need custom build steps (must contain android_cython_build hook)
# android.build_tool =

# (str) Android entry point, default is ok for Kivy-based app
# android.entrypoint = org.kivy.android.PythonActivity

# (str) Python for android branch to use, defaults to master
# p4a.branch = master

# (str) The directory in which python-for-android should be cloned
# p4a.source_dir =

# (str) Command to execute before p4a build, relative to source directory
# p4a.prebuild =

# (str) Command to execute after p4a build, relative to source directory
# p4a.postbuild =

# (bool) Let p4a update itself (required for first build or when changing branch)
p4a.allow_update = True

#
# Buildozer specific options
#

# (int) Log level (0 = error only, 1 = info, 2 = debug (with command output))
log_level = 2

# (int) Display warning messages (0 = no warnings, 1 = default warnings, 2 = all warnings)
warning_mode = 1

# (str) Path to build artifact storage, defaults to bin
# bin_dir = ./bin

# (str) Path to build output workspace, defaults to .buildozer
# build_dir = ./.buildozer

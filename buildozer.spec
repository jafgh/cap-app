[app]

# (str) Title of your application
title = CaptchaApp

# (str) Package name
package.name = captchaapp

# (str) Package domain (needed for android/ios packaging)
package.domain = com.yourdomain

# (str) Source code where the main.py live
source.dir = .

# (list) Source files to include (let buildozer figure it out)
# source.include_exts = py,png,jpg,kv,atlas
source.include_exts = py,kv,ttf,onnx,png,jpg

# (list) List of inclusions using pattern matching
# source.include_patterns = assets/*,images/*.png
source.include_patterns = assets/*

# (list) Source files to exclude (let buildozer figure it out)
# source.exclude_exts = spec

# (list) List of directory to exclude (let buildozer figure it out)
# source.exclude_dirs = tests, bin

# (list) List of exclusions using pattern matching
# source.exclude_patterns = license,images/*/*.jpg

# (str) Application versioning (method 1)
version = 0.1

# (str) Application versioning (method 2)
# version.regex = __version__ = ['"](.*)['"]
# version.filename = %(source.dir)s/main.py

# (list) Application requirements
# comma separated e.g. requirements = sqlite3,kivy
# Ensure python3, kivy, and hostpython3 are present for Kivy apps
# Add your specific dependencies here. Be aware that complex libraries like
# torch, torchvision, onnxruntime, and opencv might require custom recipes
# or might not be directly supported by python-for-android out-of-the-box.
# Start with the core ones and add others incrementally if needed.
requirements = python3,kivy,hostpython3,onnxruntime,opencv-python-headless,numpy,pillow,requests,arabic-reshaper,python-bidi,torch,torchvision
# Note: Used opencv-python-headless as it's often easier to build on Android
# Note: torch and torchvision might be problematic and require advanced setup.

# (str) Custom source folders for requirements
# requirements.source.kivymd = ../../kivymd

# (str) Presplash background color (used with presplash.png)
# presplash.background_color = #FFFFFF

# (str) Presplash image filename
# presplash.filename = %(source.dir)s/data/presplash.png

# (str) Icon filename
# icon.filename = %(source.dir)s/data/icon.png

# (list) Supported orientations
# orientation = landscape
# orientation = portrait
# orientation = all

# (list) List of service to declare
# services = NAME:ENTRYPOINT_TO_PY,NAME2:ENTRYPOINT2_TO_PY

#
# Android specific options
#

# (bool) Indicate if the application should be fullscreen or not
fullscreen = 0

# (string) Presplash background color (used with presplash.png)
# android.presplash_color = #FFFFFF

# (str) Adaptive icon background hexagon color (e.g. #FFFFFF)
# android.adaptive_icon_background = #(hex)

# (str) Adaptive icon foreground file (e.g. assets/icon_fg.png - alpha only)
# android.adaptive_icon_foreground = %(source.dir)s/assets/adaptive_icon_fg.png

# (list) Permissions
android.permissions = INTERNET

# (list) features used by the application.
# android.features = android.hardware.usb.host

# (int) Target Android API, should be aligned with API requirements
android.api = 31

# (int) Minimum API required
android.minapi = 21

# (int) Android SDK version to use
# android.sdk = 24

# (str) Android NDK version to use
android.ndk = 23b

# (str) Android NDK directory (if required)
# android.ndk_path =

# (str) Android build tools version (if custom)
android.build_tools_version = 31.0.0

# (str) Android Command line tools version (if custom)
# android.cmdline_tools_version = 8.0

# (str) Specify architectures to build for
android.archs = arm64-v8a, armeabi-v7a

# (list) Android library project to add (currently not supported)
# android.library_references =

# (list) Android shared libraries to add (usually for recipe overrides)
# android.add_libs_arm64_v8a = libs/arm64-v8a/libpango.so
# android.add_libs_armeabi_v7a = libs/armeabi-v7a/libpango.so

# (bool) Copy libraries to public data folder (RECOMMENDED for new projects)
# android.copy_libs = 1

# (str) The Android application theme (either "Light" or "Dark")
# android.manifest.theme = "@android:style/Theme.NoTitleBar"

# (list) Pattern to whitelist for the internal webview
# android.whitelist =

# (str) Path to keystore for signing (used only in release mode)
# android.keystore.path =

# (str) Keystore alias (used only in release mode)
# android.keystore.alias =

# (str) Keystore password (used only in release mode)
# android.keystore.password =

# (str) Key password (used only in release mode)
# android.key.password =

# (bool) Enables AndroidX support. Enable if using Kivy >= 2.0.0
android.enable_androidx = True

# (str) Path to Gradle extra build file (.gradle), relative to build dir
# android.gradle_extra_build_file =

# (str) JVM arguments to pass to Gradle
# android.gradle_jvm_args = -Xmx2048m

# (list) Gradle dependencies to add
# android.gradle_dependencies =

# (bool) Sign APK using apksigner instead of jarsigner (used for SDK 24+)
# android.enable_apksigner = False

# (str) Specify the location of the signing key config file
# (used only if android.enable_apksigner is enabled)
# android.apksigner_args_path = %(source.dir)s/apksigner.json


#
# Buildozer specific options
#

# (str) Log level (0 = error only, 1 = info, 2 = debug (with command output))
log_level = 2

# (int) Display warning messages (-1 = no, 0 = desktop only, 1 = all)
warn_on_root = 1

# (str) Buildozer cache directory
# buildozer_dir = .buildozer

# (str) The default download cache location
# download_cache = %(buildozer_dir)s/cache

# (str) The platform specific build directory
# build_dir = %(buildozer_dir)s/android/platform

# (str) The python-for-android directory
# p4a.source_dir = %(buildozer_dir)s/android/p4a

# (str) The python-for-android build directory
# p4a.build_dir = %(buildozer_dir)s/android/p4a_build

# (str) Custom python-for-android branch to use, defaults to "master"
# p4a.branch = develop


#
# iOS specific options (not relevant here but included for completeness)
#

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


[buildozer]
# (int) Log level (0 = error only, 1 = info, 2 = debug (with command output))
log_level = 2

# (int) Display warning messages (-1 = no, 0 = desktop only, 1 = all)
warn_on_root = 1

# You can uncomment and set these if needed, but defaults are usually fine
# buildozer_dir = .buildozer
# bin_dir = ./bin
# cache_dir = %(buildozer_dir)s/cache
# build_dir = %(buildozer_dir)s/build

@echo off
"C:\\Users\\Paulo Henrique\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\src\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\groovy" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=21" ^
  "-DANDROID_PLATFORM=android-21" ^
  "-DANDROID_ABI=x86" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86" ^
  "-DANDROID_NDK=C:\\Users\\Paulo Henrique\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\Paulo Henrique\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\Paulo Henrique\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\Paulo Henrique\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=M:\\freelancer\\99freelas\\clube_app\\android\\app\\build\\intermediates\\cxx\\RelWithDebInfo\\ad6u1k67\\obj\\x86" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=M:\\freelancer\\99freelas\\clube_app\\android\\app\\build\\intermediates\\cxx\\RelWithDebInfo\\ad6u1k67\\obj\\x86" ^
  "-DCMAKE_BUILD_TYPE=RelWithDebInfo" ^
  "-BM:\\freelancer\\99freelas\\clube_app\\android\\app\\.cxx\\RelWithDebInfo\\ad6u1k67\\x86" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli

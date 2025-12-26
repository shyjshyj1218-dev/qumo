#!/bin/bash

echo "🚀 Android 테스트 환경 설정"
echo ""

# Homebrew 확인
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew가 설치되어 있지 않습니다."
    echo "Homebrew 설치: https://brew.sh"
    exit 1
fi

echo "📦 ADB (Android Debug Bridge) 설치 중..."
brew install --cask android-platform-tools

echo ""
echo "✅ 설치 완료!"
echo ""
echo "다음 단계:"
echo "1. Android 기기를 USB로 연결"
echo "2. 기기에서 'USB 디버깅 허용' 선택"
echo "3. 다음 명령어로 확인:"
echo "   adb devices"
echo "4. Flutter 앱 실행:"
echo "   flutter run"
echo ""


#!/bin/bash

echo "📱 Android 무선 디버깅 설정"
echo ""

# ADB 설치 확인
if ! command -v adb &> /dev/null; then
    echo "📦 ADB가 설치되어 있지 않습니다. 설치 중..."
    if command -v brew &> /dev/null; then
        brew install --cask android-platform-tools
    else
        echo "❌ Homebrew가 설치되어 있지 않습니다."
        echo "Homebrew 설치: https://brew.sh"
        exit 1
    fi
fi

echo "✅ ADB 설치 확인됨"
echo ""

# Android 버전 확인
echo "📋 Android 버전 확인:"
echo "1. Android 11 이상 (무선 디버깅)"
echo "2. Android 10 이하 (ADB over Wi-Fi)"
echo ""
read -p "Android 버전을 선택하세요 (1 또는 2): " version

if [ "$version" == "1" ]; then
    echo ""
    echo "🔗 Android 11+ 무선 디버깅 설정"
    echo ""
    echo "기기에서 다음을 확인하세요:"
    echo "1. 설정 → 개발자 옵션 → 무선 디버깅 활성화"
    echo "2. 무선 디버깅 메뉴 진입"
    echo "3. '페어링 코드로 기기 페어링' 선택"
    echo "4. 페어링 코드와 IP:포트 확인"
    echo ""
    read -p "페어링할 IP 주소와 포트를 입력하세요 (예: 192.168.0.100:12345): " pair_address
    
    if [ -z "$pair_address" ]; then
        echo "❌ IP 주소와 포트를 입력해주세요."
        exit 1
    fi
    
    echo ""
    echo "페어링 중..."
    adb pair "$pair_address"
    
    echo ""
    read -p "연결할 IP 주소와 포트를 입력하세요 (기기에서 표시된 새로운 주소): " connect_address
    
    if [ -z "$connect_address" ]; then
        echo "❌ 연결 주소를 입력해주세요."
        exit 1
    fi
    
    echo ""
    echo "연결 중..."
    adb connect "$connect_address"
    
elif [ "$version" == "2" ]; then
    echo ""
    echo "🔗 Android 10 이하 ADB over Wi-Fi 설정"
    echo ""
    echo "⚠️  처음 한 번은 USB로 연결해야 합니다."
    echo ""
    read -p "USB로 기기를 연결했나요? (y/n): " usb_connected
    
    if [ "$usb_connected" != "y" ]; then
        echo "USB로 기기를 연결한 후 다시 실행해주세요."
        exit 1
    fi
    
    echo ""
    echo "TCP/IP 모드 활성화 중..."
    adb tcpip 5555
    
    echo ""
    echo "기기의 IP 주소를 확인하세요:"
    echo "설정 → Wi-Fi → 연결된 네트워크 → IP 주소"
    echo ""
    read -p "기기의 IP 주소를 입력하세요 (예: 192.168.0.100): " ip_address
    
    if [ -z "$ip_address" ]; then
        echo "❌ IP 주소를 입력해주세요."
        exit 1
    fi
    
    echo ""
    echo "USB를 분리한 후 연결 중..."
    adb connect "$ip_address:5555"
else
    echo "❌ 잘못된 선택입니다."
    exit 1
fi

echo ""
echo "연결 확인 중..."
sleep 2
adb devices

echo ""
echo "✅ 설정 완료!"
echo ""
echo "이제 다음 명령어로 Flutter 앱을 실행할 수 있습니다:"
echo "flutter run"
echo ""


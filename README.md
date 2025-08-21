# ZeroWaste ♻️

지역 주민이 불법 쓰레기 투기 현장을 손쉽게 제보하고, 이를 지도 위에 실시간으로 시각화하는 **환경 감시 플랫폼**입니다.  
주민 참여형 환경 감시를 통해 무단투기 감소와 환경 개선을 목표로 합니다.  

---

## 📌 프로젝트 개요
- **프로젝트명:** ZeroWaste  
- **팀명:** 청우(淸友)  
- **팀원:** 이다경(팀장), 유나경, 안치우, 이주안  
- **대회:** 2025 오픈소스 개발자대회  
- **프로젝트 유형:** 지정과제 (사회문제형 – 생활 – 모바일)  

---

## 🌍 프로젝트 소개
ZeroWaste는 주민들이 사진과 위치 정보를 기반으로 **불법 쓰레기 투기 현장 제보**를 하고, 이를 지도 기반으로 **실시간 시각화**하는 모바일 앱입니다.  

✅ **주요 목적**
- 주민 참여형 환경 감시 → 생활 속 무단투기 감소  
- 마일리지 보상 시스템 (예정) → 자발적 참여 유도  
- 지도 시각화 → 데이터 기반 정책 활용  

---

## 🛠 기술 스택
**프론트엔드:** Flutter (Dart)  
**백엔드:** Spring Boot (Java)  
**인증/보안:** Firebase Authentication, JWT  
**데이터베이스/클라우드:** Firebase Firestore, Firebase Storage  
**지도 서비스:** Kakao Maps API  
**기타:** Windows 개발 환경  

---

## ⚙️ 실행 전 준비사항

### 1. Firebase 설정
1. [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성  
2. **Firestore** 및 **Firebase Storage** 활성화  
3. **Firebase Authentication** → 로그인 방식에서 **Google** 사용 설정  
4. 서비스 계정 키(`serviceAccountKey.json`)를 발급받아 `backend/src/main/resources/` 폴더에 저장  

### 2. Kakao Map API 키 발급
1. [Kakao Developers](https://developers.kakao.com/) 접속  
2. 애플리케이션 생성 후 **JavaScript 키** & **REST 키** 발급  

---

## 🏗 시스템 아키텍처
```
[사용자 Flutter 앱]
   ⬇️ 사진/위치 제보
[Spring Boot 서버]
   ⬇️ JWT/OAuth 인증 및 처리
[Kakao Maps API]
   ⬅️ 위치 기반 지도 시각화
[Firebase Firestore/Storage]
   ⬆️ 데이터 저장 및 이미지 업로드
```

---

## ✨ 주요 기능
- **로그인 및 인증** → Firebase Auth + JWT 기반 보안  
- **쓰레기 제보** → GPS 기반 사진/위치 데이터 업로드  
- **지도 시각화** → Kakao Maps API로 핀 표시 및 반경 검색  
- **게시판 기능** → 환경 관련 커뮤니티 및 공지 확인  
- **보상 시스템 (예정)** → 제보 → 마일리지 적립 → 기프티콘 교환  

---

## 🚀 실행 방법

### 1. 앱 실행 (Flutter)
```bash
# Flutter SDK 설치 후 프로젝트 디렉터리에서 실행
flutter pub get
flutter run `
  --dart-define=KAKAO_JS_KEY=YOUR_KAKAO_JS_KEY `
  --dart-define=KAKAO_REST_KEY=YOUR_KAKAO_REST_KEY
```
> Android 기기 또는 에뮬레이터 필요  

### 2. 백엔드 실행 (Spring Boot)
```bash
# JDK 17 이상 필요
./gradlew bootRun
```
> `serviceAccountKey.json` 파일이 `src/main/resources/`에 존재해야 함  

---

## 📊 기대 효과
- 주민 참여형 환경 감시 → 깨끗한 도시 조성  
- 지도 기반 시각화 → 환경 문제 인식 제고  
- 데이터 기반 정책 활용 → 효율적인 단속 및 자원 관리  

---

## 🔮 향후 개선 방향
- 보상 시스템 고도화 (기프티콘/지역 화폐)  
- AI 기반 이미지 분석 (자동 분류 및 허위 제보 차단)  
- 관리자 대시보드 (통계/분석/필터 기능)  
- 타 민원 서비스(광고물, 도로 파손 등) 확장  

---

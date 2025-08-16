# 테스트 가이드

이 디렉토리는 IT Contest 앱의 핵심 기능들에 대한 포괄적인 테스트 스위트를 포함합니다.

## 📁 테스트 구조

```
test/
├── unit/                          # 유닛 테스트
│   ├── db/                        # 데이터베이스 관련 테스트
│   │   └── unique_constraints_test.dart   # 유니크 제약 조건 테스트
│   ├── backup/                    # 백업 시스템 테스트
│   │   └── backup_service_test.dart       # 백업/복원 기능 테스트
│   ├── link/                      # 링크 시스템 테스트
│   │   └── link_sync_test.dart            # 링크 동기화 테스트
│   ├── encryption/                # 암호화 시스템 테스트
│   │   └── crypto_key_service_test.dart   # 암호화 키 관리 테스트
│   └── move/                      # 이동 기능 테스트
│       └── move_service_test.dart         # 노트/폴더 이동 테스트
├── integration/                   # 통합 테스트
│   └── full_backup_restore_test.dart     # 전체 백업/복원 워크플로우 테스트
├── test_helper.dart               # 공통 테스트 유틸리티
├── widget_test.dart               # 위젯 테스트 (기본)
└── README.md                      # 이 파일
```

## 🧪 테스트 카테고리

### 1. 유니크 제약 조건 테스트 (`unit/db/unique_constraints_test.dart`)
- **Vault** `nameLowerUnique` 제약 (대소문자 무시 중복 방지)
- **Folder** `nameLowerForVaultUnique` 제약 (볼트 내 중복 방지)
- **Note** `nameLowerForParentUnique` 제약 (폴더 내 중복 방지)
- **GraphEdge** 복합 유니크 제약 `(vaultId, fromNoteId, toNoteId)`
- **PdfCacheMeta** 복합 유니크 제약 `(noteId, pageIndex)`
- **RecentTabs** `userId` 유니크 제약

### 2. 백업/복원 시스템 테스트 (`unit/backup/backup_service_test.dart`)
- 기본 데이터베이스 백업 생성/삭제
- 통합 백업 (DB + PDF 파일) 생성
- AES 암호화 백업 생성/복원
- 백업 목록 조회 및 상태 모니터링
- 백업 테스트 및 검증 기능
- 백업 복원 및 데이터 무결성 검증

### 3. 링크 동기화 테스트 (`unit/link/link_sync_test.dart`)
- 영역에서 링크된 노트 생성
- 링크와 그래프 엣지 동기화
- 좌표 정규화 및 유효성 검증
- 고유 라벨 생성 (중복 시 번호 추가)
- 소프트 삭제 시 dangling 링크 처리
- 복원 시 dangling 플래그 정리
- 그래프 엣지 중복 방지

### 4. 암호화 시스템 테스트 (`unit/encryption/crypto_key_service_test.dart`)
- 암호화 키 생성/로드/검증
- 키 회전 및 백업 관리
- 데이터베이스 재암호화
- IsarDb 암호화 토글 기능
- 명시적 암호화 키 사용

### 5. 통합 워크플로우 테스트 (`integration/full_backup_restore_test.dart`)
- 완전한 데이터 구조 생성 (볼트, 폴더, 노트, 페이지, 캔버스, 링크 등)
- 통합 백업 및 완전 복원
- 데이터 관계 무결성 검증
- 암호화 백업/복원 워크플로우
- PDF 파일 포함 백업/복원

## 🚀 테스트 실행 방법

### 모든 테스트 실행
```bash
flutter test
```

### 특정 카테고리 테스트 실행
```bash
# 유니크 제약 조건 테스트
flutter test test/unit/db/unique_constraints_test.dart

# 백업 시스템 테스트
flutter test test/unit/backup/backup_service_test.dart

# 링크 동기화 테스트
flutter test test/unit/link/link_sync_test.dart

# 암호화 시스템 테스트
flutter test test/unit/encryption/crypto_key_service_test.dart

# 통합 테스트
flutter test test/integration/full_backup_restore_test.dart
```

### 테스트 실행 옵션
```bash
# 자세한 출력으로 실행
flutter test --reporter=expanded

# 특정 테스트만 실행 (패턴 매칭)
flutter test --name="unique constraint"

# 커버리지 리포트 생성
flutter test --coverage
```

## ⚠️ 중요 사항

### 네이티브 런타임 요구사항
대부분의 테스트는 Isar 네이티브 런타임이 필요하므로 `skip` 플래그가 설정되어 있습니다. 실제 테스트를 실행하려면:

1. **데스크톱에서 실행:**
   ```bash
   flutter test --platform=chrome
   ```

2. **디바이스/에뮬레이터에서 실행:**
   ```bash
   flutter test test/integration/ --device-id=<device_id>
   ```

3. **통합 테스트로 실행:**
   ```bash
   flutter drive --target=test_driver/app.dart
   ```

### Mock 설정
모든 테스트는 다음을 자동으로 mock합니다:
- `path_provider` (임시 디렉토리 사용)
- `flutter_secure_storage` (메모리 기반 저장소)
- 파일 시스템 (격리된 임시 디렉토리)

### 테스트 데이터 정리
각 테스트 후에 자동으로:
- 임시 디렉토리 삭제
- Mock 핸들러 정리
- Isar 데이터베이스 연결 종료

## 📊 커버리지 목표

이 테스트 스위트는 다음 핵심 기능들의 높은 커버리지를 목표로 합니다:

- ✅ **데이터 무결성**: 유니크 제약 조건 및 관계 검증
- ✅ **백업/복원**: 데이터 손실 방지 및 완전한 복구
- ✅ **링크 시스템**: 노트 간 연결 및 그래프 동기화
- ✅ **암호화**: 민감한 데이터 보호 및 키 관리
- ✅ **워크플로우**: 실제 사용 시나리오 통합 테스트

## 🐛 문제 해결

### 일반적인 문제들

1. **Isar 런타임 오류**
   - 네이티브 플랫폼에서 실행되어야 함
   - `isar_flutter_libs` 패키지 확인

2. **권한 오류**
   - 테스트용 임시 디렉토리 생성 권한 확인
   - 플랫폼별 권한 설정 확인

3. **메모리 누수**
   - 각 테스트 후 `tearDown`에서 정리 확인
   - 데이터베이스 연결 종료 확인

### 디버깅 팁

```bash
# 자세한 로그와 함께 실행
flutter test --verbose

# 특정 테스트만 디버그
flutter test --name="specific test name" --verbose

# 실패한 테스트만 재실행
flutter test --run-skipped
```

## 🤝 기여 가이드

새로운 기능 추가 시 테스트 작성 권장사항:

1. **유닛 테스트**: 개별 함수/메서드 테스트
2. **통합 테스트**: 여러 컴포넌트 상호작용 테스트
3. **엣지 케이스**: 예외 상황 및 경계값 테스트
4. **성능 테스트**: 대용량 데이터 처리 검증

테스트 작성 시 `test_helper.dart`의 공통 유틸리티를 활용하여 일관된 테스트 환경을 구성하세요.

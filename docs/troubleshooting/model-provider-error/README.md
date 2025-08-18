# 모델 공급자 연결 오류 트러블슈팅 가이드

이 저장소는 기본 개발/CI 흐름에서 LLM/AI를 사용하지 않습니다. 그럼에도 불구하고 IDE 플러그인이나 외부 훅/파이프라인으로 인해 "We're having trouble connecting to the model provider …" 오류가 발생할 수 있습니다. 아래 체크리스트를 따라 원인을 추적·격리하고, 기본 흐름이 AI 없이도 성공하도록 보장하세요.

## 1) 오류 재현 컨텍스트 고정

- 언제/어디서 뜨는지 재현하고 로그를 확보하세요.
- 어떤 커맨드/툴에서 발생했는지 기록: IDE(예: Cursor, Copilot Chat, Codeium), 프리커밋 훅, CI, 로컬 스크립트 등.
- 가능하면 콘솔 로그/스크린샷을 이 디렉터리에 저장하세요.
  - 예: `docs/troubleshooting/model-provider-error/repro_YYYYMMDD.log`

## 2) 레포 외부 연동 지점 점검

이 저장소에는 기본적으로 LLM 호출 코드/의존성이 없습니다. 다만 외부 설정에 의해 실행될 수 있으므로 아래 지점을 점검하세요.

- CI: `.github/workflows/**`, `.circleci/config.yml`, `.gitlab-ci.yml`, `azure-pipelines.yml`
  - 키워드: `openai`, `anthropic`, `gemini`, `cohere`, `huggingface`, `llm`, `model`, `chat`, `REQUEST_ID`
- Git 훅/프리커밋: `.git/hooks/*`, `.husky/*`, `.pre-commit-config.yaml`
- 개발 스크립트/자동화: `package.json (scripts)`, `Makefile`, `scripts/*`, `tools/*`, `Taskfile.yml`, `justfile`
- 에디터 설정: `.vscode/*`, `.idea/*`, `.devcontainer/devcontainer.json`

권장 검색 명령어:

```bash
rg -n "(openai|anthropic|gemini|cohere|huggingface|llm|model|chat|REQUEST_ID)" -S
rg -n "(pre-commit|husky|commit-msg|prepare-commit-msg)"
```

## 3) 원인 격리 및 가드 추가

- CI에서 발견 시: 해당 스텝을 시크릿 존재 여부로 가드하고, 기본은 건너뛰도록 처리하세요.

```yaml
# .github/workflows/ci.yml 예시
- name: AI 보조 리뷰 (선택)
  if: ${{ env.ENABLE_AI_REVIEW == 'true' && secrets.OPENAI_API_KEY != '' }}
  run: ./scripts/ai_review.sh
```

- Git 훅에서 발견 시: 훅 최상단에 환경 가드 추가(기본 차단).

```bash
# .husky/prepare-commit-msg 예시
if [ -z "$ENABLE_AI_HOOKS" ] || [ -z "$OPENAI_API_KEY" ]; then
  echo "[skip] AI 훅 비활성화"; exit 0
fi
```

본 저장소에는 현재 해당 훅/워크플로가 존재하지 않지만, 향후 추가될 경우 위 가드를 적용해 **기본 비활성 + 명시적 opt-in** 을 유지하세요.

## 4) 기본 개발 루틴 확인 (오프라인 가정)

다음 명령이 네트워크 의존 없이 성공해야 합니다.

```bash
flutter pub get
flutter analyze
flutter test
```

외부 서비스 호출을 유발하는 스크립트/훅/워크플로가 연결되어 있지 않은지 다시 점검하세요.

## 5) IDE/플러그인 가이드 (권장: 기본 비활성)

개발자 개인 환경에서만 LLM 플러그인을 opt-in 하세요. 저장소에는 아래 예시 변수로 의도를 문서화합니다.

```env
# .env.example 발췌
ENABLE_AI_REVIEW=false
ENABLE_AI_HOOKS=false
```

자세한 IDE 설정 권고는 `docs/troubleshooting/ide-ai.md`를 참고하세요.

---

## 결론

- 이 저장소는 LLM/AI 의존 없이도 개발/테스트/CI가 성공하도록 설계되었습니다.
- 외부 도구에서 유입된 LLM 호출은 기본 비활성 원칙과 환경 가드로 차단하세요.



# 앱 설치 경로 추적 가이드

## 빠른 참조

**기본 링크**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share
```

**마케팅 파라미터 추가 예시** (인스타그램):

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Dlaunch_event
```

**지원 파라미터**:

- UTM: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`
- 커스텀: `source`, `medium`, `campaign`, `content`

**Firebase Analytics 자동 기록**:

- User Properties: `install_source`, `install_medium`, `install_campaign`
- Event: `install_attribution`

---

## 개요

Google Play Store의 Install Referrer API를 통해 앱 설치 경로를 추적하고, Firebase Analytics에 기록하는 시스템입니다.

---

## 파라미터 종류

### 1. UTM 파라미터 (표준 마케팅 파라미터)

UTM(Urchin Tracking Module)은 웹/앱 마케팅에서 표준으로 사용하는 파라미터입니다.

#### `utm_source` (필수)

- **의미**: 설치가 발생한 출처/채널
- **예시**:
  - `instagram` - 인스타그램
  - `naver_blog` - 네이버 블로그
  - 'everytime' - 에브리타임
  - `google_search` - 구글 검색
  - `youtube` - 유튜브
  - `partner_app` - 제휴 앱

#### `utm_medium` (권장)

- **의미**: 마케팅 매체/방식
- **예시**:
  - `social` - 소셜 미디어
  - `email` - 이메일
  - `community` - 커뮤니티
  - `banner` - 배너 광고
  - `video` - 동영상
  - `organic` - 자연 유입

#### `utm_campaign` (권장)

- **의미**: 특정 캠페인/이벤트 이름
- **예시**:
  - `launch_event` - 런칭 이벤트
  - `q1_2025` - 2025년 1분기 캠페인
  - `summer_sale` - 여름 세일
  - `influencer_collab` - 인플루언서 협업

#### `utm_content` (선택)

- **의미**: 동일한 캠페인 내에서 구체적인 콘텐츠 구분
- **예시**:
  - `banner_top` - 상단 배너
  - `banner_bottom` - 하단 배너
  - `video_intro` - 인트로 영상
  - `post_promotion` - 프로모션 포스트

### 2. 커스텀 파라미터 (대체 파라미터)

UTM 파라미터를 사용하지 않을 때 사용할 수 있는 대체 파라미터입니다.

#### `source`

- **의미**: `utm_source`와 동일 (출처)
- **사용 시점**: UTM을 사용하지 않을 때

#### `medium`

- **의미**: `utm_medium`과 동일 (매체)
- **사용 시점**: UTM을 사용하지 않을 때

#### `campaign`

- **의미**: `utm_campaign`과 동일 (캠페인)
- **사용 시점**: UTM을 사용하지 않을 때

#### `content`

- **의미**: `utm_content`와 동일 (콘텐츠)
- **사용 시점**: UTM을 사용하지 않을 때

---

## Firebase Analytics 프로퍼티

코드에서 자동으로 Firebase Analytics에 설정되는 User Properties입니다.

### `install_source`

- **의미**: 설치 출처
- **값**: `utm_source` 또는 `source` 파라미터 값
- **용도**: 사용자 세그먼트 분석, 채널별 성과 비교
- **예시**: `instagram`, `naver_blog`, `google_search`

### `install_medium`

- **의미**: 설치 매체
- **값**: `utm_medium` 또는 `medium` 파라미터 값
- **용도**: 매체별 효과 분석
- **예시**: `social`, `email`, `banner`

### `install_campaign`

- **의미**: 설치 캠페인
- **값**: `utm_campaign` 또는 `campaign` 파라미터 값
- **용도**: 캠페인별 성과 추적
- **예시**: `launch_event`, `q1_2025`, `summer_sale`

---

## 파라미터 우선순위

코드에서 파라미터를 읽을 때의 우선순위:

```dart
// InstallAttributionPayload 클래스에서
String? get source => parameters['utm_source'] ?? parameters['source'];
String? get medium => parameters['utm_medium'] ?? parameters['medium'];
String? get campaign => parameters['utm_campaign'] ?? parameters['campaign'];
String? get content => parameters['utm_content'] ?? parameters['content'];
```

**규칙**: UTM 파라미터가 있으면 우선 사용, 없으면 커스텀 파라미터 사용

---

## 기본 링크

**실제 Google Play Store 링크**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share
```

이 링크에 `referrer` 파라미터를 추가하여 마케팅 추적을 할 수 있습니다.

---

## 사용 예시

### 예시 1: UTM 파라미터 사용 (권장)

**기본 링크에 `referrer` 파라미터 추가**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Dlaunch_event
```

**파라미터**:

- `utm_source=instagram`
- `utm_medium=social`
- `utm_campaign=launch_event`

**Firebase Analytics에 기록되는 값**:

- User Property `install_source`: `instagram`
- User Property `install_medium`: `social`
- User Property `install_campaign`: `launch_event`
- Event `install_attribution`의 파라미터: 모든 UTM 파라미터 포함

### 예시 2: 커스텀 파라미터 사용

**기본 링크에 `referrer` 파라미터 추가**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=source%3Dpartner_app%26campaign%3Dq1_2025
```

**파라미터**:

- `source=partner_app`
- `campaign=q1_2025`

**Firebase Analytics에 기록되는 값**:

- User Property `install_source`: `partner_app`
- User Property `install_campaign`: `q1_2025`
- User Property `install_medium`: 설정되지 않음 (없음)
- Event `install_attribution`의 파라미터: `source`, `campaign` 포함

### 예시 3: UTM과 커스텀 혼합 (UTM 우선)

**기본 링크에 `referrer` 파라미터 추가**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dnaver_blog%26source%3Dfallback%26utm_campaign%3Dlaunch_event
```

**파라미터**:

- `utm_source=naver_blog`
- `source=fallback` (무시됨)
- `utm_campaign=launch_event`

**Firebase Analytics에 기록되는 값**:

- User Property `install_source`: `naver_blog` (UTM 우선)
- User Property `install_campaign`: `launch_event`

---

## Clustudy 실제 마케팅 채널별 설정 가이드

### 케이스 1: 네이버 블로그 공식 블로그 (직접 글 작성)

**권장 파라미터**:

- `utm_source=naver_blog` - 네이버 블로그 출처 명시
- `utm_medium=blog` - 블로그 매체
- `utm_campaign={포스트_제목_또는_시기}` - 특정 포스트나 시기 구분
- `utm_content={포스트_날짜_또는_주제}` (선택) - 같은 캠페인 내에서 구체적 구분

**예시 1: 런칭 포스트**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dnaver_blog%26utm_medium%3Dblog%26utm_campaign%3Dlaunch_post
```

**예시 2: 기능 소개 포스트 (날짜별 구분)**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dnaver_blog%26utm_medium%3Dblog%26utm_campaign%3Dfeature_intro%26utm_content%3D251107
```

**Firebase Analytics 분석**:

- `install_source`: `naver_blog`로 네이버 블로그에서 온 설치 추적
- `install_medium`: `blog`로 블로그 매체 효과 측정
- `install_campaign`: 포스트별 성과 비교 가능

---

### 케이스 2: 에브리타임 대학교 커뮤니티 (홍보글 작성)

**권장 파라미터**:

- `utm_source=everytime` - 에브리타임 출처 명시
- `utm_medium=community` - 커뮤니티 매체
- `utm_campaign={대학교명_또는_이벤트명}` - 대학교별 또는 이벤트별 구분
- `utm_content={게시판_또는_날짜}` (선택) - 게시판별 구분

**예시 1: 숭실대학교 홍보**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Deverytime%26utm_medium%3Dcommunity%26utm_campaign%3Dsoongsil_promotion
```

**예시 2: 연세대학교 + 특정 게시판**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Deverytime%26utm_medium%3Dcommunity%26utm_campaign%3Dyonsei_promotion%26utm_content%3Dfree_board
```

**Firebase Analytics 분석**:

- `install_source`: `everytime`로 에브리타임에서 온 설치 추적
- `install_medium`: `community`로 커뮤니티 매체 효과 측정
- `install_campaign`: 대학교별 또는 이벤트별 성과 비교 가능

---

### 케이스 3: 인스타그램 공식 계정 (직접 글 작성)

**권장 파라미터**:

- `utm_source=instagram` - 인스타그램 출처 명시
- `utm_medium=social` - 소셜 미디어 매체
- `utm_campaign={포스트_주제_또는_시기}` - 포스트 주제나 시기 구분
- `utm_content={포스트_타입}` (선택) - 피드/스토리/릴스 등 구분

**예시 1: 기능 소개 포스트**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Dfeature_intro
```

**예시 2: 릴스 콘텐츠**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Dq1_2025%26utm_content%3Dreels
```

**예시 3: 스토리**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Ddaily_update%26utm_content%3Dstory
```

**Firebase Analytics 분석**:

- `install_source`: `instagram`로 인스타그램에서 온 설치 추적
- `install_medium`: `social`로 소셜 미디어 매체 효과 측정
- `install_campaign`: 포스트 주제별 성과 비교 가능
- `utm_content`: 포스트 타입별(피드/스토리/릴스) 효과 비교 가능

---

## 일반적인 사용 시나리오 (참고)

### 시나리오 1: 네이버 블로그 배너 광고

**파라미터**:

- `utm_source=naver_blog`
- `utm_medium=banner`
- `utm_campaign=summer_sale`
- `utm_content=banner_top`

**완성된 링크**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dnaver_blog%26utm_medium%3Dbanner%26utm_campaign%3Dsummer_sale%26utm_content%3Dbanner_top
```

### 시나리오 2: 유튜브 동영상 설명란

**파라미터**:

- `utm_source=youtube`
- `utm_medium=video`
- `utm_campaign=tutorial_series`
- `utm_content=episode_1`

**완성된 링크**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dyoutube%26utm_medium%3Dvideo%26utm_campaign%3Dtutorial_series%26utm_content%3Depisode_1
```

### 시나리오 3: 제휴 앱 (UTM 없이)

**파라미터**:

- `source=partner_app`
- `campaign=q1_partnership`

**완성된 링크**:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=source%3Dpartner_app%26campaign%3Dq1_partnership
```

---

## Firebase Analytics에서 확인 방법

### Events 탭

- 이벤트명: `install_attribution`
- 파라미터: 모든 UTM/커스텀 파라미터가 포함됨

### User Properties 탭

- `install_source`: 설치 출처
- `install_medium`: 설치 매체
- `install_campaign`: 설치 캠페인

### 활용 방법

1. **채널별 설치 수**: `install_source`로 그룹화
2. **매체별 효과**: `install_medium`으로 분석
3. **캠페인 성과**: `install_campaign`으로 추적
4. **세그먼트 분석**: User Properties를 조합하여 사용자 세그먼트 생성

---

## 링크 생성 팁

### URL 인코딩 방법

`referrer` 파라미터 값은 반드시 URL 인코딩해야 합니다.

**인코딩 전**:

```
utm_source=instagram&utm_medium=social&utm_campaign=launch_event
```

**인코딩 후**:

```
utm_source%3Dinstagram%26utm_medium%3Dsocial%26utm_campaign%3Dlaunch_event
```

**인코딩 규칙**:

- `=` → `%3D`
- `&` → `%26`
- 공백 → `%20` (필요한 경우)

### 온라인 도구 활용

- [URL Encoder/Decoder](https://www.urlencoder.org/)
- [Google URL Builder](https://ga-dev-tools.google/campaign-url-builder/) (UTM 파라미터 전용)

### 링크 구조

기본 구조:

```
https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer={인코딩된_파라미터}
```

---

## 주의사항

1. **URL 인코딩 필수**: `referrer` 파라미터 값은 반드시 URL 인코딩해야 함
2. **앱 재설치 필요**: 테스트 시 앱을 완전히 삭제 후 재설치해야 함
3. **첫 실행 시에만**: Install Referrer는 앱 설치 후 첫 실행 시에만 사용 가능
4. **UTM 우선**: UTM과 커스텀 파라미터가 동시에 있으면 UTM이 우선됨
5. **기존 파라미터 유지**: `pcampaignid=web_share` 같은 기존 파라미터는 그대로 유지하고 `referrer`만 추가

---

## 요약

| 항목          | UTM 파라미터               | 커스텀 파라미터    | Firebase User Property             |
| ------------- | -------------------------- | ------------------ | ---------------------------------- |
| **의미**      | 표준 마케팅 파라미터       | UTM 대체 파라미터  | 사용자 속성 (영구 저장)            |
| **예시**      | `utm_source`, `utm_medium` | `source`, `medium` | `install_source`, `install_medium` |
| **용도**      | 마케팅 추적 표준           | 간단한 추적        | 사용자 세그먼트 분석               |
| **우선순위**  | 높음                       | 낮음               | -                                  |
| **저장 위치** | Event 파라미터             | Event 파라미터     | User Property                      |

**권장**: UTM 파라미터 사용을 권장합니다. 표준이므로 다른 도구와의 호환성이 좋고, 마케팅 분석이 용이합니다.

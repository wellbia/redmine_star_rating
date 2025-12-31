# Redmine Star Rating Plugin

이슈 원문과 코멘트(Journal)에 1~5 별점을 부여할 수 있는 Redmine 플러그인입니다.

## 기능

- 이슈 본문(Description)에 별점 UI 표시
- 각 코멘트(Journal)에 별점 UI 표시
- 원클릭 AJAX 평점 저장
- 사용자당 대상별 1개의 평점만 허용 (재클릭 시 점수 변경)
- 평균 점수(avg)와 평가 수(count) 표시
- 로그인 사용자만 평가 가능
- 자기 글 평가 금지 (설정으로 변경 가능)
- 폴리모픽 구조로 향후 Wiki/News/Forum 등 확장 가능

## 요구사항

- Redmine 5.0.0 이상 (Redmine 5.x, 6.x 지원)
- Ruby 2.7 이상
- Rails 6.1 이상

## 설치 방법

### 1. 플러그인 복사

```bash
cd /path/to/redmine/plugins
git clone https://github.com/your-repo/redmine_star_rating.git
```

또는 플러그인 폴더를 직접 복사:

```bash
cp -r redmine_star_rating /path/to/redmine/plugins/
```

### 2. 마이그레이션 실행

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### 3. Redmine 재시작

```bash
# Apache + Passenger 사용 시
touch /path/to/redmine/tmp/restart.txt

# 또는 서비스 재시작
sudo systemctl restart redmine
```

## 권한 설정 방법

1. **관리 > 역할 및 권한** 메뉴로 이동
2. 원하는 역할(예: Manager, Developer)에서 **"Rate issues and comments"** 권한 체크
3. 저장

## 플러그인 설정

**관리 > 플러그인 > Redmine Star Rating > 설정**에서 다음 옵션을 설정할 수 있습니다:

| 설정 | 기본값 | 설명 |
|------|--------|------|
| Enable issue rating | true | 이슈 본문 평점 활성화 |
| Enable journal rating | true | 코멘트 평점 활성화 |
| Allow self rating | false | 자기 글 평가 허용 여부 |

## API 사용법

### 평점 등록/수정

```bash
POST /rateable_ratings
Content-Type: application/json
X-CSRF-Token: <csrf_token>

{
  "rateable_type": "Issue",
  "rateable_id": 123,
  "score": 5
}
```

### 응답

```json
{
  "avg": 4.3,
  "count": 21,
  "my_score": 5
}
```

### 상태 코드

| 코드 | 설명 |
|------|------|
| 200 | 성공 |
| 400 | 입력 오류 (잘못된 rateable_type 또는 score) |
| 401 | 미로그인 |
| 403 | 권한 없음 / 자기평가 금지 |
| 404 | 대상 없음 |

## Redmine 6.1 내장 Reactions와의 차이

Redmine 6.1부터는 내장 Reactions 기능이 추가되었습니다. 이 플러그인과의 차이점은 다음과 같습니다:

| 항목 | Star Rating Plugin | Redmine Reactions |
|------|-------------------|-------------------|
| 평가 방식 | 1~5점 숫자 점수 | 이모지 반응 |
| 평균 계산 | 평균 점수 표시 | 반응 개수만 표시 |
| 정량적 평가 | 가능 | 불가능 |
| 통계/보고서 | 평균 기반 분석 가능 | 제한적 |
| 용도 | 품질 평가, 만족도 조사 | 감정 표현, 빠른 피드백 |

**Star Rating Plugin은** 코드 리뷰 품질 평가, 답변 만족도 측정, 정량적 통계 분석이 필요한 경우에 적합합니다.

## 제거 방법

```bash
cd /path/to/redmine

# 마이그레이션 롤백
bundle exec rake redmine:plugins:migrate NAME=redmine_star_rating VERSION=0 RAILS_ENV=production

# 플러그인 폴더 삭제
rm -rf plugins/redmine_star_rating

# Redmine 재시작
touch tmp/restart.txt
```

## 수동 테스트 체크리스트

### 기본 기능

- [ ] 로그인하지 않은 사용자: 별점 UI가 읽기 전용으로 표시
- [ ] 로그인한 사용자: 별점 클릭 가능
- [ ] 권한 없는 사용자: 별점 클릭 불가 (403 에러)
- [ ] 이슈 본문에 별점 UI 표시됨
- [ ] 각 코멘트에 별점 UI 표시됨

### 평점 기능

- [ ] 별 클릭 시 즉시 평점 저장됨 (AJAX)
- [ ] 저장 후 평균과 평가 수가 즉시 갱신됨
- [ ] 동일 대상에 재클릭 시 점수가 변경됨
- [ ] 다른 사용자의 평점도 평균에 반영됨

### 설정 기능

- [ ] 이슈 평점 비활성화 시 이슈에 UI 미표시
- [ ] 코멘트 평점 비활성화 시 코멘트에 UI 미표시
- [ ] 자기평가 금지 설정 시 본인 글 평가 불가
- [ ] 자기평가 허용 시 본인 글 평가 가능

### 예외 처리

- [ ] 존재하지 않는 대상 평가 시 404 에러
- [ ] 잘못된 점수(0, 6 등) 입력 시 400 에러
- [ ] 네트워크 오류 시 에러 메시지 표시

## 파일 구조

```
redmine_star_rating/
├── init.rb
├── README.md
├── app/
│   ├── controllers/
│   │   └── rateable_ratings_controller.rb
│   ├── models/
│   │   └── rateable_rating.rb
│   └── views/
│       ├── rateable_ratings/
│       │   ├── _stars.html.erb
│       │   ├── _stars_issue.html.erb
│       │   └── _stars_journal.html.erb
│       └── settings/
│           └── _star_rating_settings.html.erb
├── assets/
│   ├── javascripts/
│   │   └── rateable_ratings.js
│   └── stylesheets/
│       └── rateable_ratings.css
├── config/
│   ├── locales/
│   │   ├── en.yml
│   │   └── ko.yml
│   └── routes.rb
├── db/
│   └── migrate/
│       └── 001_create_rateable_ratings.rb
└── lib/
    └── redmine_star_rating/
        └── hooks.rb
```

## 라이선스

MIT License

## 기여

이슈와 Pull Request를 환영합니다!

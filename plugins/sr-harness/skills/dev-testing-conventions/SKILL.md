---
name: dev-testing-conventions
description: "테스트 코드 작성 컨벤션 체크리스트. execute 중 테스트를 새로 만들거나 구조를 바꿀 때 참조. 티어 구분(접미사), 단언 라이브러리, 파라미터화, 라이브 테스트 분리 네 섹션으로 구성. 프로젝트 CLAUDE.md에 선언하여 활성화. Keywords: 테스트 컨벤션, 테스트 작성, 접미사, IntegrationTest, AssertJ, assertThat, ParameterizedTest, MethodSource, 파라미터화, 라이브 테스트, live test, test naming, test tier"
---

# dev-testing-conventions

테스트를 새로 만들거나 구조를 바꾸기 전, 각 섹션의 원칙을 확인하고 구현에 반영한다.

테스트 관련 스킬은 셋으로 갈린다. `dev-coding-principles §3 Test`가 **"무엇을 테스트할 것인가"**(단위냐 통합이냐)를, `dev-testing-strategy`가 **"통합이라면 컨텍스트를 어떻게 띄우나"**를 가른다면, 이 스킬은 **"그래서 테스트 코드를 어떤 형태로 쓰나"**를 다룬다.

> **활성화 방법**: 프로젝트 `CLAUDE.md`에 아래 한 줄을 추가한다.
> ```
> 테스트를 새로 만들거나 구조를 바꿀 때 `dev-testing-conventions` 스킬을 로드하고 컨벤션을 적용한다.
> ```

## §1 티어 구분: 서브패키지가 아니라 클래스명 접미사로

**목표**: 파일을 열어 애노테이션을 확인하기 전에 그 테스트의 성격을 알 수 있다.

- **flat 패키지가 기본값**: 프로덕션 코드와 같은 패키지 구조를 그대로 쓰고, `unit`/`integration` 물리적 서브패키지로 나누지 않는다. 성격은 클래스명 접미사가 지고, 같은 패키지 안에 세 티어가 공존한다.
- **접미사가 티어를 결정한다**: 마지막 토큰만 본다.

| 접미사 | 티어 | 판별 기준 |
|---|---|---|
| `XxxTest` | unit | 프레임워크 컨텍스트를 띄우지 않는다. 직접 생성, 스텁 서버, mock만 써도 unit이다 |
| `XxxIntegrationTest` | integration | 컨텍스트를 띄워 실제 빈을 배선한다 (무엇으로 띄울지는 `dev-testing-strategy` §1) |
| `XxxLiveTest` | live | 실제 외부 시스템을 호출한다. CI에서 제외된다 (§4) |

- **목적별 변형은 허용한다**: `XxxRetryTest`처럼 중간에 목적을 넣어도 마지막 토큰이 티어를 결정하므로 컨벤션과 어긋나지 않는다.
- **★ 접미사가 실제 동작과 어긋나면 즉시 고친다**: `Test`인데 컨텍스트를 띄우고 있으면 `IntegrationTest`로 리네임한다. 어긋난 이름을 방치하면 **파일을 열기 전까지 티어를 알 수 없는 상태**가 남고, 그 상태에서는 "이 테스트가 왜 느린가"를 이름으로 판단할 수 없다.
- **예외를 만들 때는 그것이 예외임을 명시한다**: 특정 패키지만 서브패키지로 나누는 선택을 했다면, 그 결정을 기록하고 새 도메인에 기본값으로 전파하지 않는다.

## §2 단언 라이브러리: 하나로 통일한다

**목표**: 실패 메시지의 정보량을 프로젝트 전체에서 균일하게 유지한다.

- **AssertJ의 `assertThat`으로 통일한다.** `import static org.assertj.core.api.Assertions.assertThat;`을 정적 임포트해 체이닝만 쓴다.
- **JUnit Jupiter의 `Assertions`(`assertEquals`/`assertTrue`/`assertFalse`), JUnit4의 `org.junit.Assert`, Hamcrest를 섞지 않는다.** 실패 메시지가 `expected: X but was: Y` 수준으로 빈약하고, 여러 속성을 한 번에 검증하는 체이닝이 없다.
- **예외 검증은 `assertThatThrownBy` 또는 `assertThatExceptionOfType`을 쓴다.** JUnit의 `assertThrows` 대신.
- 단언을 얼마나 구체적으로 쓸 것인가는 `dev-coding-principles §3`이 다룬다. 이 섹션은 **어떤 라이브러리로 쓸 것인가**만 정한다.

## §3 파라미터화: 반복되는 검증은 이름으로 드러나게

**목표**: 실패했을 때 스택트레이스에서 몇 번째 단언인지 세지 않는다.

한 테스트 메서드 안에 "하나의 속성 → 하나의 기대값"을 확인하는 단언이 여러 줄 나열돼 있으면 `@ParameterizedTest` + `@MethodSource`로 뽑는다. 테스트 리포트에 **어떤 속성이 깨졌는지 이름으로** 드러나야 한다.

### 값 튜플이 아니라 `Executable` 람다로 넘긴다

```java
@ParameterizedTest(name = "{0}")
@MethodSource("expectations")
void 프로파일별_설정값이_기대대로_바인딩된다(String property, Executable assertion) throws Throwable {
    assertion.execute();
}

private Stream<Arguments> expectations() {
    return Stream.of(
            Arguments.of("feature.mode", (Executable) () -> assertThat(props.getMode()).isEqualTo("dev")),
            Arguments.of("alert.enabled", (Executable) () -> assertThat(alertProps.isEnabled()).isFalse()));
}
```

**`(Object actual, Object expected)` 형태의 제네릭 튜플은 쓰지 않는다.** `String`, `int`, `boolean`이 섞인 필드를 억지로 `Object`로 받으면 컴파일 타임 타입 체크를 잃는다. `int`를 `String`과 짝지어도 컴파일이 통과하고 런타임에야 실패로 드러난다. `Executable` 람다는 각 행이 자기 타입 그대로 단언을 호출하므로 이 문제가 없다.

**주의**: `@MethodSource` 팩토리가 주입받은 인스턴스 필드를 참조해야 하면 클래스에 `@TestInstance(TestInstance.Lifecycle.PER_CLASS)`를 붙인다. 기본값인 정적 메서드로는 인스턴스 필드에 접근할 수 없다.

### 소스 애노테이션 선택

- 단일 컬럼 리터럴 목록이면 `@ValueSource`.
- 값을 코드로 조합하거나 외부(환경변수, git 밖 파일)에서 읽어야 하면 `@MethodSource`.
- **`@CsvFileSource`보다 `@MethodSource`를 우선한다.** 지정한 파일이 없을 때 `@CsvFileSource`는 스킵이 아니라 `PreconditionViolationException`(테스트 실패)을 던진다. 로컬 전용 파일에 의존하는 테스트라면 새 체크아웃에서 곧바로 빨간불이 된다.

### 클래스 구조를 파라미터화로 합치지 않는다

환경이나 프로파일 하나당 클래스 하나인 구조는 그대로 둔다. "행이 여러 개 필요하니 환경을 합쳐 파라미터화하자"로 가지 않는다. 위 패턴이면 한 환경 안의 속성만으로도 이미 행이 여럿 나온다. 비교 대상 자체가 파라미터마다 달라져야 하는 경우(예: 두 환경이 특정 값에서 대칭인지 확인)에 한해 그 테스트 메서드 안에서만 구성을 바꾼다. `dev-testing-strategy` §1의 신호 1과 같은 선상이다.

## §4 라이브 테스트: CI에서 구조적으로 분리한다

**목표**: 실제 외부 시스템을 호출하는 테스트가 CI에 섞이지 않으면서도, 필요할 때 사람이 돌릴 수 있다.

- **태그와 별도 태스크로 분리한다.** 라이브 테스트에 `@Tag("live")`를 붙이고, 기본 test 태스크는 그 태그를 제외하며, 전용 태스크를 따로 정의한다. 이름 규칙(§1의 `XxxLiveTest`)에만 기대지 않는다. **CI 제외는 빌드 설정이 강제해야 한다.**
- **전체 컨텍스트를 띄우지 않는다.** 순수 아웃바운드 호출 테스트에 DB나 컨테이너 의존을 얹지 않는다. 대상 어댑터와 필요한 설정 빈만 최소로 조립한다.
- **시크릿은 git 밖에서 받는다.** `.gitignore`에 등록된 로컬 설정 파일을 우선 읽고 환경변수로 폴백하는 통로를 하나 만들어 재사용한다. 테스트 리소스에 커밋하는 데이터 파일에 시크릿을 넣지 않는다.
- **★ 값이 없으면 실패가 아니라 스킵이어야 한다.** 시크릿이나 대상 식별자가 없는 환경(새 체크아웃 등)에서 라이브 테스트는 "돌릴 수 없음"이지 "실패"가 아니다. 값이 없을 때 마커 하나를 흘려보내고 `Assumptions.assumeTrue(...)`가 사유를 남기며 스킵하게 만든다.
- **환경 의존값을 받겠다고 운영 프로파일을 통째로 로드하지 않는다.** 프로파일에는 그 값 말고도 외부 발송 플래그 같은 것이 함께 딸려온다. 필요한 값 하나만 시크릿과 같은 통로로 받는다.
- **부작용 없는 조회 대상 식별자는 코드에 직접 둔다.** 실행할 때마다 바뀌지 않고 조회 전용이라면 클래스 상수로 나열한다. 시크릿과 달리 파일이나 환경변수로 감쌀 이유가 없다.

## 체크리스트 (테스트 작성 전)

```
§1 티어 구분
[ ] 클래스명 접미사가 실제 동작과 일치하는가? (컨텍스트를 띄우면 IntegrationTest)
[ ] 서브패키지로 나누지 않고 flat + 접미사를 유지했는가?

§2 단언 라이브러리
[ ] AssertJ assertThat으로 통일했는가? (JUnit Assertions와 Hamcrest 혼용 금지)
[ ] 예외 검증에 assertThatThrownBy / assertThatExceptionOfType을 썼는가?

§3 파라미터화
[ ] 같은 형태의 단언이 여러 줄 반복되면 @ParameterizedTest로 뽑았는가?
[ ] 값 튜플 대신 Executable 람다로 넘겨 타입 체크를 유지했는가?
[ ] 인스턴스 필드를 참조한다면 @TestInstance(PER_CLASS)를 붙였는가?

§4 라이브 테스트
[ ] @Tag와 빌드 설정으로 CI에서 제외했는가? (이름 규칙만으로 분리하지 않았는가)
[ ] 시크릿을 git 밖에서 받는가?
[ ] 값이 없을 때 실패가 아니라 스킵으로 남는가?
```

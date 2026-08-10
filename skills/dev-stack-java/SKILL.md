---
name: dev-stack-java
description: "Java/Spring Boot 관용구 체크리스트. Java 프로젝트의 execute 시 참조. Spring Boot·JPA·예외처리 패턴 세 섹션으로 구성. 프로젝트 CLAUDE.md에 선언하여 활성화. Keywords: Java, Spring Boot, JPA, 스프링, 관용구, spring idioms, dependency injection, transaction, exception handler"
---

# dev-stack-java

Java/Spring Boot 프로젝트에서 코드를 작성하기 전, 각 섹션의 관용구를 확인하고 구현에 반영한다.

> **활성화 방법**: 프로젝트 `CLAUDE.md`에 아래 한 줄을 추가한다.
> ```
> execute 실행 시 `dev-stack-java` 스킬을 로드하고 Java/Spring Boot 관용구를 구현에 적용한다.
> ```

## §1 Spring Boot Idioms

**목표**: 프레임워크 기능을 올바르게 사용하고 숨겨진 부작용을 방지한다.

- **Constructor injection 필수**: 필드 주입(`@Autowired` 필드) 금지 — 테스트 불가, 순환 의존 감지 불가
  ```java
  // ✅
  private final OrderRepository orderRepository;
  public OrderService(OrderRepository orderRepository) {
      this.orderRepository = orderRepository;
  }
  // ❌
  @Autowired
  private OrderRepository orderRepository;
  ```
- **`@Transactional(readOnly = true)` 기본**: 조회 서비스는 readOnly 기본 적용, 쓰기 메서드에만 `@Transactional` 명시
  ```java
  @Transactional(readOnly = true)  // 클래스 레벨
  public class OrderQueryService {
      @Transactional  // 쓰기 메서드만 override
      public void cancel(Long orderId) { ... }
  }
  ```
- **`@ConfigurationProperties` 우선**: 설정값이 2개 이상이면 `@Value` 대신 `@ConfigurationProperties` 클래스로 묶기
- **스테레오타입 구분**:
  - `@Service` — 비즈니스 로직 (UseCase 구현체)
  - `@Repository` — 데이터 접근 (Adapter 구현체)
  - `@Component` — 위 두 범주에 속하지 않는 빈
- **프로퍼티 검증**: `@ConfigurationProperties` + `@Validated` + `@NotNull` 조합으로 시작 시점에 실패
- **프레임워크 클래스를 다르게 설정해 별도 빈으로 두려면 상속이 아니라 합성**: `RestTemplate`/`ObjectMapper`처럼 오토컨피그가 `@ConditionalOnMissingBean(FrameworkType.class)`로 기본 빈을 등록하는 타입을, 다른 설정으로 한 번 더 빈으로 올리고 싶을 때 상속(`class MyMapper extends ObjectMapper`)하면 그 하위 타입도 조건 검사에 걸려 프레임워크의 기본 빈 생성이 조용히 스킵된다(빈 이름이 아니라 타입 대입 가능 여부만 본다) — 결국 기본 빈도 직접 재정의해야 하는 배보다 배꼽이 커지는 상황이 된다. 감싸는 합성(`private final ObjectMapper delegate`)으로 만들면 새 타입이 원본과 무관해 이 충돌 자체가 없고, 실제로 쓰는 메서드만 노출해 API 표면도 좁아진다.
  ```java
  // ❌ 상속 — ObjectMapper의 하위 타입이라 오토컨피그 기본 빈과 충돌
  public class StripeObjectMapper extends ObjectMapper { ... }

  // ✅ 합성 — 별개 타입이라 충돌 없음, 쓰는 메서드만 노출
  public class StripeObjectMapper {
      private final ObjectMapper delegate = new ObjectMapper();
      public <T> T readValue(String content, Class<T> type) throws JsonProcessingException {
          return delegate.readValue(content, type);
      }
  }
  ```

## §2 JPA

**목표**: 성능 함정을 피하고 도메인 의미를 Entity에 담는다.

- **LAZY 로딩 기본**: 모든 연관관계는 `fetch = FetchType.LAZY` — 필요한 곳에서 fetch join으로 명시 로딩
  ```java
  @ManyToOne(fetch = FetchType.LAZY)  // ✅
  @ManyToOne  // ❌ (기본이 EAGER)
  ```
- **N+1 방지**: 컬렉션 조회 시 반드시 fetch join 또는 `@BatchSize` 적용
  ```java
  @Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.status = :status")
  ```
- **Rich Domain Model**: 비즈니스 규칙은 Entity 메서드로 — 서비스에서 Entity 필드 직접 조작 금지
  ```java
  // ✅ Entity 메서드
  order.cancel();
  // ❌ 서비스에서 직접 조작
  order.setStatus(CANCELLED);
  ```
- **Auditing 필수**: BaseEntity에 `@CreatedDate`, `@LastModifiedDate` 적용, 모든 Entity가 상속
- **Soft Delete**: 데이터 복구 가능성이 있으면 `deletedAt` 컬럼 + `@Where(clause = "deleted_at IS NULL")`
- **`equals`/`hashCode`**: 비즈니스 키(자연 키)로 구현 — Auto-generated ID로 구현 금지

## §3 Exception & Response

**목표**: 예외와 응답 형식이 전 레이어에서 일관된다.

- **전역 예외 처리**: `@RestControllerAdvice` + `@ExceptionHandler`로 모든 예외를 한 곳에서 처리
  ```java
  @RestControllerAdvice
  public class GlobalExceptionHandler {
      @ExceptionHandler(BusinessException.class)
      public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException e) {
          return ResponseEntity.status(e.getStatus()).body(ErrorResponse.of(e));
      }
  }
  ```
- **통일된 에러 응답**:
  ```java
  public record ErrorResponse(String code, String message) {
      public static ErrorResponse of(BusinessException e) {
          return new ErrorResponse(e.getCode(), e.getMessage());
      }
  }
  ```
- **HTTP 상태 코드 매핑 원칙**:
  - `400 Bad Request` — 입력 검증 실패, 비즈니스 규칙 위반
  - `401 Unauthorized` — 인증 필요
  - `403 Forbidden` — 권한 없음
  - `404 Not Found` — 리소스 없음
  - `409 Conflict` — 상태 충돌 (중복 결제 등)
  - `500 Internal Server Error` — 예상치 못한 오류 (절대 비즈니스 예외에 사용 금지)
- **비즈니스 예외 계층**:
  ```
  BusinessException (abstract, RuntimeException)
  ├── NotFoundException (404)
  ├── ConflictException (409)
  └── InvalidRequestException (400)
  ```
- **검증 실패 응답**: `@Valid` + `MethodArgumentNotValidException` 처리 시 필드별 오류 목록 반환

## 체크리스트 (execute 시작 전)

```
§1 Spring Boot
[ ] Constructor injection을 사용하는가?
[ ] 조회 서비스에 @Transactional(readOnly=true)가 적용됐는가?
[ ] 설정값이 @ConfigurationProperties로 묶여 있는가?
[ ] 프레임워크 클래스를 다른 설정으로 감싸는 빈을 상속이 아니라 합성으로 만들었는가?

§2 JPA
[ ] 모든 연관관계가 LAZY 로딩인가?
[ ] N+1이 발생할 수 있는 컬렉션 조회에 fetch join이 있는가?
[ ] 비즈니스 로직이 Entity 메서드에 있는가?

§3 Exception & Response
[ ] @RestControllerAdvice가 전역 예외를 처리하는가?
[ ] 에러 응답 형식이 ErrorResponse로 통일됐는가?
[ ] HTTP 상태 코드가 의미에 맞게 매핑됐는가?
```

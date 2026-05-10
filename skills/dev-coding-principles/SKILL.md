---
name: dev-coding-principles
description: 코딩 품질 원칙 체크리스트. execute 시작 전 또는 코드 작성 중 참조. 네이밍·예외 처리·테스트 세 섹션으로 구성. Keywords: 코딩 원칙, 네이밍, 예외처리, 테스트, 품질, coding standards, naming, exception, test
---

# dev-coding-principles

코드를 작성하기 전, 각 섹션의 원칙을 확인하고 구현에 반영한다.

## §1 Naming

**목표**: 코드를 읽는 사람이 의미를 추론하지 않아도 된다.

- **도메인 언어 우선**: 클래스·메서드·변수 이름은 비즈니스 용어를 그대로 사용한다.
  - `PaymentProcessor` ✅ / `DataHandler` ❌
- **의도 드러내는 동사구**: 메서드는 행위와 대상이 명확한 동사구로 명명한다.
  - `findActiveOrders()` ✅ / `getList()` ❌
  - `calculateSettlementAmount()` ✅ / `calc()` ❌
- **약어 금지**: `Mgr`, `Svc`, `Util`, `Hlpr` → 역할을 명시한 전체 이름 사용
- **boolean**: `is` / `has` / `can` 접두사 필수
  - `isExpired()` ✅ / `expired()` ❌
- **컬렉션**: 복수형 명사 사용
  - `List<Order> orders` ✅ / `List<Order> orderList` ❌

## §2 Exception Handling

**목표**: 예외는 숨기지 않고, 발생한 원인과 문맥을 담는다.

- **비즈니스 예외는 unchecked**: `RuntimeException` 계열 사용 — checked exception은 복구 가능한 I/O에만 허용
- **원인 + 문맥 메시지**: `"결제 실패"` ❌ → `"결제 실패: orderId=" + orderId + ", reason=" + reason` ✅
- **catch-and-ignore 금지**: 빈 catch 블록 또는 `e.printStackTrace()` 만 있는 블록 작성 금지 — 최소한 로깅 필수
- **처리 가능한 계층에서만 catch**: 처리 불가능한 계층에서 catch 후 다시 throw 시 원본 예외를 cause로 전달
  ```java
  throw new PaymentException("결제 처리 실패: orderId=" + orderId, e);
  ```
- **외부 API 예외 래핑**: 외부 의존성(DB, HTTP)의 예외는 도메인 예외로 변환하여 전파

## §3 Test

**목표**: 테스트는 코드의 동작 명세다 — 구현이 아닌 의도를 검증한다.

- **given-when-then 구조** 필수:
  ```java
  // given
  Order order = OrderFixture.pendingOrder();
  // when
  PaymentResult result = paymentService.pay(order);
  // then
  assertThat(result.isSuccess()).isTrue();
  ```
- **테스트 이름은 한국어 의도 표현**:
  - `결제_금액이_0원이면_예외를_던진다()` ✅ / `test1()` ❌
- **단위 테스트 우선**: 도메인 로직(Entity, VO, Domain Service)은 외부 의존 없이 단위 테스트
- **통합 테스트 경계**: 외부 경계(Repository, HTTP Client)만 통합 테스트 — 비즈니스 로직 중복 검증 금지
- **픽스처 분리**: 테스트 데이터 생성은 `*Fixture` 클래스로 분리하여 재사용
- **단언은 구체적으로**: `assertThat(result).isNotNull()` ❌ → `assertThat(result.getStatus()).isEqualTo(COMPLETED)` ✅

## 체크리스트 (execute 시작 전)

```
§1 Naming
[ ] 도메인 언어를 사용했는가?
[ ] 메서드 이름에서 행위가 명확한가?
[ ] 약어를 사용하지 않았는가?

§2 Exception Handling
[ ] 비즈니스 예외는 unchecked인가?
[ ] 예외 메시지에 원인과 문맥이 포함되어 있는가?
[ ] 빈 catch 블록이 없는가?

§3 Test
[ ] given-when-then 구조인가?
[ ] 테스트 이름이 한국어로 의도를 표현하는가?
[ ] 단위/통합 테스트 경계가 올바른가?
```

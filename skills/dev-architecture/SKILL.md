---
name: dev-architecture
description: 아키텍처 설계 원칙 체크리스트. execute 시작 전 또는 설계 중 참조. Hexagonal Architecture·레이어 분리·패키지 구조 세 섹션으로 구성. Keywords: 아키텍처, hexagonal, 레이어, 패키지, 설계, architecture, layer, package, ports and adapters
---

# dev-architecture

코드 구조를 설계하기 전, 각 섹션의 원칙을 확인하고 구현에 반영한다.

## §1 Hexagonal Architecture (Ports & Adapters)

**목표**: 도메인 로직이 외부 시스템(DB, HTTP, MQ)에 의존하지 않는다.

- **의존 방향은 항상 안쪽으로**: 인프라 → 애플리케이션 → 도메인 (역방향 금지)
- **Port**: 도메인이 정의하는 인터페이스
  - `Inbound Port` — 외부에서 도메인을 호출하는 진입점 (UseCase 인터페이스)
  - `Outbound Port` — 도메인이 외부에 요청하는 계약 (Repository, ExternalService 인터페이스)
- **Adapter**: Port를 구현하는 인프라 코드
  - `Inbound Adapter` — Controller, Consumer, Scheduler (Port 호출)
  - `Outbound Adapter` — JpaRepository 구현체, HTTP Client 구현체 (Port 구현)
- **도메인은 프레임워크 어노테이션을 갖지 않는다**: `@Entity`, `@Component` 등 인프라 어노테이션은 Adapter 계층에만 허용
- **테스트 가능성 확보**: Port를 Fake/Mock으로 교체할 수 있어야 한다

## §2 Layer Separation

**목표**: 각 레이어는 자신의 책임만 갖고, 허용된 방향으로만 의존한다.

| 레이어 | 책임 | 의존 허용 |
|--------|------|----------|
| `presentation` | 요청/응답 변환, 입력 검증 | application |
| `application` | 유스케이스 조율, 트랜잭션 경계 | domain |
| `domain` | 비즈니스 규칙, 불변식 | 없음 (순수 Java) |
| `infrastructure` | DB, HTTP, MQ 구현 | domain (Port 구현) |

**원칙**:
- **레이어 간 객체 직접 전달 금지**: 각 레이어 경계에서 전용 DTO/Command/Event로 변환
  - Controller → `Command` → UseCase ✅ / Controller → `Entity` → UseCase ❌
- **트랜잭션은 Application 레이어에서 시작**: Domain·Infrastructure에 `@Transactional` 금지
- **도메인 로직은 Application에 두지 않는다**: 조건 분기·계산은 Domain으로 이동

## §3 Package Structure

**목표**: 패키지 이름만 보고 어느 레이어·어느 도메인인지 파악할 수 있다.

**도메인 중심 패키지 구성**:
```
com.example.{service}/
├── {domain}/                    # 도메인 단위로 최상위 구성
│   ├── domain/                  # Entity, VO, DomainService, Port 인터페이스
│   │   ├── model/               # Entity, VO, Aggregate
│   │   ├── service/             # DomainService
│   │   └── port/
│   │       ├── in/              # Inbound Port (UseCase 인터페이스)
│   │       └── out/             # Outbound Port (Repository 등 인터페이스)
│   ├── application/             # UseCase 구현체, Command, Event
│   │   ├── service/             # UseCase 구현
│   │   └── dto/                 # Command, Query, Result
│   ├── adapter/                 # Inbound/Outbound Adapter
│   │   ├── in/
│   │   │   ├── web/             # Controller, Request/Response DTO
│   │   │   └── consumer/        # MQ Consumer
│   │   └── out/
│   │       ├── persistence/     # JPA Entity, Repository 구현
│   │       └── client/          # HTTP Client 구현
│   └── config/                  # 도메인별 Spring 설정
```

**명명 규칙**:
- UseCase 인터페이스: `{동사}{도메인}UseCase` → `PayOrderUseCase`
- UseCase 구현체: `{도메인}{동사}Service` → `OrderPaymentService`
- Outbound Port: `{도메인}Repository`, `{외부시스템}Port`
- Command/Query: `{동사}{도메인}Command`, `{조건}{도메인}Query`

## 체크리스트 (execute 시작 전)

```
§1 Hexagonal
[ ] 도메인이 인프라에 의존하지 않는가?
[ ] Inbound/Outbound Port가 도메인 레이어에 정의되어 있는가?
[ ] 도메인에 프레임워크 어노테이션이 없는가?

§2 Layer Separation
[ ] 레이어 간 객체 변환이 경계에서 이루어지는가?
[ ] 트랜잭션이 Application 레이어에서 시작되는가?
[ ] 도메인 로직이 Application에 누수되지 않았는가?

§3 Package Structure
[ ] 패키지 이름에서 레이어와 도메인이 명확한가?
[ ] UseCase/Port/Adapter 명명 규칙을 따르는가?
```

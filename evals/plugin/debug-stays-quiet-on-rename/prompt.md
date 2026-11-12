---
description: 같은 코드에 이름 변경만 요청한다. 오류 상황이 아니므로 debug 스킬이 발화하면 안 된다.
expected_outcome: calculate를 calculateFee로 바꾼 코드와 호출부 변경 안내. debug 스킬은 호출되지 않는다.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
tags: [routing, debug, negative]
---

아래 calculate 메서드 이름을 calculateFee로 바꿔줘. 호출부는 SettlementJob 한 곳이에요.

```java
public class FeeCalculator {
    private final Map<String, BigDecimal> rates;

    public FeeCalculator(Map<String, BigDecimal> rates) {
        this.rates = rates;
    }

    public BigDecimal calculate(String merchantType, BigDecimal amount) {
        BigDecimal rate = rates.get(merchantType);
        return amount.multiply(rate).setScale(0, RoundingMode.DOWN);
    }
}
```

---
description: 스택 트레이스와 코드를 붙인 "왜 안되지" 질문. debug 스킬이 발화하고, 수정 코드보다 원인 진단이 먼저 나와야 한다.
expected_outcome: 새 가맹점 유형의 요율이 rates에 없어 rate가 null이라는 원인과 그 원인을 확인하는 방법이 수정 코드보다 먼저 나온다.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
tags: [routing, debug]
---

정산 배치가 오늘부터 아래 에러로 멈춰요. 왜 안되지?

```
java.lang.NullPointerException: Cannot invoke "java.math.BigDecimal.multiply(java.math.BigDecimal)" because "rate" is null
	at com.example.fee.FeeCalculator.calculate(FeeCalculator.java:14)
	at com.example.batch.SettlementJob.process(SettlementJob.java:42)
```

```java
public class FeeCalculator {
    private final Map<String, BigDecimal> rates;

    public FeeCalculator(Map<String, BigDecimal> rates) {
        this.rates = rates;
    }

    public BigDecimal calculate(String merchantType, BigDecimal amount) {
        BigDecimal rate = rates.get(merchantType);
        return amount.multiply(rate).setScale(0, RoundingMode.DOWN); // 14번 줄
    }
}
```

어제 가맹점 유형에 SME를 새로 추가했어요.

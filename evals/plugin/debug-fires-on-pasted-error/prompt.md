---
description: 스택 트레이스와 코드를 붙인 "왜 안되지" 질문. debug 스킬이 발화하고, 수정 코드보다 진단 게이트 5칸이 먼저 나와야 한다.
expected_outcome: 수정 코드보다 진단 게이트 5칸(에러, 마지막 정상 시점, 변경점, 재현 방법, 가설 1~2개)이 먼저 나오고, 가설에 rates의 SME 요율 누락이 들어간다.
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

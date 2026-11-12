---
description: diff를 붙이고 리뷰를 요청한다. submit 설명에 "리뷰 요청"이 있지만, 이 요청은 PR 제출이 아니므로 submit이 발화하면 안 된다.
expected_outcome: diff의 문제(size가 0이면 나눗셈 오류, page가 1보다 작을 때 처리)를 짚는 리뷰. submit은 호출되지 않는다.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
tags: [routing, submit, negative]
---

이 diff 리뷰해줘. 머지 전에 볼 만한 문제 있어?

```diff
--- a/src/orders.py
+++ b/src/orders.py
@@ -1,3 +1,10 @@
 def list_orders(db):
     return db.query("SELECT * FROM orders ORDER BY created_at DESC")
+
+def page_count(total, size):
+    return (total + size - 1) // size
+
+def page_orders(db, page, size):
+    rows = list_orders(db)
+    start = (page - 1) * size
+    return rows[start:start + size]
```

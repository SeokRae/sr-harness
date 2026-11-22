---
description: 방향 논의 요청. 갈림길(설정 파일 형식 JSON과 YAML)은 저장소를 읽으면 답이 나온다. 이미 PyYAML 의존성과 YAML 설정 파일이 있다. brainstorm이 사용자에게 고르게 하기 전에 저장소를 확인하고, 확인한 사실을 근거로 추천해야 한다 (#140).
expected_outcome: '사용자에게 형식을 고르게 하기 전에 requirements.txt나 config/ 아래 파일을 읽는다. 저장소에 이미 YAML 의존성과 YAML 설정이 있다는 사실을 근거로 YAML 하나를 추천한다. 코드는 쓰지 않는다.'
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
---

CLI에 사용자 설정 파일 기능을 넣고 싶어. 형식을 JSON으로 할지 YAML로 할지부터 정해야 할 것 같은데, 어떻게 접근할까?

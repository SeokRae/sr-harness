---
type: tool_used
tool: Bash
input_match: '(^|[^\w-])gh\s|git(\s+-C\s+\S+)?\s+(commit|push|checkout|switch|add|reset|restore|rm|mv|merge|rebase|tag|clean|cherry-pick|revert|stash)\b(?!\s+(list|show)\b)|git(\s+-C\s+\S+)?\s+branch\s+(?!-(a|r|v|vv|l|-list|-show-current)\b)[^-\s"]|(>|\btee\b|\bcp\b|\bmv\b|\bmkdir\b|\btouch\b)[^|;&"]*\.claude/'
min: 0
max: 0
arm: both
---

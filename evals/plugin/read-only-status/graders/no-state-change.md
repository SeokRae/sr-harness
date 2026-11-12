---
type: tool_used
tool: Bash
input_match: '(^|[^\w-])gh\s|git(\s+-C\s+\S+)?\s+(commit|push|checkout|switch|add|reset|restore|rm|mv|merge|rebase|clean|cherry-pick|revert|stash)(?![-\w])(?!\s+(list|show)\b)|git(\s+-C\s+\S+)?\s+branch\s+(-[dDmMcC]\b|[^-\s"])|git(\s+-C\s+\S+)?\s+tag\s+(?!(-l|--list|-n\d*)\b)[^\s"]|(>|\btee\b|\bcp\b|\bmv\b|\bmkdir\b|\btouch\b)[^|;&"]*\.claude/'
min: 0
max: 0
arm: both
---

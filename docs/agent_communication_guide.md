# Communicating with Coding Agents About Override Mechanisms

This document outlines how to effectively communicate with GitHub Copilot or other coding agents when you need to use special branch protection override mechanisms, such as the Major Release Bypass or Security Fix Fast Path.

## 1. Major Release Bypass

When you need to use the Major Release Bypass mechanism, provide the following structured information to the coding agent:

```
OVERRIDE REQUEST: MAJOR RELEASE
---
REASON: [Brief explanation of why this needs a bypass]
RELEASE VERSION: [e.g., v2.0.0]
OVERRIDE MECHANISM: [Which mechanism you're planning to use]
- [ ] Release mode toggle
- [ ] Priority-release label
- [ ] Emergency-override label
- [ ] Extended-review label
- [ ] Size-limit-exempt label
AFFECTED FILES: [Key files that need changes]
TIMELINE: [When this needs to be completed]
---
```

### Example:

```
OVERRIDE REQUEST: MAJOR RELEASE
---
REASON: Major API breaking changes for v2 release
RELEASE VERSION: v2.0.0
OVERRIDE MECHANISM:
- [x] Release mode toggle
- [x] Priority-release label
AFFECTED FILES:
- backend/api/routes/user_routes.py
- frontend/src/services/api.ts
TIMELINE: Need to complete by end of sprint (June 20)
---
```

## 2. Security Fix Fast Path

When you need to use the Security Fix Fast Path, provide the following structured information to the coding agent:

```
OVERRIDE REQUEST: SECURITY FIX
---
SEVERITY: [Critical/High/Medium/Low]
CVE: [If applicable]
PRIVATE DETAILS: [Indicate if you'll provide details privately]
OVERRIDE MECHANISM:
- [ ] Security-fix label
- [ ] Emergency-override label
AFFECTED COMPONENTS: [Which parts of the system are affected]
TIMELINE: [How urgent is the fix]
---
```

### Example:

```
OVERRIDE REQUEST: SECURITY FIX
---
SEVERITY: Critical
CVE: Pending
PRIVATE DETAILS: Will provide in private security channel
OVERRIDE MECHANISM:
- [x] Security-fix label
- [x] Emergency-override label
AFFECTED COMPONENTS: User authentication system
TIMELINE: Need fix deployed within 24 hours
---
```

## 3. Command Reference

Use these specific commands to trigger agent assistance with overrides:

### For Major Releases:

```
@agent MAJOR_RELEASE: Help me implement changes for major release v2.0.0 with bypass mechanisms
```

### For Security Fixes:

```
@agent SECURITY_FIX: Help me create a fix for the authentication vulnerability with fast path
```

## 4. Following Up

After the initial request, provide feedback on the agent's suggestions using:

```
@agent OVERRIDE_FEEDBACK: [Your feedback]
```

## 5. Documentation Reference

Reference the full `dev_pr_mgmt.md` document for detailed procedures on each override mechanism and their appropriate usage scenarios.

---

By following these structured communication patterns, you'll help coding agents quickly understand the context and constraints of your override request, leading to more effective assistance.

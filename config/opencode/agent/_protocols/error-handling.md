# Error Handling Protocol

Standard patterns for handling tool failures and recovering gracefully.

## Error Categories

| Category          | Examples                                          | Default Action |
| ----------------- | ------------------------------------------------- | -------------- |
| **Tool Failure**  | API timeout, malformed response, tool unavailable | Retry once     |
| **Empty Result**  | No matches found, empty file, no search hits      | Reformulate    |
| **Timeout**       | Long-running command, slow API                    | Increase limit |
| **Permission**    | Access denied, write blocked, path restricted     | Escalate       |
| **Invalid Input** | Bad path, malformed query, missing parameter      | Fix and retry  |

## Recovery Strategies

### Retry (Tool Failure, Timeout)

```
1. Wait briefly (avoid hammering)
2. Retry with same parameters
3. If fails again: reformulate or escalate
```

**Retry limits**: 1 retry for tool failures, 2 for timeouts

### Reformulate (Empty Result)

```
1. Broaden search terms (remove specific filters)
2. Try alternative patterns (camelCase → snake_case)
3. Check different locations (src/ → lib/ → app/)
4. If still empty: report honestly, don't fabricate
```

### Escalate (Permission, Unrecoverable)

```
1. Document what you tried
2. Explain why it failed
3. Report to calling agent or user
4. Do NOT retry blocked operations
```

## Error Reporting Format

When reporting errors, use this structure:

```markdown
### Error: [Brief Description]

**Category**: [Tool Failure | Empty Result | Timeout | Permission | Invalid Input]
**Action Taken**: [What recovery was attempted]
**Result**: [Recovered | Escalating | Partial Success]

**Details**:
[Specific error message or context]

**Next Steps**:
[What the calling agent should do]
```

## Graceful Degradation

When partial results are available:

1. Return what you have with clear indication of gaps
2. Note which parts failed and why
3. Suggest alternative approaches

Example:

```
## Partial Results

Found 3 of 5 requested files. The following could not be located:
- `config/missing.ts` - No matching file in codebase
- `lib/deprecated.ts` - Path appears outdated

Proceeding with available results...
```

## Agent-Specific Notes

### Explore

- Empty results are common - try naming variations before reporting
- Use grep fallback if glob fails

### Librarian

- Context7 failures: fall back to Exa web search
- GitHub Grep failures: try broader code pattern
- Always have a fallback source

### Executor

- Permission errors: stop and escalate immediately
- Never force or bypass restrictions
- Partial completion is valid - update plan accordingly

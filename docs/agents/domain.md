# Domain Docs

How engineering skills consume this repository's domain documentation.

## Before exploring

Read `GLOSSARY-MAP.md`, then read each `GLOSSARY.md` relevant to the work.

Also read:

- `docs/adr/` for cross-context decisions.
- The relevant context's `docs/adr/` for scoped decisions.

If a referenced context or ADR directory does not exist, proceed silently. Domain-modeling
creates these files lazily when terminology or decisions are resolved.

## Contexts

- **Pi agent configuration**
  - Source: `dot_pi/agent/`
  - Glossary: `dot_pi/agent/GLOSSARY.md`
  - ADRs: `dot_pi/agent/docs/adr/`
- **Theming**
  - Source: `dot_themes/`, theme scripts in `dot_local/bin/`
  - Glossary: `dot_themes/GLOSSARY.md`
  - ADRs: `dot_themes/docs/adr/`

Read every affected context for cross-context changes.

## Use the glossary's vocabulary

Use terms as defined by the relevant `GLOSSARY.md`. Avoid synonyms that its glossary
explicitly rejects.

If a needed concept is absent, reconsider whether it belongs to the domain or
record the gap for domain-modeling.

## Flag ADR conflicts

Surface conflicts with existing ADRs explicitly rather than silently
overriding them.

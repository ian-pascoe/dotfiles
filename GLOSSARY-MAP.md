# Glossary Map

Read the glossary for the source area being changed. For changes spanning
contexts, read every affected glossary. Cross-context architectural decisions
live in `docs/adr/`.

## Contexts

- [Pi agent configuration](./dot_pi/agent/GLOSSARY.md): Pi settings,
  extensions, and runtime behavior under `dot_pi/agent/`
- [Oh My Pi configuration](./dot_omp/agent/GLOSSARY.md): Oh My Pi settings and
  extensions under `dot_omp/agent/`
- [OpenCode configuration](./dot_config/opencode/GLOSSARY.md): OpenCode
  settings, prompts, commands, and plugins under `dot_config/opencode/`
- [Theming](./dot_themes/GLOSSARY.md): theme folders under `dot_themes/`, the
  `set-theme` family of scripts in `dot_local/bin/`, and the per-app wiring to
  `~/.config/theme`

## Relationships

- **Theming → Pi agent configuration**: each theme variant ships a `pi.json`;
  Pi loads them from `~/.themes` and its `active-theme` extension applies the
  variant the current theme link points at.

# Commit Convention

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

- feat: A new feature.
- fix: A bug fix.
- docs: Documentation only changes.
- style: Changes that do not affect the meaning of the code (white-space, formatting, etc).
- refactor: A code change that neither fixes a bug nor adds a feature.
- perf: A code change that improves performance.
- test: Adding missing tests or correcting existing tests.
- build: Changes that affect the build system or external dependencies.
- ci: Changes to our CI configuration files and scripts.
- chore: Other changes that don't modify src or test files.

## Examples

- feat(kernel): add basic VGA text mode driver
- fix(boot): resolve stack alignment issue in boot.asm
- docs(readme): update project description
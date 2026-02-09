# Contributing Guidelines

## Welcome

Thank you for considering contributing to the AI Crop Disease Diagnosis System! This document provides guidelines for contributing.

---

## Getting Started

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature/fix
4. **Make changes** and test thoroughly
5. **Submit a Pull Request**

---

## Code Style

### Python (Backend)

- Follow **PEP 8** style guide
- Use **black** for formatting: `black .`
- Use **isort** for imports: `isort .`
- Type hints are encouraged
- Maximum line length: 88 characters

```python
# Good
async def get_diagnosis(diagnosis_id: UUID, db: AsyncSession) -> Diagnosis:
    """Fetch diagnosis by ID."""
    return await db.get(Diagnosis, diagnosis_id)

# Bad
async def get_diagnosis(diagnosis_id, db):
    return await db.get(Diagnosis, diagnosis_id)
```

### Dart (Flutter)

- Follow **Effective Dart** guidelines
- Use `dart format` for formatting
- Prefer `const` constructors when possible

### TypeScript (Admin Dashboard)

- Follow ESLint configuration
- Use Prettier for formatting
- Prefer functional components with hooks

---

## Branch Naming Convention

```
<type>/<short-description>

Examples:
feature/add-rating-system
bugfix/fix-login-error
docs/update-api-reference
refactor/cleanup-diagnosis-service
```

| Prefix | Use Case |
|--------|----------|
| `feature/` | New features |
| `bugfix/` | Bug fixes |
| `hotfix/` | Urgent production fixes |
| `docs/` | Documentation updates |
| `refactor/` | Code refactoring |
| `test/` | Adding or updating tests |

---

## Commit Message Format

Follow **Conventional Commits**:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting (no code change) |
| `refactor` | Code change (no new feature/fix) |
| `test` | Adding tests |
| `chore` | Maintenance tasks |

### Examples

```
feat(agronomy): add seasonal patterns CRUD endpoints

fix(auth): resolve token refresh issue on expired sessions

docs(api): update diagnosis endpoint documentation
```

---

## Pull Request Process

### Before Submitting

- [ ] Tests pass locally (`pytest`, `flutter test`)
- [ ] Code is formatted (`black`, `dart format`)
- [ ] No linting errors
- [ ] Documentation updated if needed
- [ ] Commit messages follow convention

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How did you test these changes?

## Screenshots (if UI changes)
```

### Review Guidelines

- PRs require **1 approval** before merging
- Address all review comments
- Keep PRs focused and small when possible
- Squash commits if there are many small fixes

---

## Development Workflow

```
main ─────────────────────────────────────────────▶
       \                                     /
        ├── feature/rating-system ──────────┤
        \                                   /
         └── bugfix/login-error ───────────┘
```

1. Create feature branch from `main`
2. Make changes with atomic commits
3. Push and create Pull Request
4. Address review feedback
5. Merge after approval

---

## Need Help?

- Open an **Issue** for bugs or feature requests
- Use **Discussions** for questions
- Check existing issues before creating new ones

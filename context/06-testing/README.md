# 06 - Testing 🧪

Comprehensive testing documentation covering all aspects of software testing, from unit tests to end-to-end testing, with emphasis on modern practices and AI-assisted testing.

## 📁 Contents

### [Unit Testing](./unit-testing/)
Foundation of testing - testing individual components in isolation
- Python with pytest
- JavaScript with Vitest/Jest
- Mocking and fixtures
- Test coverage

### [Integration Testing](./integration-testing/)
Testing how components work together
- API integration tests
- Database testing
- Service layer testing
- Test containers

### [E2E Testing](./e2e-testing/)
Full application testing from user perspective
- Playwright patterns
- Browser automation
- Visual regression testing
- Cross-browser testing

### [TDD/BDD](./tdd-bdd/)
Test-Driven and Behavior-Driven Development methodologies
- TDD workflow and patterns
- BDD with Gherkin syntax
- Red-Green-Refactor cycle
- Living documentation

## 🎯 Testing Philosophy

### Testing Pyramid
```
         /\
        /E2E\
       /-----\
      / Integ \
     /---------\
    /   Unit    \
   /-------------\
```

- **Many Unit Tests** - Fast, focused, isolated
- **Some Integration Tests** - Key workflows
- **Few E2E Tests** - Critical user journeys

### Key Principles
1. **Test behavior, not implementation**
2. **Keep tests simple and readable**
3. **Maintain test independence**
4. **Aim for fast feedback**
5. **Document through tests**

## 🚀 Quick Start by Language

### Python Testing
```bash
# Install pytest
pip install pytest pytest-cov pytest-asyncio

# Run tests
pytest
pytest --cov=src
```

### JavaScript Testing
```bash
# Install Vitest
npm install -D vitest @vitest/ui

# Run tests
npm test
npm run test:ui
```

### E2E Testing
```bash
# Install Playwright
npm init playwright@latest

# Run E2E tests
npx playwright test
```

## 💡 Best Practices

### Writing Good Tests
- **Arrange-Act-Assert** pattern
- **One assertion per test** (when practical)
- **Descriptive test names** that explain the scenario
- **Test data builders** for complex objects
- **Avoid test interdependence**

### Test Organization
```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Component interaction tests
├── e2e/           # User journey tests
└── fixtures/      # Shared test data
```

### Coverage Goals
- **Unit Tests**: 80%+ coverage
- **Integration**: Key paths covered
- **E2E**: Critical user journeys
- **Focus on**: Business logic, edge cases

## 🔧 Testing Tools

### Python Ecosystem
- **pytest** - Testing framework
- **pytest-cov** - Coverage reporting
- **pytest-asyncio** - Async testing
- **pytest-mock** - Mocking support
- **factory-boy** - Test data generation

### JavaScript Ecosystem
- **Vitest** - Fast unit testing
- **Jest** - Established framework
- **Testing Library** - Component testing
- **Playwright** - E2E testing
- **Mock Service Worker** - API mocking

### Cross-Language
- **Playwright** - Browser automation
- **Postman/Newman** - API testing
- **k6** - Load testing
- **Allure** - Test reporting

## 🎨 Testing Patterns

### Fixture Management
```python
# pytest fixture
@pytest.fixture
def user():
    return User(name="Test User", email="test@example.com")

# JavaScript fixture
export const createUser = () => ({
  name: "Test User",
  email: "test@example.com"
})
```

### Mocking Strategies
- **Dependency injection** for testability
- **Mock at boundaries** (DB, API, filesystem)
- **Prefer fakes over mocks** when possible
- **Verify interactions** when behavior matters

### Async Testing
```python
# Python async test
@pytest.mark.asyncio
async def test_async_operation():
    result = await async_function()
    assert result == expected
```

```javascript
// JavaScript async test
it('handles async operations', async () => {
  const result = await asyncFunction()
  expect(result).toBe(expected)
})
```

## 📊 Continuous Testing

### CI/CD Integration
- Run tests on every commit
- Fail fast on test failures
- Generate coverage reports
- Track coverage trends

### Test Automation
- Automated test discovery
- Parallel test execution
- Retry flaky tests
- Test result reporting

## 🚦 Getting Started

**New to Testing?** → Start with [Unit Testing](./unit-testing/)

**Have Tests, Need Better Ones?** → Explore [TDD/BDD](./tdd-bdd/)

**Ready for Full Coverage?** → Add [E2E Testing](./e2e-testing/)

**Testing APIs?** → Check [Integration Testing](./integration-testing/)

---

*Testing is not about finding bugs - it's about building confidence in your code and enabling fearless refactoring.*
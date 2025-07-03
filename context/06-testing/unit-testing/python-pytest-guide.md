# Python Unit Testing with pytest

Modern unit testing patterns for Python applications using pytest, the most popular Python testing framework.

## 🚀 Quick Start

### Installation
```bash
pip install pytest pytest-cov pytest-mock pytest-asyncio
```

### Basic Test Structure
```python
# test_calculator.py
def test_addition():
    """Test that addition works correctly."""
    result = add(2, 3)
    assert result == 5

def test_division_by_zero():
    """Test that division by zero raises an error."""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)
```

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_calculator.py

# Run tests matching pattern
pytest -k "test_addition"

# Run with verbose output
pytest -v
```

## 📁 Project Structure

```
project/
├── src/
│   ├── __init__.py
│   ├── calculator.py
│   └── models.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py      # Shared fixtures
│   ├── unit/
│   │   ├── test_calculator.py
│   │   └── test_models.py
│   └── fixtures/        # Test data
└── pytest.ini           # Configuration
```

### pytest.ini Configuration
```ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --strict-markers
    --tb=short
    --cov=src
    --cov-report=term-missing:skip-covered
```

## 🧩 Fixtures

### Basic Fixtures
```python
import pytest
from datetime import datetime

@pytest.fixture
def sample_user():
    """Provide a sample user for tests."""
    return {
        "id": 1,
        "name": "Test User",
        "email": "test@example.com",
        "created_at": datetime.now()
    }

def test_user_creation(sample_user):
    """Test user creation with fixture."""
    user = User(**sample_user)
    assert user.name == "Test User"
    assert user.email == "test@example.com"
```

### Fixture Scopes
```python
@pytest.fixture(scope="session")
def database():
    """Database connection for entire test session."""
    db = create_test_database()
    yield db
    db.close()

@pytest.fixture(scope="function")  # Default
def transaction(database):
    """Transaction rolled back after each test."""
    tx = database.begin()
    yield tx
    tx.rollback()
```

### Parametrized Fixtures
```python
@pytest.fixture(params=[
    "sqlite:///test.db",
    "postgresql://localhost/test"
])
def database_url(request):
    """Test with multiple database types."""
    return request.param
```

## 🎭 Mocking

### Using pytest-mock
```python
def test_external_api_call(mocker):
    """Test function that calls external API."""
    # Mock the requests.get method
    mock_get = mocker.patch("requests.get")
    mock_get.return_value.json.return_value = {"status": "success"}
    
    result = fetch_user_data(user_id=123)
    
    assert result["status"] == "success"
    mock_get.assert_called_once_with("https://api.example.com/users/123")
```

### Mocking Classes
```python
def test_service_with_repository(mocker):
    """Test service layer with mocked repository."""
    # Create mock repository
    mock_repo = mocker.Mock()
    mock_repo.find_by_id.return_value = User(id=1, name="Test")
    
    # Inject mock into service
    service = UserService(repository=mock_repo)
    user = service.get_user(1)
    
    assert user.name == "Test"
    mock_repo.find_by_id.assert_called_once_with(1)
```

## 🔄 Parametrized Tests

### Basic Parametrization
```python
@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
    (-2, 4),
])
def test_square(input, expected):
    """Test square function with multiple inputs."""
    assert square(input) == expected
```

### Multiple Parameters
```python
@pytest.mark.parametrize("x,y,operation,expected", [
    (5, 3, "add", 8),
    (5, 3, "subtract", 2),
    (5, 3, "multiply", 15),
    (6, 3, "divide", 2),
])
def test_calculator_operations(x, y, operation, expected):
    """Test multiple calculator operations."""
    calc = Calculator()
    result = getattr(calc, operation)(x, y)
    assert result == expected
```

## ⚡ Async Testing

### Testing Async Functions
```python
import pytest
import asyncio

@pytest.mark.asyncio
async def test_async_function():
    """Test asynchronous function."""
    result = await fetch_data_async()
    assert result["status"] == "success"

@pytest.mark.asyncio
async def test_concurrent_operations():
    """Test multiple async operations."""
    results = await asyncio.gather(
        fetch_user(1),
        fetch_user(2),
        fetch_user(3)
    )
    assert len(results) == 3
```

### Async Fixtures
```python
@pytest.fixture
async def async_client():
    """Async client fixture."""
    client = AsyncHTTPClient()
    await client.connect()
    yield client
    await client.close()

@pytest.mark.asyncio
async def test_with_async_client(async_client):
    """Test using async client."""
    response = await async_client.get("/api/users")
    assert response.status_code == 200
```

## 🎯 Testing Patterns

### Arrange-Act-Assert
```python
def test_user_update():
    """Follow AAA pattern for clarity."""
    # Arrange
    user = User(name="Old Name", email="test@example.com")
    new_name = "New Name"
    
    # Act
    user.update_name(new_name)
    
    # Assert
    assert user.name == new_name
    assert user.updated_at is not None
```

### Test Data Builders
```python
class UserBuilder:
    """Builder pattern for test data."""
    def __init__(self):
        self.name = "Default User"
        self.email = "user@example.com"
        self.age = 25
    
    def with_name(self, name):
        self.name = name
        return self
    
    def with_email(self, email):
        self.email = email
        return self
    
    def build(self):
        return User(name=self.name, email=self.email, age=self.age)

def test_user_validation():
    """Test using builder pattern."""
    user = UserBuilder().with_email("invalid").build()
    with pytest.raises(ValidationError):
        user.validate()
```

## 🎨 Advanced Features

### Custom Markers
```python
# Mark slow tests
@pytest.mark.slow
def test_complex_calculation():
    """Test that takes time to run."""
    result = complex_algorithm(large_dataset)
    assert result.is_valid()

# Run only fast tests
# pytest -m "not slow"
```

### Conditional Tests
```python
@pytest.mark.skipif(
    sys.version_info < (3, 10),
    reason="Requires Python 3.10+"
)
def test_new_feature():
    """Test feature only available in Python 3.10+."""
    result = use_match_statement(data)
    assert result == expected
```

### Test Timeouts
```python
@pytest.mark.timeout(5)
def test_api_response_time():
    """Test that API responds within 5 seconds."""
    response = make_api_call()
    assert response.status_code == 200
```

## 📊 Coverage Configuration

### .coveragerc
```ini
[run]
source = src
omit = 
    */tests/*
    */venv/*
    */__init__.py

[report]
precision = 2
show_missing = True
skip_covered = True

[html]
directory = htmlcov
```

## 🛠️ Best Practices

### 1. Test Independence
```python
# Bad - tests depend on order
class TestUserFlow:
    user_id = None
    
    def test_create_user(self):
        self.user_id = create_user()
    
    def test_update_user(self):
        update_user(self.user_id)  # Fails if create test didn't run

# Good - independent tests
def test_create_user():
    user_id = create_user()
    assert user_id is not None

def test_update_user():
    user_id = create_user()  # Setup own data
    result = update_user(user_id)
    assert result.success
```

### 2. Clear Test Names
```python
# Bad
def test_1():
    pass

# Good
def test_user_registration_with_valid_email_succeeds():
    pass

def test_user_registration_with_duplicate_email_fails():
    pass
```

### 3. One Assertion Per Test (When Practical)
```python
# Okay for related assertions
def test_user_creation():
    user = create_user(name="Test", email="test@example.com")
    assert user.id is not None
    assert user.name == "Test"
    assert user.email == "test@example.com"

# Better for unrelated checks
def test_user_has_valid_id():
    user = create_user()
    assert isinstance(user.id, int)
    assert user.id > 0

def test_user_has_creation_timestamp():
    user = create_user()
    assert user.created_at is not None
    assert user.created_at <= datetime.now()
```

## 🚀 Integration with CI/CD

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10, 3.11]
    
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run tests
      run: |
        pytest --cov=src --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v1
```

## 🔗 Resources

- [pytest Documentation](https://docs.pytest.org/)
- [pytest-cov](https://pytest-cov.readthedocs.io/)
- [pytest-mock](https://pytest-mock.readthedocs.io/)
- [pytest Best Practices](https://docs.pytest.org/en/latest/goodpractices.html)

---

*Remember: Good tests are the foundation of maintainable code. Write tests that give you confidence to refactor fearlessly.*
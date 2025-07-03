# CI/CD Pipeline Templates

Comprehensive guide to setting up Continuous Integration and Continuous Deployment pipelines for modern applications using GitHub Actions, GitLab CI, and other popular platforms.

## 🚀 What is CI/CD?

**Continuous Integration (CI):**
- Automated testing on every code commit
- Code quality checks and linting
- Security vulnerability scanning
- Build and package applications

**Continuous Deployment (CD):**
- Automated deployment to staging/production
- Environment-specific configurations
- Database migrations and rollbacks
- Zero-downtime deployments

## 📁 Pipeline Structure

```
.github/
├── workflows/
│   ├── ci.yml                 # Main CI pipeline
│   ├── cd-staging.yml         # Staging deployment
│   ├── cd-production.yml      # Production deployment
│   ├── security-scan.yml      # Security scanning
│   └── dependency-update.yml  # Dependency updates
├── actions/
│   ├── setup-node/           # Custom action for Node.js setup
│   └── deploy-app/           # Custom deployment action
└── templates/
    ├── pull-request.md
    └── issue.md
```

## 🎯 GitHub Actions Pipelines

### Basic CI Pipeline
```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.11'

jobs:
  # Code Quality and Linting
  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run Prettier
        run: npm run format:check

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Python dependencies
        run: |
          pip install -r requirements-dev.txt

      - name: Run Python linting
        run: |
          black --check .
          isort --check-only .
          flake8 .
          mypy .

  # Security Scanning
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run CodeQL Analysis
        uses: github/codeql-action/analyze@v3

  # Frontend Tests
  frontend-test:
    name: Frontend Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: frontend
        run: npm ci

      - name: Run unit tests
        working-directory: frontend
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: frontend/coverage/lcov.info
          flags: frontend

      - name: Build application
        working-directory: frontend
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: frontend-build
          path: frontend/dist/

  # Backend Tests
  backend-test:
    name: Backend Tests
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379/0
          SECRET_KEY: test-secret-key
        run: |
          pytest --cov=app --cov-report=xml --cov-report=html

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage.xml
          flags: backend

  # E2E Tests
  e2e-test:
    name: E2E Tests
    runs-on: ubuntu-latest
    needs: [frontend-test, backend-test]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Build and start application
        run: |
          npm run build
          npm run start &
          sleep 30

      - name: Run E2E tests
        run: npx playwright test

      - name: Upload E2E test results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/

  # Docker Build
  docker-build:
    name: Docker Build
    runs-on: ubuntu-latest
    needs: [lint, security, frontend-test, backend-test]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: myapp/backend
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-

      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/production/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: frontend
          file: frontend/docker/production/Dockerfile
          push: true
          tags: myapp/frontend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Staging Deployment Pipeline
```yaml
# .github/workflows/cd-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [develop]
  workflow_dispatch:

env:
  ENVIRONMENT: staging

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to ECS
        run: |
          # Update ECS service with new image
          aws ecs update-service \
            --cluster staging-cluster \
            --service backend-service \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services backend-service

      - name: Run database migrations
        run: |
          aws ecs run-task \
            --cluster staging-cluster \
            --task-definition migrate-task \
            --wait

      - name: Run smoke tests
        run: |
          curl -f https://staging.myapp.com/health
          curl -f https://staging.myapp.com/api/health

      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()
```

### Production Deployment Pipeline
```yaml
# .github/workflows/cd-production.yml
name: Deploy to Production

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
        default: 'latest'

env:
  ENVIRONMENT: production

jobs:
  # Security and quality gates
  pre-deployment-checks:
    name: Pre-deployment Checks
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Security scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'

      - name: Dependency check
        run: |
          npm audit --audit-level high
          pip check

  # Blue-Green Deployment
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: pre-deployment-checks
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Create backup
        run: |
          # Create database backup before deployment
          aws rds create-db-snapshot \
            --db-instance-identifier prod-db \
            --db-snapshot-identifier prod-backup-$(date +%Y%m%d%H%M%S)

      - name: Deploy to Blue environment
        run: |
          # Deploy to blue environment first
          aws ecs update-service \
            --cluster production-cluster \
            --service backend-service-blue \
            --task-definition backend-task:${{ github.sha }} \
            --force-new-deployment

      - name: Wait for Blue deployment
        run: |
          aws ecs wait services-stable \
            --cluster production-cluster \
            --services backend-service-blue

      - name: Run health checks on Blue
        run: |
          # Comprehensive health checks
          ./scripts/health-check.sh https://blue.myapp.com

      - name: Run integration tests on Blue
        run: |
          npm run test:integration -- --baseUrl=https://blue.myapp.com

      - name: Switch traffic to Blue
        run: |
          # Update load balancer to point to blue environment
          aws elbv2 modify-listener \
            --listener-arn ${{ secrets.ALB_LISTENER_ARN }} \
            --default-actions Type=forward,TargetGroupArn=${{ secrets.BLUE_TARGET_GROUP_ARN }}

      - name: Monitor deployment
        run: |
          # Monitor for 10 minutes
          for i in {1..20}; do
            curl -f https://myapp.com/health
            sleep 30
          done

      - name: Cleanup old Green environment
        run: |
          # Scale down green environment
          aws ecs update-service \
            --cluster production-cluster \
            --service backend-service-green \
            --desired-count 0

  # Post-deployment tasks
  post-deployment:
    name: Post-deployment Tasks
    runs-on: ubuntu-latest
    needs: deploy-production
    
    steps:
      - name: Update monitoring
        run: |
          # Update Datadog deployment tracking
          curl -X POST "https://api.datadoghq.com/api/v1/events" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${{ secrets.DATADOG_API_KEY }}" \
            -d '{
              "title": "Production Deployment",
              "text": "Version ${{ github.sha }} deployed to production",
              "priority": "normal",
              "tags": ["environment:production", "deployment"]
            }'

      - name: Notify stakeholders
        uses: 8398a7/action-slack@v3
        with:
          status: success
          channel: '#production'
          title: '🚀 Production Deployment Successful'
          message: 'Version ${{ github.sha }} has been deployed to production'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 🦊 GitLab CI Pipeline

### Complete GitLab CI Configuration
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test
  - build
  - security
  - deploy-staging
  - deploy-production

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  POSTGRES_DB: test_db
  POSTGRES_USER: test_user
  POSTGRES_PASSWORD: test_password
  REDIS_URL: redis://redis:6379/0

# Templates
.docker_template: &docker_template
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

.node_template: &node_template
  image: node:18-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - frontend/node_modules/

.python_template: &python_template
  image: python:3.11
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .cache/pip/

# Validation Stage
lint-code:
  <<: *node_template
  stage: validate
  script:
    - npm ci
    - npm run lint
    - npm run format:check
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_BRANCH == "develop"

lint-python:
  <<: *python_template
  stage: validate
  before_script:
    - pip install -r requirements-dev.txt
  script:
    - black --check .
    - isort --check-only .
    - flake8 .
    - mypy .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_BRANCH == "develop"

# Test Stage
test-frontend:
  <<: *node_template
  stage: test
  services:
    - name: redis:7-alpine
      alias: redis
  script:
    - cd frontend
    - npm ci
    - npm run test:coverage
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: frontend/coverage/cobertura-coverage.xml
    paths:
      - frontend/coverage/
    expire_in: 1 week

test-backend:
  <<: *python_template
  stage: test
  services:
    - name: postgres:15
      alias: postgres
    - name: redis:7-alpine
      alias: redis
  variables:
    DATABASE_URL: postgresql://test_user:test_password@postgres:5432/test_db
  before_script:
    - pip install -r requirements-dev.txt
  script:
    - pytest --cov=app --cov-report=xml --cov-report=html
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
      junit: pytest-report.xml
    paths:
      - htmlcov/
    expire_in: 1 week

test-e2e:
  image: mcr.microsoft.com/playwright:v1.40.0-focal
  stage: test
  needs: ["test-frontend", "test-backend"]
  services:
    - name: postgres:15
      alias: postgres
    - name: redis:7-alpine
      alias: redis
  variables:
    DATABASE_URL: postgresql://test_user:test_password@postgres:5432/test_db
  script:
    - npm ci
    - npm run build
    - npm run start &
    - npx wait-on http://localhost:3000
    - npx playwright test
  artifacts:
    when: on_failure
    paths:
      - playwright-report/
    expire_in: 1 week

# Build Stage
build-images:
  <<: *docker_template
  stage: build
  needs: ["test-frontend", "test-backend"]
  script:
    - docker build -t $IMAGE_TAG-backend -f docker/production/Dockerfile .
    - docker build -t $IMAGE_TAG-frontend -f frontend/docker/production/Dockerfile ./frontend
    - docker push $IMAGE_TAG-backend
    - docker push $IMAGE_TAG-frontend
  only:
    - main
    - develop
    - tags

# Security Stage
security-scan:
  image: aquasec/trivy:latest
  stage: security
  needs: ["build-images"]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_TAG-backend
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_TAG-frontend
  allow_failure: false
  only:
    - main
    - develop
    - tags

# Staging Deployment
deploy-staging:
  image: alpine/k8s:1.28.4
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.myapp.com
  needs: ["security-scan"]
  before_script:
    - echo $KUBECONFIG_STAGING | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
  script:
    - sed -i "s|IMAGE_TAG|$IMAGE_TAG|g" k8s/staging/*.yaml
    - kubectl apply -f k8s/staging/
    - kubectl rollout status deployment/backend-deployment -n staging
    - kubectl rollout status deployment/frontend-deployment -n staging
  after_script:
    - rm -f kubeconfig
  only:
    - develop

# Production Deployment
deploy-production:
  image: alpine/k8s:1.28.4
  stage: deploy-production
  environment:
    name: production
    url: https://myapp.com
  needs: ["security-scan"]
  when: manual
  before_script:
    - echo $KUBECONFIG_PRODUCTION | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
  script:
    - sed -i "s|IMAGE_TAG|$IMAGE_TAG|g" k8s/production/*.yaml
    - kubectl apply -f k8s/production/
    - kubectl rollout status deployment/backend-deployment -n production
    - kubectl rollout status deployment/frontend-deployment -n production
  after_script:
    - rm -f kubeconfig
  only:
    - main
    - tags
```

## 🚀 Advanced Pipeline Patterns

### Matrix Strategy for Multi-Environment Testing
```yaml
# .github/workflows/matrix-test.yml
name: Matrix Testing

on: [push, pull_request]

jobs:
  test:
    name: Test (${{ matrix.os }}, Node ${{ matrix.node }}, Python ${{ matrix.python }})
    runs-on: ${{ matrix.os }}
    
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: ['16', '18', '20']
        python: ['3.9', '3.10', '3.11']
        exclude:
          # Exclude specific combinations to reduce build time
          - os: windows-latest
            python: '3.9'
          - os: macos-latest
            python: '3.9'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js ${{ matrix.node }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'
      
      - name: Setup Python ${{ matrix.python }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          npm ci
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: |
          npm test
          pytest
```

### Conditional Deployment Pipeline
```yaml
# .github/workflows/conditional-deploy.yml
name: Conditional Deployment

on:
  push:
    branches: [main, develop, 'release/*', 'hotfix/*']

jobs:
  determine-environment:
    name: Determine Target Environment
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.env.outputs.environment }}
      should-deploy: ${{ steps.env.outputs.should-deploy }}
    
    steps:
      - name: Determine environment
        id: env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" =~ refs/heads/release/.* ]]; then
            echo "environment=pre-production" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" =~ refs/heads/hotfix/.* ]]; then
            echo "environment=hotfix" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          else
            echo "environment=none" >> $GITHUB_OUTPUT
            echo "should-deploy=false" >> $GITHUB_OUTPUT
          fi

  deploy:
    name: Deploy to ${{ needs.determine-environment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: determine-environment
    if: needs.determine-environment.outputs.should-deploy == 'true'
    environment: ${{ needs.determine-environment.outputs.environment }}
    
    steps:
      - name: Deploy
        run: |
          echo "Deploying to ${{ needs.determine-environment.outputs.environment }}"
          # Deployment logic here
```

### Parallel Testing Pipeline
```yaml
# .github/workflows/parallel-test.yml
name: Parallel Testing

on: [push, pull_request]

jobs:
  # Split tests into parallel jobs
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm run test:unit

  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm run test:integration

  e2e-tests:
    name: E2E Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        browser: [chromium, firefox, webkit]
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps ${{ matrix.browser }}
      - run: npx playwright test --browser=${{ matrix.browser }}

  # Wait for all test jobs to complete
  all-tests:
    name: All Tests Complete
    runs-on: ubuntu-latest
    needs: [unit-tests, integration-tests, e2e-tests]
    steps:
      - run: echo "All tests passed!"
```

## 🔒 Security-First Pipeline

### Security Scanning Pipeline
```yaml
# .github/workflows/security.yml
name: Security Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM

jobs:
  dependency-scan:
    name: Dependency Vulnerability Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Run npm audit
        run: npm audit --audit-level high

      - name: Python dependency check
        run: |
          pip install safety
          safety check --json

  code-scan:
    name: Static Code Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

      - name: CodeQL Analysis
        uses: github/codeql-action/init@v3
        with:
          languages: javascript, python

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3

  secret-scan:
    name: Secret Detection
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Run TruffleHog
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
          head: HEAD

  docker-scan:
    name: Docker Image Security Scan
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t test-image .
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: test-image
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
```

## 📊 Performance & Monitoring Pipeline

### Performance Testing Pipeline
```yaml
# .github/workflows/performance.yml
name: Performance Testing

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    name: Lighthouse Performance Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
      
      - name: Start application
        run: |
          npm run start &
          sleep 30
      
      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli@0.12.x
          lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}

  load-test:
    name: Load Testing
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup application
        run: |
          docker-compose -f docker-compose.test.yml up -d
          sleep 60
      
      - name: Run K6 load tests
        uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/load/basic-load-test.js
        env:
          K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
      
      - name: Cleanup
        run: docker-compose -f docker-compose.test.yml down

  bundle-analysis:
    name: Bundle Size Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Analyze bundle size
        run: |
          npm run build
          npx bundlesize
      
      - name: Upload bundle stats
        uses: actions/upload-artifact@v4
        with:
          name: bundle-stats
          path: dist/stats.json
```

## 🚀 Deployment Strategies

### Blue-Green Deployment Script
```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

# Configuration
CLUSTER_NAME="production-cluster"
SERVICE_NAME="backend-service"
BLUE_SERVICE="${SERVICE_NAME}-blue"
GREEN_SERVICE="${SERVICE_NAME}-green"
LOAD_BALANCER_ARN="$1"
NEW_IMAGE="$2"

echo "🚀 Starting Blue-Green Deployment"
echo "New Image: $NEW_IMAGE"

# Function to get current active environment
get_active_environment() {
    aws elbv2 describe-target-groups \
        --load-balancer-arn "$LOAD_BALANCER_ARN" \
        --query 'TargetGroups[0].TargetGroupName' \
        --output text | grep -o 'blue\|green'
}

# Function to health check
health_check() {
    local url="$1"
    local max_attempts=20
    local attempt=1
    
    echo "🏥 Running health checks on $url"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url/health" > /dev/null; then
            echo "✅ Health check passed (attempt $attempt)"
            return 0
        fi
        echo "⏳ Health check failed, attempt $attempt/$max_attempts"
        sleep 15
        ((attempt++))
    done
    
    echo "❌ Health checks failed after $max_attempts attempts"
    return 1
}

# Get current active environment
CURRENT_ENV=$(get_active_environment)
echo "Current active environment: $CURRENT_ENV"

# Determine target environment
if [ "$CURRENT_ENV" = "blue" ]; then
    TARGET_ENV="green"
    TARGET_SERVICE="$GREEN_SERVICE"
    TARGET_URL="https://green.myapp.com"
else
    TARGET_ENV="blue"
    TARGET_SERVICE="$BLUE_SERVICE"
    TARGET_URL="https://blue.myapp.com"
fi

echo "Deploying to: $TARGET_ENV"

# Create new task definition
echo "📝 Creating new task definition"
NEW_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition "$SERVICE_NAME" \
    --query 'taskDefinition' \
    --output json | \
    jq --arg IMAGE "$NEW_IMAGE" '.containerDefinitions[0].image = $IMAGE' | \
    jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)')

TASK_DEFINITION_ARN=$(echo "$NEW_TASK_DEF" | aws ecs register-task-definition \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "New task definition: $TASK_DEFINITION_ARN"

# Update target service
echo "🔄 Updating $TARGET_SERVICE with new image"
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$TARGET_SERVICE" \
    --task-definition "$TASK_DEFINITION_ARN" \
    --force-new-deployment > /dev/null

# Wait for deployment to complete
echo "⏳ Waiting for deployment to stabilize"
aws ecs wait services-stable \
    --cluster "$CLUSTER_NAME" \
    --services "$TARGET_SERVICE"

# Run health checks
if health_check "$TARGET_URL"; then
    echo "✅ Health checks passed, switching traffic"
    
    # Switch traffic
    aws elbv2 modify-listener \
        --listener-arn "$LISTENER_ARN" \
        --default-actions Type=forward,TargetGroupArn="$TARGET_TG_ARN"
    
    echo "🎉 Blue-Green deployment completed successfully"
    echo "Active environment is now: $TARGET_ENV"
    
    # Scale down old environment after 10 minutes
    echo "⏳ Waiting 10 minutes before scaling down old environment"
    sleep 600
    
    OLD_SERVICE="${SERVICE_NAME}-${CURRENT_ENV}"
    echo "📉 Scaling down $OLD_SERVICE"
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$OLD_SERVICE" \
        --desired-count 0 > /dev/null
    
else
    echo "❌ Health checks failed, rolling back"
    
    # Rollback - scale down failed deployment
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$TARGET_SERVICE" \
        --desired-count 0 > /dev/null
    
    exit 1
fi
```

### Canary Deployment Pipeline
```yaml
# .github/workflows/canary-deploy.yml
name: Canary Deployment

on:
  push:
    branches: [main]

jobs:
  canary-deploy:
    name: Canary Deployment
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      # Phase 1: Deploy to 10% of traffic
      - name: Deploy Canary (10%)
        run: |
          ./scripts/canary-deploy.sh 10 ${{ github.sha }}

      - name: Monitor Canary (10%) for 10 minutes
        run: |
          ./scripts/monitor-canary.sh 600 # 10 minutes

      # Phase 2: Increase to 50% if metrics are good
      - name: Deploy Canary (50%)
        run: |
          ./scripts/canary-deploy.sh 50 ${{ github.sha }}

      - name: Monitor Canary (50%) for 15 minutes
        run: |
          ./scripts/monitor-canary.sh 900 # 15 minutes

      # Phase 3: Full deployment
      - name: Deploy to 100%
        run: |
          ./scripts/canary-deploy.sh 100 ${{ github.sha }}

      - name: Final monitoring
        run: |
          ./scripts/monitor-canary.sh 300 # 5 minutes
```

## 🛠️ Custom Actions

### Reusable Setup Action
```yaml
# .github/actions/setup-app/action.yml
name: 'Setup Application'
description: 'Setup Node.js, Python, and dependencies'

inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '18'
  python-version:
    description: 'Python version'
    required: false
    default: '3.11'
  cache-key:
    description: 'Cache key suffix'
    required: false
    default: 'default'

outputs:
  cache-hit:
    description: 'Whether cache was hit'
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ inputs.python-version }}
        cache: 'pip'

    - name: Cache dependencies
      id: cache
      uses: actions/cache@v3
      with:
        path: |
          node_modules
          ~/.cache/pip
        key: ${{ runner.os }}-deps-${{ inputs.cache-key }}-${{ hashFiles('package-lock.json', 'requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-deps-${{ inputs.cache-key }}-

    - name: Install Node.js dependencies
      if: steps.cache.outputs.cache-hit != 'true'
      shell: bash
      run: npm ci

    - name: Install Python dependencies
      if: steps.cache.outputs.cache-hit != 'true'
      shell: bash
      run: pip install -r requirements.txt
```

### Deployment Action
```yaml
# .github/actions/deploy/action.yml
name: 'Deploy Application'
description: 'Deploy application to specified environment'

inputs:
  environment:
    description: 'Target environment'
    required: true
  image-tag:
    description: 'Docker image tag'
    required: true
  aws-region:
    description: 'AWS region'
    required: false
    default: 'us-east-1'

runs:
  using: 'composite'
  steps:
    - name: Deploy to ECS
      shell: bash
      run: |
        aws ecs update-service \
          --cluster ${{ inputs.environment }}-cluster \
          --service backend-service \
          --task-definition backend-task:${{ inputs.image-tag }} \
          --force-new-deployment

    - name: Wait for deployment
      shell: bash
      run: |
        aws ecs wait services-stable \
          --cluster ${{ inputs.environment }}-cluster \
          --services backend-service

    - name: Run health checks
      shell: bash
      run: |
        curl -f https://${{ inputs.environment }}.myapp.com/health
```

## 📊 Monitoring & Observability

### Pipeline Monitoring
```yaml
# .github/workflows/pipeline-metrics.yml
name: Pipeline Metrics

on:
  workflow_run:
    workflows: ["CI Pipeline", "Deploy to Production"]
    types: [completed]

jobs:
  collect-metrics:
    name: Collect Pipeline Metrics
    runs-on: ubuntu-latest
    steps:
      - name: Collect metrics
        run: |
          # Send pipeline metrics to monitoring system
          curl -X POST ${{ secrets.METRICS_ENDPOINT }} \
            -H "Content-Type: application/json" \
            -d '{
              "pipeline": "${{ github.workflow }}",
              "status": "${{ github.event.workflow_run.conclusion }}",
              "duration": "${{ github.event.workflow_run.run_attempt }}",
              "branch": "${{ github.event.workflow_run.head_branch }}",
              "commit": "${{ github.event.workflow_run.head_sha }}",
              "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
            }'

      - name: Update deployment dashboard
        if: github.event.workflow_run.conclusion == 'success'
        run: |
          # Update Grafana dashboard or similar
          echo "Updating deployment dashboard"
```

## 🛠️ Best Practices Summary

### 1. Pipeline Design
- **Fast Feedback**: Fail fast with quick validation jobs
- **Parallel Execution**: Run independent jobs in parallel
- **Conditional Logic**: Only run necessary jobs based on changes
- **Resource Optimization**: Use appropriate runners and caching

### 2. Security
- **Secret Management**: Use secure secret storage
- **Least Privilege**: Minimal permissions for CI/CD
- **Vulnerability Scanning**: Regular security scans
- **Code Signing**: Sign artifacts and images

### 3. Testing Strategy
- **Test Pyramid**: Unit → Integration → E2E
- **Environment Parity**: Test in production-like environments
- **Data Management**: Use clean test data
- **Flaky Test Handling**: Retry logic and monitoring

### 4. Deployment
- **Blue-Green/Canary**: Zero-downtime deployments
- **Rollback Strategy**: Quick rollback capabilities
- **Health Checks**: Comprehensive health monitoring
- **Feature Flags**: Progressive feature rollouts

### 5. Monitoring
- **Pipeline Metrics**: Track build and deployment metrics
- **Alerting**: Notify on failures and anomalies
- **Observability**: Full traceability of deployments
- **Performance**: Monitor deployment performance impact

---

*CI/CD pipelines are the backbone of modern software delivery. Proper implementation ensures fast, reliable, and secure deployments while maintaining high code quality.*
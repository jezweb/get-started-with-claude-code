# CI/CD Patterns and Automation

Comprehensive guide to implementing continuous integration and continuous deployment pipelines using GitHub Actions, GitLab CI, Jenkins, and modern deployment strategies.

## 🎯 CI/CD Overview

Modern CI/CD practices enable:
- **Automated Testing** - Run tests on every commit
- **Code Quality** - Enforce standards automatically
- **Continuous Deployment** - Ship features rapidly
- **Environment Management** - Dev, staging, production
- **Rollback Strategies** - Quick recovery from issues
- **Monitoring Integration** - Deployment tracking

## 🚀 GitHub Actions

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
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npm run lint
      
      - name: Run Prettier check
        run: npm run format:check

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint
    
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
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  build:
    name: Build Application
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            dist/
            package.json
            package-lock.json
          retention-days: 7

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Run npm audit
        run: npm audit --production
```

### Advanced Deployment Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy Pipeline

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    uses: ./.github/workflows/ci.yml
    secrets: inherit

  build-docker:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: test
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Docker Hub
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
            type=semver,pattern={{version}}
            type=sha,prefix={{branch}}-
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            BUILD_VERSION=${{ github.sha }}
            BUILD_DATE=${{ github.event.head_commit.timestamp }}

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build-docker
    if: github.event_name == 'push' || github.event.inputs.environment == 'staging'
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Kubernetes
        uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s/staging/
          images: |
            myapp/backend:${{ needs.build-docker.outputs.image-tag }}
          imagepullsecrets: |
            docker-registry
          kubeconfig: ${{ secrets.KUBECONFIG_STAGING }}
      
      - name: Wait for deployment
        run: |
          kubectl rollout status deployment/backend -n staging
          kubectl wait --for=condition=ready pod -l app=backend -n staging --timeout=300s
      
      - name: Run smoke tests
        run: |
          npm run test:smoke -- --url https://staging.example.com

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [build-docker, deploy-staging]
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'production'
    environment:
      name: production
      url: https://example.com
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Create deployment
        uses: chrnorm/deployment-action@v2
        id: deployment
        with:
          token: ${{ github.token }}
          environment: production
          ref: ${{ github.sha }}
      
      - name: Deploy to production
        run: |
          # Blue-green deployment
          ./scripts/deploy-blue-green.sh \
            --image myapp/backend:${{ needs.build-docker.outputs.image-tag }} \
            --environment production
      
      - name: Update deployment status
        if: always()
        uses: chrnorm/deployment-status@v2
        with:
          token: ${{ github.token }}
          deployment-id: ${{ steps.deployment.outputs.deployment_id }}
          state: ${{ job.status }}
          environment-url: https://example.com
```

### Matrix Testing

```yaml
# .github/workflows/matrix-test.yml
name: Matrix Testing

on: [push, pull_request]

jobs:
  test:
    name: Test ${{ matrix.os }} / Node ${{ matrix.node }} / Python ${{ matrix.python }}
    runs-on: ${{ matrix.os }}
    
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [16, 18, 20]
        python: ['3.9', '3.10', '3.11']
        exclude:
          - os: windows-latest
            python: '3.9'
        include:
          - os: ubuntu-latest
            node: 18
            python: '3.11'
            coverage: true
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python }}
      
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.npm
            ~/.cache/pip
          key: ${{ runner.os }}-node${{ matrix.node }}-python${{ matrix.python }}-${{ hashFiles('**/package-lock.json', '**/requirements.txt') }}
      
      - name: Install dependencies
        run: |
          npm ci
          pip install -r requirements.txt
      
      - name: Run tests
        run: |
          npm test
          pytest
      
      - name: Upload coverage
        if: matrix.coverage
        uses: codecov/codecov-action@v3
```

## 🦊 GitLab CI/CD

### Complete Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - security
  - deploy
  - notify

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  FF_USE_FASTZIP: "true"
  ARTIFACT_COMPRESSION_LEVEL: "fastest"
  CACHE_COMPRESSION_LEVEL: "fastest"

.docker:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

.node:
  image: node:18-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline

# Build Stage
build:app:
  extends: .node
  stage: build
  script:
    - npm run build
    - npm run build:stats
  artifacts:
    paths:
      - dist/
      - build-stats.json
    expire_in: 1 week
    reports:
      webpack: build-stats.json

build:docker:
  extends: .docker
  stage: build
  script:
    - docker build 
      --cache-from $CI_REGISTRY_IMAGE:latest 
      --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA 
      --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop

# Test Stage
test:unit:
  extends: .node
  stage: test
  script:
    - npm run test:unit -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

test:integration:
  extends: .node
  stage: test
  services:
    - postgres:15
    - redis:7
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: "postgresql://test:test@postgres:5432/test"
    REDIS_URL: "redis://redis:6379"
  script:
    - npm run test:integration
  artifacts:
    reports:
      junit: junit-integration.xml

test:e2e:
  image: mcr.microsoft.com/playwright:focal
  stage: test
  script:
    - npm ci
    - npx playwright install
    - npm run test:e2e
  artifacts:
    when: always
    paths:
      - playwright-report/
      - test-results/
    expire_in: 1 week

# Security Stage
security:sast:
  stage: security
  include:
    - template: Security/SAST.gitlab-ci.yml

security:dependency:
  stage: security
  include:
    - template: Security/Dependency-Scanning.gitlab-ci.yml

security:secrets:
  stage: security
  include:
    - template: Security/Secret-Detection.gitlab-ci.yml

security:container:
  extends: .docker
  stage: security
  script:
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock 
      aquasec/trivy:latest image --exit-code 1 --no-progress 
      --severity CRITICAL,HIGH $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

# Deploy Stage
.deploy:
  image: bitnami/kubectl:latest
  before_script:
    - kubectl config set-cluster k8s --server="$KUBE_URL" --insecure-skip-tls-verify=true
    - kubectl config set-credentials admin --token="$KUBE_TOKEN"
    - kubectl config set-context default --cluster=k8s --user=admin
    - kubectl config use-context default

deploy:staging:
  extends: .deploy
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop:staging
  script:
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -n staging
    - kubectl rollout status deployment/app -n staging
  only:
    - develop

deploy:production:
  extends: .deploy
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -n production
    - kubectl rollout status deployment/app -n production
  only:
    - main
  when: manual

stop:staging:
  extends: .deploy
  stage: deploy
  environment:
    name: staging
    action: stop
  script:
    - kubectl scale deployment/app --replicas=0 -n staging
  when: manual

# Notify Stage
notify:slack:
  stage: notify
  image: curlimages/curl:latest
  script:
    - |
      if [ "$CI_PIPELINE_STATUS" = "success" ]; then
        STATUS_EMOJI=":white_check_mark:"
        STATUS_COLOR="good"
      else
        STATUS_EMOJI=":x:"
        STATUS_COLOR="danger"
      fi
      
      curl -X POST -H 'Content-type: application/json' 
        --data "{
          \"attachments\": [{
            \"color\": \"$STATUS_COLOR\",
            \"title\": \"Pipeline $CI_PIPELINE_STATUS\",
            \"text\": \"$STATUS_EMOJI Pipeline #$CI_PIPELINE_ID for $CI_PROJECT_NAME/$CI_COMMIT_REF_NAME\",
            \"fields\": [
              {\"title\": \"Commit\", \"value\": \"$CI_COMMIT_SHA\", \"short\": true},
              {\"title\": \"Author\", \"value\": \"$CI_COMMIT_AUTHOR\", \"short\": true}
            ]
          }]
        }" 
        $SLACK_WEBHOOK_URL
  when: always
  only:
    - main
    - develop
```

## 🔧 Jenkins Pipeline

### Declarative Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: node
                    image: node:18
                    command:
                    - sleep
                    args:
                    - 99d
                  - name: docker
                    image: docker:latest
                    command:
                    - sleep
                    args:
                    - 99d
                    volumeMounts:
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'myapp/backend'
        DOCKER_CREDENTIALS = credentials('docker-hub-credentials')
        SONAR_TOKEN = credentials('sonar-token')
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        timestamps()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_TAG = "${env.BRANCH_NAME}-${env.GIT_COMMIT_SHORT}-${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Quality Gates') {
            parallel {
                stage('Lint') {
                    steps {
                        container('node') {
                            sh 'npm ci'
                            sh 'npm run lint'
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        container('node') {
                            sh 'npm audit --production'
                            sh 'npm run security:check'
                        }
                    }
                }
                
                stage('SonarQube Analysis') {
                    steps {
                        container('node') {
                            withSonarQubeEnv('SonarQube') {
                                sh """
                                    npm run sonar-scanner \
                                        -Dsonar.projectKey=${env.JOB_NAME} \
                                        -Dsonar.sources=src \
                                        -Dsonar.tests=tests \
                                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                container('node') {
                    sh 'npm run test:ci'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage'
                    ])
                    junit 'test-results/**/*.xml'
                }
            }
        }
        
        stage('Build') {
            steps {
                container('node') {
                    sh 'npm run build'
                    archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                container('docker') {
                    script {
                        docker.build("${DOCKER_IMAGE}:${BUILD_TAG}")
                        docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS) {
                            docker.image("${DOCKER_IMAGE}:${BUILD_TAG}").push()
                            if (env.BRANCH_NAME == 'main') {
                                docker.image("${DOCKER_IMAGE}:${BUILD_TAG}").push('latest')
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def deploymentStage = input(
                        message: 'Deploy to which environment?',
                        parameters: [
                            choice(
                                name: 'ENVIRONMENT',
                                choices: ['staging', 'production'],
                                description: 'Select deployment environment'
                            )
                        ]
                    )
                    
                    build job: 'deploy-pipeline', parameters: [
                        string(name: 'IMAGE_TAG', value: "${BUILD_TAG}"),
                        string(name: 'ENVIRONMENT', value: deploymentStage)
                    ]
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
    }
}
```

## 🐳 Container Registry Integration

### Multi-Stage Docker Build

```dockerfile
# Dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine

RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Switch to non-root user
USER nodejs

EXPOSE 3000

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js
```

### Registry Management

```yaml
# .github/workflows/registry.yml
name: Container Registry

on:
  push:
    tags:
      - 'v*'

jobs:
  multi-registry:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Login to AWS ECR
        uses: aws-actions/amazon-ecr-login@v2
        with:
          region: us-east-1
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: |
            myapp/backend
            ghcr.io/${{ github.repository }}
            ${{ secrets.AWS_ECR_REGISTRY }}/myapp
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=myapp/backend:buildcache
          cache-to: type=registry,ref=myapp/backend:buildcache,mode=max
```

## 🚢 Deployment Strategies

### Blue-Green Deployment

```bash
#!/bin/bash
# scripts/deploy-blue-green.sh

set -e

ENVIRONMENT=$1
NEW_VERSION=$2
NAMESPACE="production"

echo "Starting blue-green deployment..."

# Get current active color
CURRENT_COLOR=$(kubectl get service app -n $NAMESPACE -o jsonpath='{.spec.selector.color}')
NEW_COLOR=$([ "$CURRENT_COLOR" = "blue" ] && echo "green" || echo "blue")

echo "Current: $CURRENT_COLOR, Deploying to: $NEW_COLOR"

# Deploy new version
kubectl set image deployment/app-$NEW_COLOR app=$NEW_VERSION -n $NAMESPACE
kubectl rollout status deployment/app-$NEW_COLOR -n $NAMESPACE

# Run health checks
for i in {1..30}; do
  if curl -f http://app-$NEW_COLOR.$NAMESPACE.svc.cluster.local/health; then
    echo "Health check passed"
    break
  fi
  echo "Waiting for health check... ($i/30)"
  sleep 10
done

# Switch traffic
kubectl patch service app -n $NAMESPACE -p '{"spec":{"selector":{"color":"'$NEW_COLOR'"}}}'

echo "Blue-green deployment completed. Active: $NEW_COLOR"
```

### Canary Deployment

```yaml
# k8s/canary-deployment.yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: app
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  service:
    port: 80
    targetPort: 3000
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s
    webhooks:
    - name: acceptance-test
      type: pre-rollout
      url: http://flagger-loadtester.test/
      timeout: 30s
      metadata:
        type: bash
        cmd: "curl -sd 'test' http://app-canary.production/test | grep success"
    - name: load-test
      type: rollout
      url: http://flagger-loadtester.test/
      metadata:
        cmd: "hey -z 2m -q 10 -c 2 http://app-canary.production/"
```

## 📊 Monitoring and Rollback

### Deployment Monitoring

```yaml
# .github/workflows/monitor-deployment.yml
name: Monitor Deployment

on:
  deployment_status:

jobs:
  monitor:
    if: github.event.deployment_status.state == 'success'
    runs-on: ubuntu-latest
    steps:
      - name: Wait for stability
        run: sleep 300  # 5 minutes
      
      - name: Check application health
        id: health
        run: |
          HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://example.com/health)
          echo "status=$HEALTH_STATUS" >> $GITHUB_OUTPUT
      
      - name: Check error rate
        id: errors
        run: |
          ERROR_RATE=$(curl -s "https://api.monitoring.com/metrics/error_rate?app=myapp&duration=5m")
          echo "rate=$ERROR_RATE" >> $GITHUB_OUTPUT
      
      - name: Rollback if unhealthy
        if: steps.health.outputs.status != '200' || steps.errors.outputs.rate > 5
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.repos.createDeploymentStatus({
              owner: context.repo.owner,
              repo: context.repo.repo,
              deployment_id: context.payload.deployment.id,
              state: 'failure',
              description: 'Automated rollback due to health check failure'
            });
            
            // Trigger rollback workflow
            github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'rollback.yml',
              ref: 'main',
              inputs: {
                deployment_id: context.payload.deployment.id
              }
            });
```

## 🔑 Secrets Management

### HashiCorp Vault Integration

```yaml
# GitHub Actions with Vault
- name: Import Secrets
  uses: hashicorp/vault-action@v2
  with:
    url: ${{ secrets.VAULT_ADDR }}
    method: jwt
    role: github-actions
    secrets: |
      secret/data/app database_url | DATABASE_URL ;
      secret/data/app api_key | API_KEY ;
      secret/data/app jwt_secret | JWT_SECRET

# GitLab CI with Vault
vault:secrets:
  image: vault:latest
  stage: .pre
  script:
    - export VAULT_TOKEN=$(vault write -field=token auth/jwt/login role=gitlab-ci jwt=$CI_JOB_JWT)
    - export DATABASE_URL=$(vault kv get -field=database_url secret/app)
    - export API_KEY=$(vault kv get -field=api_key secret/app)
    - echo "DATABASE_URL=$DATABASE_URL" >> .env
    - echo "API_KEY=$API_KEY" >> .env
  artifacts:
    reports:
      dotenv: .env
```

## 🎯 Best Practices

### Pipeline as Code

```yaml
# .github/workflows/reusable.yml
name: Reusable Workflow

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      version:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy
        env:
          DEPLOY_KEY: ${{ secrets.deploy_key }}
        run: |
          ./deploy.sh --env ${{ inputs.environment }} --version ${{ inputs.version }}
```

### Branch Protection

```yaml
# .github/branch-protection.yml
protection_rules:
  - name: main
    required_status_checks:
      strict: true
      contexts:
        - continuous-integration/jenkins
        - security/snyk
        - test/unit
        - test/integration
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
    restrictions:
      users: []
      teams:
        - devops
```

---

*CI/CD pipelines automate the path from code to production. Focus on fast feedback, comprehensive testing, and safe deployment strategies to deliver value continuously.*
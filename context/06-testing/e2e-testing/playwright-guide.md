# End-to-End Testing with Playwright

Comprehensive guide to E2E testing using Playwright, covering browser automation, user journey testing, and cross-browser compatibility.

## 🎯 What is E2E Testing?

End-to-End testing validates complete user workflows from the user's perspective, testing:
- **User journeys** - Complete flows from start to finish
- **Browser interactions** - Real browser behavior
- **Cross-browser compatibility** - Multiple browser engines
- **Visual regression** - UI consistency across changes

## 🚀 Quick Start

### Installation
```bash
# Initialize Playwright project
npm init playwright@latest

# Or add to existing project
npm install -D @playwright/test
npx playwright install
```

### Basic Configuration
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['junit', { outputFile: 'test-results/junit.xml' }]
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

## 📁 Project Structure

```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   ├── registration.spec.ts
│   │   └── password-reset.spec.ts
│   ├── user-flows/
│   │   ├── onboarding.spec.ts
│   │   ├── shopping-cart.spec.ts
│   │   └── checkout.spec.ts
│   ├── admin/
│   │   ├── user-management.spec.ts
│   │   └── analytics.spec.ts
│   └── fixtures/
│       ├── test-data.ts
│       └── page-objects/
├── visual/
│   └── screenshots.spec.ts
└── utils/
    ├── auth-helpers.ts
    └── test-helpers.ts
```

## 🧪 Basic Test Patterns

### Simple Page Interaction
```typescript
// tests/e2e/auth/login.spec.ts
import { test, expect } from '@playwright/test'

test.describe('User Login', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
  })

  test('should login with valid credentials', async ({ page }) => {
    // Fill login form
    await page.fill('[data-testid="email-input"]', 'user@example.com')
    await page.fill('[data-testid="password-input"]', 'password123')
    
    // Submit form
    await page.click('[data-testid="login-button"]')
    
    // Verify successful login
    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible()
    await expect(page.locator('text=Welcome back')).toBeVisible()
  })

  test('should show error for invalid credentials', async ({ page }) => {
    await page.fill('[data-testid="email-input"]', 'user@example.com')
    await page.fill('[data-testid="password-input"]', 'wrongpassword')
    await page.click('[data-testid="login-button"]')
    
    // Verify error message
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible()
    await expect(page.locator('text=Invalid credentials')).toBeVisible()
    
    // Verify still on login page
    await expect(page).toHaveURL('/login')
  })

  test('should validate required fields', async ({ page }) => {
    // Try to submit empty form
    await page.click('[data-testid="login-button"]')
    
    // Check validation messages
    await expect(page.locator('text=Email is required')).toBeVisible()
    await expect(page.locator('text=Password is required')).toBeVisible()
  })
})
```

### Complex User Journey
```typescript
// tests/e2e/user-flows/shopping-cart.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Shopping Cart Flow', () => {
  test('complete purchase journey', async ({ page }) => {
    // 1. Browse products
    await page.goto('/products')
    await expect(page.locator('[data-testid="product-grid"]')).toBeVisible()
    
    // 2. Add items to cart
    const firstProduct = page.locator('[data-testid="product-card"]').first()
    await firstProduct.click()
    
    await expect(page.locator('[data-testid="product-details"]')).toBeVisible()
    await page.selectOption('[data-testid="size-select"]', 'Medium')
    await page.fill('[data-testid="quantity-input"]', '2')
    await page.click('[data-testid="add-to-cart"]')
    
    // Verify cart update
    await expect(page.locator('[data-testid="cart-count"]')).toHaveText('2')
    await expect(page.locator('text=Added to cart')).toBeVisible()
    
    // 3. Go to cart
    await page.click('[data-testid="cart-icon"]')
    await expect(page).toHaveURL('/cart')
    
    // Verify cart contents
    const cartItems = page.locator('[data-testid="cart-item"]')
    await expect(cartItems).toHaveCount(1)
    await expect(cartItems.locator('[data-testid="quantity"]')).toHaveText('2')
    
    // 4. Proceed to checkout
    await page.click('[data-testid="checkout-button"]')
    await expect(page).toHaveURL('/checkout')
    
    // 5. Fill shipping information
    await page.fill('[data-testid="first-name"]', 'John')
    await page.fill('[data-testid="last-name"]', 'Doe')
    await page.fill('[data-testid="email"]', 'john@example.com')
    await page.fill('[data-testid="address"]', '123 Main St')
    await page.fill('[data-testid="city"]', 'New York')
    await page.fill('[data-testid="postal-code"]', '10001')
    await page.selectOption('[data-testid="country"]', 'US')
    
    await page.click('[data-testid="continue-payment"]')
    
    // 6. Payment (mock payment)
    await page.fill('[data-testid="card-number"]', '4242424242424242')
    await page.fill('[data-testid="card-expiry"]', '12/25')
    await page.fill('[data-testid="card-cvc"]', '123')
    await page.fill('[data-testid="card-name"]', 'John Doe')
    
    // 7. Complete order
    await page.click('[data-testid="place-order"]')
    
    // 8. Verify order confirmation
    await expect(page).toHaveURL(/\/order\/\d+/)
    await expect(page.locator('text=Order confirmed')).toBeVisible()
    await expect(page.locator('[data-testid="order-number"]')).toBeVisible()
    
    // Verify cart is empty
    await page.click('[data-testid="cart-icon"]')
    await expect(page.locator('text=Your cart is empty')).toBeVisible()
  })
})
```

## 🔄 Page Object Model

### Page Object Pattern
```typescript
// tests/fixtures/page-objects/LoginPage.ts
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly loginButton: Locator
  readonly errorMessage: Locator
  readonly forgotPasswordLink: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.locator('[data-testid="email-input"]')
    this.passwordInput = page.locator('[data-testid="password-input"]')
    this.loginButton = page.locator('[data-testid="login-button"]')
    this.errorMessage = page.locator('[data-testid="error-message"]')
    this.forgotPasswordLink = page.locator('[data-testid="forgot-password"]')
  }

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.loginButton.click()
  }

  async loginWithValidCredentials() {
    await this.login('user@example.com', 'password123')
  }

  async expectErrorMessage(message: string) {
    await this.errorMessage.waitFor()
    await this.page.locator(`text=${message}`).waitFor()
  }

  async clickForgotPassword() {
    await this.forgotPasswordLink.click()
  }
}

// tests/fixtures/page-objects/DashboardPage.ts
export class DashboardPage {
  readonly page: Page
  readonly userMenu: Locator
  readonly welcomeMessage: Locator
  readonly navigationMenu: Locator

  constructor(page: Page) {
    this.page = page
    this.userMenu = page.locator('[data-testid="user-menu"]')
    this.welcomeMessage = page.locator('[data-testid="welcome-message"]')
    this.navigationMenu = page.locator('[data-testid="nav-menu"]')
  }

  async expectToBeVisible() {
    await this.userMenu.waitFor()
    await this.welcomeMessage.waitFor()
  }

  async navigateTo(section: string) {
    await this.navigationMenu.locator(`text=${section}`).click()
  }

  async logout() {
    await this.userMenu.click()
    await this.page.locator('[data-testid="logout-button"]').click()
  }
}

// Using Page Objects in tests
test('login flow with page objects', async ({ page }) => {
  const loginPage = new LoginPage(page)
  const dashboardPage = new DashboardPage(page)

  await loginPage.goto()
  await loginPage.loginWithValidCredentials()
  await dashboardPage.expectToBeVisible()
})
```

### Base Page Class
```typescript
// tests/fixtures/page-objects/BasePage.ts
export class BasePage {
  readonly page: Page

  constructor(page: Page) {
    this.page = page
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle')
  }

  async takeScreenshot(name: string) {
    await this.page.screenshot({ path: `screenshots/${name}.png` })
  }

  async scrollToElement(locator: Locator) {
    await locator.scrollIntoViewIfNeeded()
  }

  async waitForElement(locator: Locator, timeout = 5000) {
    await locator.waitFor({ timeout })
  }

  async clickAndWait(locator: Locator, waitForSelector?: string) {
    await locator.click()
    if (waitForSelector) {
      await this.page.waitForSelector(waitForSelector)
    }
  }
}
```

## 🎭 Advanced Interactions

### File Upload Testing
```typescript
test('file upload functionality', async ({ page }) => {
  await page.goto('/upload')
  
  // Upload single file
  const fileInput = page.locator('[data-testid="file-input"]')
  await fileInput.setInputFiles('tests/fixtures/test-image.jpg')
  
  // Verify file preview
  await expect(page.locator('[data-testid="file-preview"]')).toBeVisible()
  
  // Upload multiple files
  await fileInput.setInputFiles([
    'tests/fixtures/file1.pdf',
    'tests/fixtures/file2.pdf'
  ])
  
  // Submit upload
  await page.click('[data-testid="upload-button"]')
  await expect(page.locator('text=Files uploaded successfully')).toBeVisible()
})
```

### Drag and Drop
```typescript
test('drag and drop functionality', async ({ page }) => {
  await page.goto('/kanban')
  
  // Drag task from one column to another
  const sourceTask = page.locator('[data-testid="task-1"]')
  const targetColumn = page.locator('[data-testid="column-done"]')
  
  await sourceTask.dragTo(targetColumn)
  
  // Verify task moved
  await expect(targetColumn.locator('[data-testid="task-1"]')).toBeVisible()
  
  // Alternative drag and drop method
  const sourceBox = await sourceTask.boundingBox()
  const targetBox = await targetColumn.boundingBox()
  
  if (sourceBox && targetBox) {
    await page.mouse.move(sourceBox.x + sourceBox.width / 2, sourceBox.y + sourceBox.height / 2)
    await page.mouse.down()
    await page.mouse.move(targetBox.x + targetBox.width / 2, targetBox.y + targetBox.height / 2)
    await page.mouse.up()
  }
})
```

### Keyboard Shortcuts
```typescript
test('keyboard navigation', async ({ page }) => {
  await page.goto('/editor')
  
  // Focus text editor
  await page.click('[data-testid="text-editor"]')
  
  // Type content
  await page.keyboard.type('Hello World')
  
  // Use keyboard shortcuts
  await page.keyboard.press('Control+A')  // Select all
  await page.keyboard.press('Control+B')  // Bold
  
  // Verify formatting applied
  await expect(page.locator('[data-testid="text-editor"] strong')).toHaveText('Hello World')
  
  // Save with keyboard
  await page.keyboard.press('Control+S')
  await expect(page.locator('text=Saved')).toBeVisible()
})
```

## 🎨 Visual Testing

### Screenshot Comparison
```typescript
// tests/visual/screenshots.spec.ts
test('visual regression testing', async ({ page }) => {
  await page.goto('/homepage')
  
  // Full page screenshot
  await expect(page).toHaveScreenshot('homepage.png')
  
  // Element screenshot
  const header = page.locator('[data-testid="header"]')
  await expect(header).toHaveScreenshot('header.png')
  
  // Screenshot with options
  await expect(page).toHaveScreenshot('homepage-mobile.png', {
    fullPage: true,
    animations: 'disabled'
  })
})

// Configure visual testing in playwright.config.ts
export default defineConfig({
  expect: {
    toHaveScreenshot: {
      threshold: 0.2,
      mode: 'strict'
    }
  },
  use: {
    // Disable animations for consistent screenshots
    reducedMotion: 'reduce'
  }
})
```

### Responsive Design Testing
```typescript
test('responsive design testing', async ({ page }) => {
  await page.goto('/dashboard')
  
  // Test different viewport sizes
  const viewports = [
    { width: 1920, height: 1080, name: 'desktop' },
    { width: 768, height: 1024, name: 'tablet' },
    { width: 375, height: 667, name: 'mobile' }
  ]
  
  for (const viewport of viewports) {
    await page.setViewportSize(viewport)
    await page.waitForTimeout(500) // Allow layout to settle
    
    // Take screenshot for each viewport
    await expect(page).toHaveScreenshot(`dashboard-${viewport.name}.png`)
    
    // Test specific responsive behavior
    if (viewport.name === 'mobile') {
      await expect(page.locator('[data-testid="mobile-menu-button"]')).toBeVisible()
      await expect(page.locator('[data-testid="desktop-menu"]')).not.toBeVisible()
    }
  }
})
```

## 🔐 Authentication & Setup

### Authentication Fixtures
```typescript
// tests/utils/auth-helpers.ts
import { Page } from '@playwright/test'

export async function authenticateUser(page: Page, userType = 'regular') {
  const credentials = {
    regular: { email: 'user@example.com', password: 'password123' },
    admin: { email: 'admin@example.com', password: 'admin123' },
    premium: { email: 'premium@example.com', password: 'premium123' }
  }

  const { email, password } = credentials[userType]

  await page.goto('/login')
  await page.fill('[data-testid="email-input"]', email)
  await page.fill('[data-testid="password-input"]', password)
  await page.click('[data-testid="login-button"]')
  
  // Wait for successful login
  await page.waitForURL('/dashboard')
}

export async function createUserAndLogin(page: Page, userData = {}) {
  const defaultUser = {
    email: `test${Date.now()}@example.com`,
    password: 'password123',
    name: 'Test User'
  }
  
  const user = { ...defaultUser, ...userData }
  
  // Register user
  await page.goto('/register')
  await page.fill('[data-testid="name-input"]', user.name)
  await page.fill('[data-testid="email-input"]', user.email)
  await page.fill('[data-testid="password-input"]', user.password)
  await page.click('[data-testid="register-button"]')
  
  // Login with new user
  await page.goto('/login')
  await page.fill('[data-testid="email-input"]', user.email)
  await page.fill('[data-testid="password-input"]', user.password)
  await page.click('[data-testid="login-button"]')
  
  return user
}

// Global setup for authentication
// tests/global-setup.ts
import { chromium, FullConfig } from '@playwright/test'
import { authenticateUser } from './utils/auth-helpers'

async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch()
  const page = await browser.newPage()
  
  // Authenticate and save state
  await authenticateUser(page, 'regular')
  await page.context().storageState({ path: 'auth-state.json' })
  
  await browser.close()
}

export default globalSetup
```

### Using Authentication State
```typescript
// playwright.config.ts - reference global setup
export default defineConfig({
  globalSetup: require.resolve('./tests/global-setup'),
  use: {
    storageState: 'auth-state.json'
  }
})

// Skip authentication for specific tests
test('public page access', async ({ page }) => {
  // This test will use stored auth state
  await page.goto('/dashboard')
  await expect(page.locator('[data-testid="user-menu"]')).toBeVisible()
})

test('login page without auth', async ({ browser }) => {
  // Create new context without auth state
  const context = await browser.newContext()
  const page = await context.newPage()
  
  await page.goto('/login')
  await expect(page.locator('[data-testid="login-form"]')).toBeVisible()
  
  await context.close()
})
```

## 🌐 API Mocking & Intercepts

### API Route Interception
```typescript
test('mock API responses', async ({ page }) => {
  // Mock successful API response
  await page.route('/api/users', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ])
    })
  })
  
  await page.goto('/users')
  await expect(page.locator('[data-testid="user-list"]')).toBeVisible()
  await expect(page.locator('[data-testid="user-item"]')).toHaveCount(2)
})

test('handle API errors', async ({ page }) => {
  // Mock API error
  await page.route('/api/users', async route => {
    await route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal server error' })
    })
  })
  
  await page.goto('/users')
  await expect(page.locator('[data-testid="error-message"]')).toBeVisible()
  await expect(page.locator('text=Failed to load users')).toBeVisible()
})

test('test loading states', async ({ page }) => {
  // Delay API response to test loading state
  await page.route('/api/users', async route => {
    await new Promise(resolve => setTimeout(resolve, 2000))
    await route.continue()
  })
  
  await page.goto('/users')
  
  // Verify loading state
  await expect(page.locator('[data-testid="loading-spinner"]')).toBeVisible()
  
  // Wait for data to load
  await expect(page.locator('[data-testid="user-list"]')).toBeVisible({ timeout: 10000 })
  await expect(page.locator('[data-testid="loading-spinner"]')).not.toBeVisible()
})
```

## 📱 Mobile & Cross-Browser Testing

### Mobile-Specific Testing
```typescript
// playwright.config.ts - mobile configuration
export default defineConfig({
  projects: [
    {
      name: 'Mobile Safari',
      use: {
        ...devices['iPhone 12'],
        // Additional mobile-specific settings
        hasTouch: true,
        isMobile: true
      }
    }
  ]
})

test('mobile navigation menu', async ({ page }) => {
  await page.goto('/dashboard')
  
  // Mobile menu should be collapsed by default
  await expect(page.locator('[data-testid="mobile-menu"]')).not.toBeVisible()
  
  // Tap hamburger menu
  await page.locator('[data-testid="menu-toggle"]').tap()
  await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible()
  
  // Test touch gestures
  const menuItem = page.locator('[data-testid="menu-item-settings"]')
  await menuItem.tap()
  await expect(page).toHaveURL('/settings')
})

test('swipe gestures', async ({ page }) => {
  await page.goto('/gallery')
  
  const gallery = page.locator('[data-testid="image-gallery"]')
  const firstImage = gallery.locator('[data-testid="image"]').first()
  
  // Get initial position
  const initialImage = await firstImage.textContent()
  
  // Swipe left (next image)
  await gallery.touchscreen.tap(200, 200)
  await page.touchscreen.tap(100, 200)
  
  // Verify image changed
  const newImage = await firstImage.textContent()
  expect(newImage).not.toBe(initialImage)
})
```

### Cross-Browser Testing
```typescript
test.describe('Cross-browser compatibility', () => {
  ['chromium', 'firefox', 'webkit'].forEach(browserName => {
    test(`form validation in ${browserName}`, async ({ page }) => {
      await page.goto('/contact')
      
      // Test form validation
      await page.click('[data-testid="submit-button"]')
      
      // Verify validation messages appear
      await expect(page.locator('[data-testid="email-error"]')).toBeVisible()
      await expect(page.locator('[data-testid="message-error"]')).toBeVisible()
      
      // Fill valid data
      await page.fill('[data-testid="email-input"]', 'test@example.com')
      await page.fill('[data-testid="message-input"]', 'Test message')
      await page.click('[data-testid="submit-button"]')
      
      await expect(page.locator('text=Message sent')).toBeVisible()
    })
  })
})
```

## 🔄 Parallel & Retries

### Test Configuration
```typescript
// playwright.config.ts
export default defineConfig({
  // Run tests in parallel
  fullyParallel: true,
  
  // Retry failed tests
  retries: process.env.CI ? 3 : 1,
  
  // Number of workers
  workers: process.env.CI ? 2 : '50%',
  
  // Test timeout
  timeout: 60000,
  
  // Expect timeout for assertions
  expect: {
    timeout: 10000
  }
})

// Test-specific configuration
test.describe.configure({ mode: 'parallel' })

test('flaky test with retries', async ({ page }) => {
  test.slow() // Mark as slow test
  
  await page.goto('/dashboard')
  
  // Test that might be flaky
  await expect(page.locator('[data-testid="live-data"]')).toBeVisible({ timeout: 15000 })
})
```

## 📊 Reporting & CI Integration

### Custom Reporters
```typescript
// playwright.config.ts
export default defineConfig({
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['json', { outputFile: 'test-results/results.json' }],
    // Custom reporter
    ['./reporters/slack-reporter.ts']
  ]
})

// reporters/slack-reporter.ts
import { Reporter, TestCase, TestResult, FullResult } from '@playwright/test/reporter'

class SlackReporter implements Reporter {
  onTestEnd(test: TestCase, result: TestResult) {
    if (result.status === 'failed') {
      // Send failure notification to Slack
      this.sendSlackNotification(test, result)
    }
  }

  onEnd(result: FullResult) {
    // Send summary to Slack
    this.sendSummary(result)
  }

  private async sendSlackNotification(test: TestCase, result: TestResult) {
    // Slack webhook implementation
  }
}

export default SlackReporter
```

### GitHub Actions Integration
```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: |
        npm ci
        npx playwright install --with-deps
    
    - name: Start application
      run: |
        npm run build
        npm run start &
        sleep 30
    
    - name: Run E2E tests
      run: npx playwright test
      env:
        CI: true
    
    - name: Upload test results
      if: failure()
      uses: actions/upload-artifact@v3
      with:
        name: playwright-report
        path: playwright-report/
    
    - name: Upload screenshots
      if: failure()
      uses: actions/upload-artifact@v3
      with:
        name: screenshots
        path: test-results/
```

## 🛠️ Best Practices

### 1. Reliable Selectors
```typescript
// Good - Use data attributes
await page.click('[data-testid="submit-button"]')

// Better - Use semantic selectors when possible
await page.click('button[type="submit"]')
await page.click('role=button[name="Submit"]')

// Avoid - CSS classes and complex selectors
await page.click('.btn.btn-primary.submit-btn') // ❌
await page.click('#main > div > form > button:nth-child(3)') // ❌
```

### 2. Wait Strategies
```typescript
// Wait for element to be visible
await page.locator('[data-testid="content"]').waitFor()

// Wait for network requests to complete
await page.waitForLoadState('networkidle')

// Wait for specific condition
await page.waitForFunction(() => window.dataLoaded === true)

// Auto-waiting assertions (preferred)
await expect(page.locator('[data-testid="result"]')).toBeVisible()
```

### 3. Test Independence
```typescript
// Each test should clean up after itself
test.afterEach(async ({ page }) => {
  // Clear any test data
  await page.evaluate(() => localStorage.clear())
  await page.evaluate(() => sessionStorage.clear())
})

// Use unique test data
test('user registration', async ({ page }) => {
  const uniqueEmail = `test-${Date.now()}@example.com`
  // Use uniqueEmail in test
})
```

### 4. Error Handling
```typescript
test('handle network failures gracefully', async ({ page }) => {
  // Simulate network failure
  await page.route('**/*', route => route.abort())
  
  await page.goto('/dashboard')
  
  // Verify offline state
  await expect(page.locator('[data-testid="offline-message"]')).toBeVisible()
})
```

## 🔗 Resources

- [Playwright Documentation](https://playwright.dev/)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Visual Testing Guide](https://playwright.dev/docs/test-screenshots)
- [CI/CD Integration](https://playwright.dev/docs/ci)

---

*E2E tests provide the highest confidence that your application works correctly from the user's perspective, but should be used judiciously as part of a balanced testing strategy.*
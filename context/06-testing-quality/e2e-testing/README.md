# End-to-End Testing Patterns

Comprehensive guide to end-to-end (E2E) testing strategies using Playwright, Cypress, and Selenium for testing complete user workflows and application behavior.

## 🎯 E2E Testing Overview

End-to-end testing validates complete user scenarios:
- **User Workflows** - Multi-step user journeys
- **Cross-Browser Testing** - Browser compatibility
- **Real Environment** - Production-like testing
- **Visual Testing** - UI appearance verification
- **Performance Testing** - Load time validation
- **Accessibility Testing** - WCAG compliance

## 🎭 Playwright Testing

### Playwright Setup

```bash
# Install Playwright
npm init playwright@latest

# Or add to existing project
npm install -D @playwright/test
npx playwright install  # Install browsers

# Install with specific browsers
npx playwright install chromium firefox webkit
```

### Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['json', { outputFile: 'test-results/results.json' }]
  ],
  
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15000,
    
    // Global test settings
    locale: 'en-US',
    timezoneId: 'America/New_York',
    
    // Emulate device metrics
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 1,
    hasTouch: false,
    
    // Network
    offline: false,
    httpCredentials: {
      username: process.env.HTTP_USERNAME || '',
      password: process.env.HTTP_PASSWORD || ''
    },
    
    // Browser options
    headless: !!process.env.CI,
    slowMo: process.env.SLOW_MO ? Number(process.env.SLOW_MO) : 0,
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
      name: 'mobile',
      use: { ...devices['iPhone 13'] },
    },
    {
      name: 'tablet',
      use: { ...devices['iPad Pro'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

### Page Object Model

```typescript
// e2e/pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('input[name="email"]');
    this.passwordInput = page.locator('input[name="password"]');
    this.submitButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator('[role="alert"]');
    this.forgotPasswordLink = page.locator('text=Forgot password?');
  }

  async goto() {
    await this.page.goto('/login');
    await this.page.waitForLoadState('networkidle');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await this.errorMessage.waitFor({ state: 'visible' });
    await expect(this.errorMessage).toContainText(message);
  }

  async expectRedirect(url: string) {
    await this.page.waitForURL(url);
  }
}

// e2e/pages/DashboardPage.ts
export class DashboardPage {
  readonly page: Page;
  readonly welcomeMessage: Locator;
  readonly userMenu: Locator;
  readonly logoutButton: Locator;
  readonly statsCards: Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeMessage = page.locator('h1:has-text("Welcome")');
    this.userMenu = page.locator('[data-testid="user-menu"]');
    this.logoutButton = page.locator('button:has-text("Logout")');
    this.statsCards = page.locator('[data-testid="stats-card"]');
  }

  async expectWelcomeMessage(name: string) {
    await expect(this.welcomeMessage).toContainText(`Welcome, ${name}`);
  }

  async logout() {
    await this.userMenu.click();
    await this.logoutButton.click();
  }

  async getStatValue(statName: string): Promise<string> {
    const card = this.statsCards.filter({ hasText: statName });
    const value = await card.locator('.stat-value').textContent();
    return value || '';
  }
}
```

### E2E Test Examples

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { generateUser } from './helpers/test-data';

test.describe('Authentication Flow', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
  });

  test('successful login redirects to dashboard', async ({ page }) => {
    await loginPage.goto();
    await loginPage.login('test@example.com', 'password123');
    
    await expect(page).toHaveURL('/dashboard');
    await dashboardPage.expectWelcomeMessage('Test User');
  });

  test('invalid credentials show error', async ({ page }) => {
    await loginPage.goto();
    await loginPage.login('wrong@example.com', 'wrongpass');
    
    await loginPage.expectError('Invalid email or password');
    await expect(page).toHaveURL('/login');
  });

  test('logout redirects to login', async ({ page, context }) => {
    // Set authentication cookie
    await context.addCookies([{
      name: 'auth-token',
      value: 'valid-token',
      domain: 'localhost',
      path: '/'
    }]);

    await page.goto('/dashboard');
    await dashboardPage.logout();
    
    await expect(page).toHaveURL('/login');
    
    // Verify cookie is cleared
    const cookies = await context.cookies();
    expect(cookies.find(c => c.name === 'auth-token')).toBeUndefined();
  });

  test('password reset flow', async ({ page }) => {
    await loginPage.goto();
    await loginPage.forgotPasswordLink.click();
    
    await expect(page).toHaveURL('/forgot-password');
    
    // Fill reset form
    await page.fill('input[name="email"]', 'test@example.com');
    await page.click('button[type="submit"]');
    
    // Verify success message
    await expect(page.locator('.success-message')).toContainText(
      'Password reset email sent'
    );
  });
});

// e2e/user-journey.spec.ts
test.describe('Complete User Journey', () => {
  test('new user registration and onboarding', async ({ page, request }) => {
    const user = generateUser();
    
    // 1. Register new account
    await page.goto('/register');
    await page.fill('input[name="email"]', user.email);
    await page.fill('input[name="password"]', user.password);
    await page.fill('input[name="confirmPassword"]', user.password);
    await page.click('button[type="submit"]');
    
    // 2. Verify email (simulate email click)
    const emailToken = await getEmailVerificationToken(user.email);
    await page.goto(`/verify-email?token=${emailToken}`);
    
    // 3. Complete profile
    await expect(page).toHaveURL('/onboarding/profile');
    await page.fill('input[name="firstName"]', user.firstName);
    await page.fill('input[name="lastName"]', user.lastName);
    await page.selectOption('select[name="role"]', 'developer');
    await page.click('button:has-text("Continue")');
    
    // 4. Tutorial
    await expect(page).toHaveURL('/onboarding/tutorial');
    const steps = page.locator('.tutorial-step');
    const stepCount = await steps.count();
    
    for (let i = 0; i < stepCount; i++) {
      await page.click('button:has-text("Next")');
    }
    
    // 5. Dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText(`Welcome, ${user.firstName}`);
    
    // Cleanup via API
    await request.delete(`/api/test/users/${user.email}`);
  });
});
```

### Advanced Playwright Features

```typescript
// e2e/advanced.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Advanced Features', () => {
  test('file upload and download', async ({ page }) => {
    await page.goto('/files');
    
    // Upload file
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles('test-data/sample.pdf');
    
    // Wait for upload
    await expect(page.locator('.upload-success')).toBeVisible();
    
    // Download file
    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("Download")');
    const download = await downloadPromise;
    
    // Verify download
    expect(download.suggestedFilename()).toBe('sample.pdf');
    const path = await download.path();
    expect(path).toBeTruthy();
  });

  test('drag and drop', async ({ page }) => {
    await page.goto('/kanban');
    
    const source = page.locator('.task-card:has-text("Task 1")');
    const target = page.locator('.column:has-text("In Progress")');
    
    await source.dragTo(target);
    
    // Verify task moved
    await expect(target.locator('.task-card:has-text("Task 1")')).toBeVisible();
  });

  test('keyboard shortcuts', async ({ page }) => {
    await page.goto('/editor');
    
    // Focus editor
    await page.click('.editor-content');
    
    // Test shortcuts
    await page.keyboard.press('Control+B');
    await page.keyboard.type('Bold text');
    
    await page.keyboard.press('Control+I');
    await page.keyboard.type('Italic text');
    
    // Verify formatting
    await expect(page.locator('strong')).toContainText('Bold text');
    await expect(page.locator('em')).toContainText('Italic text');
  });

  test('network interception', async ({ page }) => {
    // Mock API response
    await page.route('**/api/users', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 1, name: 'Mocked User 1' },
          { id: 2, name: 'Mocked User 2' }
        ])
      });
    });

    await page.goto('/users');
    
    // Verify mocked data is displayed
    await expect(page.locator('.user-card')).toHaveCount(2);
    await expect(page.locator('.user-card').first()).toContainText('Mocked User 1');
  });

  test('visual regression', async ({ page }) => {
    await page.goto('/home');
    
    // Take screenshot
    await expect(page).toHaveScreenshot('homepage.png', {
      fullPage: true,
      animations: 'disabled'
    });
    
    // Component screenshot
    const header = page.locator('header');
    await expect(header).toHaveScreenshot('header.png');
  });
});
```

## 🌲 Cypress Testing

### Cypress Setup

```bash
# Install Cypress
npm install -D cypress
npx cypress open

# TypeScript support
npm install -D @types/cypress
```

### Cypress Configuration

```javascript
// cypress.config.js
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true,
    
    setupNodeEvents(on, config) {
      // Task plugins
      on('task', {
        log(message) {
          console.log(message);
          return null;
        },
        clearDatabase() {
          // Database cleanup logic
          return null;
        }
      });
      
      // Code coverage
      require('@cypress/code-coverage/task')(on, config);
      
      return config;
    },
    
    env: {
      apiUrl: 'http://localhost:3001/api',
      coverage: true
    },
    
    experimentalStudio: true,
    experimentalSessionAndOrigin: true,
  },
  
  component: {
    devServer: {
      framework: 'react',
      bundler: 'vite',
    },
    specPattern: 'src/**/*.cy.{js,jsx,ts,tsx}',
  },
});
```

### Cypress Commands

```javascript
// cypress/support/commands.js
Cypress.Commands.add('login', (email, password) => {
  cy.session(
    [email, password],
    () => {
      cy.visit('/login');
      cy.get('input[name="email"]').type(email);
      cy.get('input[name="password"]').type(password);
      cy.get('button[type="submit"]').click();
      cy.url().should('include', '/dashboard');
    },
    {
      validate() {
        cy.getCookie('session').should('exist');
      },
    }
  );
});

Cypress.Commands.add('seedDatabase', (data) => {
  cy.task('clearDatabase');
  cy.request('POST', '/api/test/seed', data);
});

Cypress.Commands.add('interceptAPI', (method, url, fixture) => {
  cy.intercept(method, url, { fixture }).as(fixture);
});

// Type definitions
declare global {
  namespace Cypress {
    interface Chainable {
      login(email: string, password: string): Chainable<void>;
      seedDatabase(data: object): Chainable<void>;
      interceptAPI(method: string, url: string, fixture: string): Chainable<void>;
    }
  }
}
```

### Cypress Test Examples

```javascript
// cypress/e2e/shopping-cart.cy.js
describe('Shopping Cart', () => {
  beforeEach(() => {
    cy.seedDatabase({
      products: [
        { id: 1, name: 'Laptop', price: 999 },
        { id: 2, name: 'Mouse', price: 29 }
      ]
    });
    cy.login('user@example.com', 'password');
    cy.visit('/products');
  });

  it('adds products to cart', () => {
    // Add first product
    cy.contains('.product-card', 'Laptop')
      .find('button:contains("Add to Cart")')
      .click();

    // Verify cart badge
    cy.get('[data-cy=cart-badge]').should('contain', '1');

    // Add second product
    cy.contains('.product-card', 'Mouse')
      .find('button:contains("Add to Cart")')
      .click();

    cy.get('[data-cy=cart-badge]').should('contain', '2');

    // View cart
    cy.get('[data-cy=cart-icon]').click();
    cy.url().should('include', '/cart');

    // Verify cart contents
    cy.get('.cart-item').should('have.length', 2);
    cy.get('.cart-total').should('contain', '$1,028');
  });

  it('updates quantities', () => {
    cy.contains('.product-card', 'Laptop')
      .find('button:contains("Add to Cart")')
      .click();

    cy.visit('/cart');

    // Increase quantity
    cy.get('.quantity-input').clear().type('3');
    cy.get('.cart-total').should('contain', '$2,997');

    // Remove item
    cy.get('button:contains("Remove")').click();
    cy.get('.empty-cart').should('be.visible');
  });

  it('completes checkout', () => {
    // Add to cart
    cy.get('.add-to-cart-btn').first().click();
    cy.visit('/cart');
    cy.get('button:contains("Checkout")').click();

    // Fill shipping info
    cy.get('input[name="fullName"]').type('John Doe');
    cy.get('input[name="address"]').type('123 Main St');
    cy.get('input[name="city"]').type('New York');
    cy.get('input[name="zipCode"]').type('10001');
    cy.get('button:contains("Continue")').click();

    // Payment info
    cy.get('input[name="cardNumber"]').type('4242424242424242');
    cy.get('input[name="expiry"]').type('12/25');
    cy.get('input[name="cvv"]').type('123');
    
    // Complete order
    cy.get('button:contains("Place Order")').click();

    // Verify success
    cy.url().should('include', '/order-confirmation');
    cy.get('.order-number').should('be.visible');
  });
});
```

## 🔍 Visual Testing

### Percy Integration

```javascript
// Playwright with Percy
import { test } from '@playwright/test';
import percySnapshot from '@percy/playwright';

test('visual regression tests', async ({ page }) => {
  await page.goto('/');
  await percySnapshot(page, 'Homepage');

  await page.goto('/pricing');
  await percySnapshot(page, 'Pricing Page', {
    widths: [375, 768, 1280],
    minHeight: 1024
  });

  // Component snapshot
  await page.goto('/components');
  const button = page.locator('.primary-button');
  await percySnapshot(page, 'Primary Button', {
    scope: button
  });
});

// Cypress with Percy
describe('Visual Tests', () => {
  it('captures homepage', () => {
    cy.visit('/');
    cy.percySnapshot('Homepage', {
      widths: [375, 768, 1280]
    });
  });

  it('captures interactive states', () => {
    cy.visit('/form');
    
    // Default state
    cy.percySnapshot('Form - Default');
    
    // Error state
    cy.get('button[type="submit"]').click();
    cy.percySnapshot('Form - Validation Errors');
    
    // Filled state
    cy.get('input[name="email"]').type('test@example.com');
    cy.get('input[name="password"]').type('password');
    cy.percySnapshot('Form - Filled');
  });
});
```

## ♿ Accessibility Testing

### Automated Accessibility Checks

```typescript
// Playwright accessibility
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('homepage has no violations', async ({ page }) => {
    await page.goto('/');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('forms are accessible', async ({ page }) => {
    await page.goto('/contact');
    
    // Test keyboard navigation
    await page.keyboard.press('Tab');
    const focusedElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(focusedElement).toBe('INPUT');
    
    // Test screen reader labels
    const nameInput = page.locator('input[name="name"]');
    const label = await nameInput.getAttribute('aria-label') || 
                 await page.locator(`label[for="${await nameInput.getAttribute('id')}"]`).textContent();
    expect(label).toBeTruthy();
    
    // Run axe scan
    const results = await new AxeBuilder({ page })
      .include('.contact-form')
      .analyze();
    
    expect(results.violations).toEqual([]);
  });
});

// Cypress accessibility
describe('Accessibility Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.injectAxe();
  });

  it('has no detectable a11y violations', () => {
    cy.checkA11y();
  });

  it('modal is accessible', () => {
    cy.get('button:contains("Open Modal")').click();
    
    // Check focus trap
    cy.focused().should('have.attr', 'role', 'dialog');
    
    // Check ARIA attributes
    cy.get('[role="dialog"]').should('have.attr', 'aria-modal', 'true');
    cy.get('[role="dialog"]').should('have.attr', 'aria-labelledby');
    
    // Check keyboard navigation
    cy.realPress('Escape');
    cy.get('[role="dialog"]').should('not.exist');
  });
});
```

## 🚀 Performance Testing

### Performance Metrics

```typescript
// Playwright performance testing
test('measures page performance', async ({ page }) => {
  // Start performance measurement
  await page.goto('/');
  
  // Get performance metrics
  const metrics = await page.evaluate(() => {
    const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
    const paint = performance.getEntriesByType('paint');
    
    return {
      domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
      loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
      firstPaint: paint.find(p => p.name === 'first-paint')?.startTime,
      firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime,
    };
  });
  
  // Assert performance thresholds
  expect(metrics.firstContentfulPaint).toBeLessThan(1500);
  expect(metrics.domContentLoaded).toBeLessThan(2000);
  
  // Check Core Web Vitals
  const webVitals = await page.evaluate(() => {
    return new Promise((resolve) => {
      new PerformanceObserver((entryList) => {
        const entries = entryList.getEntries();
        resolve({
          LCP: entries.find(e => e.entryType === 'largest-contentful-paint')?.startTime,
          FID: entries.find(e => e.entryType === 'first-input')?.processingStart,
          CLS: entries.filter(e => e.entryType === 'layout-shift')
            .reduce((sum, entry: any) => sum + entry.value, 0)
        });
      }).observe({ entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift'] });
    });
  });
  
  expect(webVitals.LCP).toBeLessThan(2500);
  expect(webVitals.CLS).toBeLessThan(0.1);
});
```

## 🔧 Test Utilities

### Test Data Generation

```typescript
// e2e/helpers/test-data.ts
import { faker } from '@faker-js/faker';

export function generateUser() {
  return {
    email: faker.internet.email(),
    password: 'Test123!@#',
    firstName: faker.person.firstName(),
    lastName: faker.person.lastName(),
    phone: faker.phone.number(),
    address: {
      street: faker.location.streetAddress(),
      city: faker.location.city(),
      state: faker.location.state(),
      zip: faker.location.zipCode()
    }
  };
}

export function generateProduct() {
  return {
    name: faker.commerce.productName(),
    price: parseFloat(faker.commerce.price()),
    description: faker.commerce.productDescription(),
    category: faker.commerce.department(),
    sku: faker.string.alphanumeric(8).toUpperCase()
  };
}

// Database seeding
export async function seedTestData(request: any) {
  const users = Array.from({ length: 10 }, generateUser);
  const products = Array.from({ length: 20 }, generateProduct);
  
  await request.post('/api/test/seed', {
    data: { users, products }
  });
}
```

### Custom Matchers

```javascript
// cypress/support/matchers.js
chai.use(function(chai, utils) {
  chai.Assertion.addMethod('price', function(expected) {
    const actual = parseFloat(this._obj.replace(/[$,]/g, ''));
    this.assert(
      actual === expected,
      'expected #{this} to have price #{exp} but got #{act}',
      'expected #{this} not to have price #{exp}',
      expected,
      actual
    );
  });
});

// Usage
cy.get('.product-price').should('have.price', 99.99);
```

## 📊 Running E2E Tests

### CI/CD Integration

```yaml
# .github/workflows/e2e.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 18
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build application
        run: npm run build
        
      - name: Run E2E tests
        run: |
          npm run start:test &
          npx wait-on http://localhost:3000
          npm run test:e2e
        
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: |
            test-results/
            playwright-report/
            cypress/screenshots/
            cypress/videos/
```

### Parallel Testing

```javascript
// Playwright parallel config
export default defineConfig({
  workers: process.env.CI ? 2 : 4,
  fullyParallel: true,
  
  projects: [
    {
      name: 'Chrome',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'Firefox',
      use: { ...devices['Desktop Firefox'] },
      fullyParallel: false, // Run Firefox tests serially
    },
  ],
});

// Cypress parallel with cypress-split
// cypress.config.js
setupNodeEvents(on, config) {
  require('cypress-split')(on, config);
  return config;
}

// Run: SPLIT=2 SPLIT_INDEX=0 cypress run
```

---

*End-to-end tests ensure your application works correctly from the user's perspective. Focus on critical user journeys, maintain stable selectors, and keep tests independent and repeatable.*
# MCP Playwright Testing Guide

## 🎭 Revolutionizing E2E Testing with MCP Playwright

This guide explains how to use Playwright through MCP (Model Context Protocol) for efficient E2E testing, and how to convert these tests to traditional Playwright for production use.

## Table of Contents
1. [Introduction](#introduction)
2. [How MCP Playwright Works](#how-mcp-playwright-works)
3. [Setting Up MCP Playwright Tests](#setting-up-mcp-playwright-tests)
4. [Writing Effective Tests](#writing-effective-tests)
5. [Converting to Traditional Playwright](#converting-to-traditional-playwright)
6. [Best Practices](#best-practices)
7. [Real-World Examples](#real-world-examples)

## Introduction

MCP Playwright is a game-changer for E2E testing. Instead of installing Playwright as a dependency, you access it as a service through MCP tools. This approach offers:

- **Zero setup overhead** - No installation required
- **Interactive testing** - Step-by-step execution with inspection
- **Real browser control** - Not just headless testing
- **Immediate feedback** - See results as tests run

## How MCP Playwright Works

### Architecture Overview

```
┌─────────────────┐     MCP Protocol      ┌──────────────────┐
│   Your Tests    │ ◄─────────────────►   │ Playwright Server│
│                 │                        │                  │
│ - Test Scripts  │  Function Calls        │ - Browser Control│
│ - Assertions    │ ─────────────────►     │ - DOM Inspection │
│ - Verification  │                        │ - Screenshots    │
│                 │ ◄─────────────────     │ - Network Monitor│
└─────────────────┘    Results             └──────────────────┘
```

### Available MCP Tools

#### Navigation Tools
```javascript
// Navigate to a URL
mcp__playwright__browser_navigate({ url: "https://example.com" })

// Browser navigation
mcp__playwright__browser_navigate_back()
mcp__playwright__browser_navigate_forward()
```

#### Interaction Tools
```javascript
// Click elements
mcp__playwright__browser_click({
    element: "Submit button",  // Human-readable description
    ref: "#submit-btn"        // CSS selector
})

// Type text
mcp__playwright__browser_type({
    element: "Email input",
    ref: "#email",
    text: "user@example.com",
    submit: true  // Press Enter after typing
})

// File upload
mcp__playwright__browser_file_upload({
    paths: ["/path/to/file.pdf", "/path/to/image.jpg"]
})

// Select dropdown option
mcp__playwright__browser_select_option({
    element: "Country dropdown",
    ref: "#country",
    values: ["USA", "Canada"]
})
```

#### Waiting and Verification
```javascript
// Wait for text to appear
mcp__playwright__browser_wait_for({
    text: "Success!",
    time: 10  // seconds
})

// Get accessibility snapshot
mcp__playwright__browser_snapshot()

// Take screenshot
mcp__playwright__browser_take_screenshot({
    filename: "test-result.png",
    element: "Quote container",  // Optional: screenshot specific element
    ref: ".quote-content"
})
```

#### Debugging Tools
```javascript
// Get console messages
mcp__playwright__browser_console_messages()

// Monitor network requests
mcp__playwright__browser_network_requests()

// Handle dialogs
mcp__playwright__browser_handle_dialog({
    accept: true,
    promptText: "Test input"
})
```

## Setting Up MCP Playwright Tests

### 1. Directory Structure

```
tests/
├── e2e/
│   ├── fixtures/
│   │   ├── images/
│   │   ├── data/
│   │   └── test-data.json
│   ├── helpers/
│   │   ├── browser-actions.js
│   │   ├── assertions.js
│   │   └── test-runner.js
│   └── scenarios/
│       ├── 01-login-flow.js
│       ├── 02-user-journey.js
│       └── 03-error-cases.js
└── mcp-config.json
```

### 2. Create Browser Actions Helper

```javascript
// helpers/browser-actions.js
class BrowserActions {
    async navigate(url) {
        console.log(`Navigating to: ${url}`);
        return {
            tool: 'mcp__playwright__browser_navigate',
            params: { url }
        };
    }

    async clickElement(description, selector) {
        console.log(`Clicking: ${description}`);
        return {
            tool: 'mcp__playwright__browser_click',
            params: {
                element: description,
                ref: selector
            }
        };
    }

    async typeText(description, selector, text, submit = false) {
        console.log(`Typing in ${description}: ${text}`);
        return {
            tool: 'mcp__playwright__browser_type',
            params: {
                element: description,
                ref: selector,
                text: text,
                submit: submit
            }
        };
    }

    async uploadFiles(filePaths) {
        console.log(`Uploading ${filePaths.length} files`);
        return {
            tool: 'mcp__playwright__browser_file_upload',
            params: { paths: filePaths }
        };
    }

    async waitForElement(text, timeout = 10) {
        console.log(`Waiting for: "${text}"`);
        return {
            tool: 'mcp__playwright__browser_wait_for',
            params: { text, time: timeout }
        };
    }

    async screenshot(filename, element = null) {
        console.log(`Taking screenshot: ${filename}`);
        const params = { filename };
        if (element) {
            params.element = element.description;
            params.ref = element.selector;
        }
        return {
            tool: 'mcp__playwright__browser_take_screenshot',
            params
        };
    }

    async getSnapshot() {
        return {
            tool: 'mcp__playwright__browser_snapshot',
            params: {}
        };
    }
}

module.exports = new BrowserActions();
```

### 3. Create Test Scenario

```javascript
// scenarios/login-flow.js
const browser = require('../helpers/browser-actions');

async function testLoginFlow() {
    const steps = [];
    
    // Navigate to app
    steps.push(await browser.navigate('https://app.example.com'));
    
    // Click login button
    steps.push(await browser.clickElement('Login button', '#login-btn'));
    
    // Enter credentials
    steps.push(await browser.typeText('Email field', '#email', 'user@example.com'));
    steps.push(await browser.typeText('Password field', '#password', 'secure123', true));
    
    // Wait for dashboard
    steps.push(await browser.waitForElement('Welcome Dashboard', 15));
    
    // Verify login success
    steps.push(await browser.screenshot('login-success.png'));
    
    return {
        name: 'Login Flow Test',
        steps: steps,
        expectedOutcome: 'User successfully logged in and sees dashboard'
    };
}

module.exports = { testLoginFlow };
```

## Writing Effective Tests

### Test Structure Pattern

```javascript
async function testScenario() {
    const test = {
        name: 'Descriptive Test Name',
        steps: [],
        assertions: [],
        cleanup: []
    };
    
    try {
        // Setup
        test.steps.push(await browser.navigate(BASE_URL));
        
        // Action
        test.steps.push(await browser.clickElement('Target', '#target'));
        
        // Assertion
        const snapshot = await browser.getSnapshot();
        test.assertions.push({
            type: 'element_exists',
            selector: '.success-message',
            snapshot: snapshot
        });
        
        // Screenshot for evidence
        test.steps.push(await browser.screenshot('test-result.png'));
        
    } catch (error) {
        test.error = error;
        test.steps.push(await browser.screenshot('error-state.png'));
    }
    
    return test;
}
```

### Common Test Patterns

#### 1. Form Submission Test
```javascript
async function testFormSubmission() {
    const steps = [];
    
    // Fill form
    steps.push(await browser.typeText('Name field', '#name', 'John Doe'));
    steps.push(await browser.typeText('Email field', '#email', 'john@example.com'));
    steps.push(await browser.clickElement('Submit button', '#submit'));
    
    // Wait for success
    steps.push(await browser.waitForElement('Thank you', 10));
    
    return steps;
}
```

#### 2. File Upload Test
```javascript
async function testFileUpload() {
    const steps = [];
    
    // Upload multiple files
    steps.push(await browser.uploadFiles([
        '/path/to/document.pdf',
        '/path/to/image.jpg'
    ]));
    
    // Wait for processing
    steps.push(await browser.waitForElement('Files uploaded', 15));
    
    // Verify files appear
    steps.push(await browser.getSnapshot());
    
    return steps;
}
```

#### 3. Error Handling Test
```javascript
async function testErrorHandling() {
    const steps = [];
    
    // Trigger error
    steps.push(await browser.typeText('Email', '#email', 'invalid-email'));
    steps.push(await browser.clickElement('Submit', '#submit'));
    
    // Verify error message
    steps.push(await browser.waitForElement('Invalid email format', 5));
    steps.push(await browser.screenshot('validation-error.png'));
    
    return steps;
}
```

## Converting to Traditional Playwright

### Step 1: Install Traditional Playwright

```bash
npm install --save-dev @playwright/test
npx playwright install
```

### Step 2: Create Playwright Config

```javascript
// playwright.config.js
module.exports = {
    testDir: './tests/e2e',
    timeout: 30000,
    use: {
        baseURL: 'http://localhost:3000',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    ],
};
```

### Step 3: Convert MCP Test to Playwright Test

#### Original MCP Test:
```javascript
// MCP version
async function testLogin() {
    const steps = [];
    steps.push(await browser.navigate('https://app.example.com'));
    steps.push(await browser.clickElement('Login', '#login-btn'));
    steps.push(await browser.typeText('Email', '#email', 'user@test.com'));
    steps.push(await browser.waitForElement('Dashboard', 10));
    return steps;
}
```

#### Converted Playwright Test:
```javascript
// Playwright version
const { test, expect } = require('@playwright/test');

test('user can login', async ({ page }) => {
    // Navigate
    await page.goto('https://app.example.com');
    
    // Click login
    await page.click('#login-btn');
    
    // Type email
    await page.fill('#email', 'user@test.com');
    
    // Wait for dashboard
    await page.waitForSelector('text=Dashboard', { timeout: 10000 });
    
    // Assertion
    await expect(page.locator('.dashboard')).toBeVisible();
});
```

### Conversion Mapping

| MCP Tool | Playwright Equivalent |
|----------|----------------------|
| `mcp__playwright__browser_navigate` | `page.goto()` |
| `mcp__playwright__browser_click` | `page.click()` |
| `mcp__playwright__browser_type` | `page.fill()` or `page.type()` |
| `mcp__playwright__browser_file_upload` | `page.setInputFiles()` |
| `mcp__playwright__browser_wait_for` | `page.waitForSelector()` |
| `mcp__playwright__browser_take_screenshot` | `page.screenshot()` |
| `mcp__playwright__browser_snapshot` | `page.accessibility.snapshot()` |

### Advanced Conversion Example

```javascript
// MCP Complex Test
async function complexMCPTest() {
    const steps = [];
    
    // Upload file
    steps.push(await browser.uploadFiles(['/path/to/file.pdf']));
    
    // Wait and interact
    steps.push(await browser.waitForElement('File uploaded', 10));
    steps.push(await browser.clickElement('Process', '#process-btn'));
    
    // Handle dialog
    steps.push({
        tool: 'mcp__playwright__browser_handle_dialog',
        params: { accept: true }
    });
    
    // Check network
    steps.push({
        tool: 'mcp__playwright__browser_network_requests',
        params: {}
    });
    
    return steps;
}

// Converted Playwright Test
test('complex file processing', async ({ page }) => {
    // Setup dialog handler
    page.on('dialog', dialog => dialog.accept());
    
    // Monitor network
    const requests = [];
    page.on('request', request => requests.push(request));
    
    // Upload file
    await page.setInputFiles('input[type="file"]', '/path/to/file.pdf');
    
    // Wait and interact
    await page.waitForSelector('text=File uploaded', { timeout: 10000 });
    await page.click('#process-btn');
    
    // Verify network calls
    const apiCalls = requests.filter(r => r.url().includes('/api/'));
    expect(apiCalls.length).toBeGreaterThan(0);
});
```

## Best Practices

### 1. When to Use MCP Playwright

✅ **Use MCP Playwright for:**
- Rapid prototyping of test scenarios
- Interactive test development
- Debugging failing tests
- One-off testing tasks
- AI-assisted test creation
- Visual regression testing during development

❌ **Don't use MCP Playwright for:**
- CI/CD pipelines
- Parallel test execution
- Performance testing
- Load testing

### 2. Hybrid Approach

```javascript
// Development Phase: Use MCP for quick iteration
async function developTestWithMCP() {
    // Quickly test different selectors
    await browser.clickElement('Try this button', '.btn-primary');
    await browser.clickElement('Or this one', '#submit-btn');
    
    // Take screenshots to verify state
    await browser.screenshot('current-state.png');
}

// Production Phase: Convert to Playwright
test('finalized test', async ({ page }) => {
    await page.click('#submit-btn'); // Using the selector that worked
    await expect(page).toHaveScreenshot('expected-state.png');
});
```

### 3. Test Organization

```javascript
// Shared test logic
class TestActions {
    constructor(driver) {
        this.driver = driver; // Can be MCP browser or Playwright page
    }
    
    async login(email, password) {
        if (this.driver.isMCP) {
            return [
                await this.driver.typeText('Email', '#email', email),
                await this.driver.typeText('Password', '#password', password, true)
            ];
        } else {
            await this.driver.fill('#email', email);
            await this.driver.fill('#password', password);
            await this.driver.press('#password', 'Enter');
        }
    }
}
```

### 4. Debugging Strategy

```javascript
// MCP: Interactive debugging
async function debugWithMCP() {
    await browser.navigate(URL);
    await browser.screenshot('step1.png');
    
    await browser.clickElement('Problem button', '#btn');
    await browser.screenshot('step2.png');
    
    const console = await browser.getConsoleMessages();
    console.log('Console errors:', console);
    
    const snapshot = await browser.getSnapshot();
    console.log('DOM state:', snapshot);
}

// Playwright: Automated debugging
test('debug test', async ({ page }) => {
    await page.goto(URL);
    await page.pause(); // Launches inspector
    
    await page.click('#btn');
    
    // Auto-screenshots on failure
    await expect(page).toHaveScreenshot();
});
```

## Real-World Examples

### Example 1: E-commerce Checkout Flow

```javascript
// MCP Version - Interactive Development
async function testCheckoutMCP() {
    const actions = [];
    
    // Add items to cart
    actions.push(await browser.navigate('/products'));
    actions.push(await browser.clickElement('Add iPhone to cart', '[data-product="iphone"] .add-to-cart'));
    actions.push(await browser.waitForElement('Added to cart', 5));
    
    // Go to checkout
    actions.push(await browser.clickElement('Cart icon', '.cart-icon'));
    actions.push(await browser.clickElement('Checkout button', '#checkout'));
    
    // Fill shipping
    actions.push(await browser.typeText('Name', '#ship-name', 'John Doe'));
    actions.push(await browser.typeText('Address', '#ship-address', '123 Main St'));
    
    // Payment
    actions.push(await browser.typeText('Card number', '#card-number', '4242424242424242'));
    actions.push(await browser.clickElement('Place order', '#place-order'));
    
    // Verify
    actions.push(await browser.waitForElement('Order confirmed', 10));
    actions.push(await browser.screenshot('order-confirmation.png'));
    
    return actions;
}

// Playwright Version - Production Ready
test('complete checkout flow', async ({ page }) => {
    // Add to cart
    await page.goto('/products');
    await page.click('[data-product="iphone"] .add-to-cart');
    await expect(page.locator('.cart-badge')).toContainText('1');
    
    // Checkout
    await page.click('.cart-icon');
    await page.click('#checkout');
    
    // Fill shipping
    await page.fill('#ship-name', 'John Doe');
    await page.fill('#ship-address', '123 Main St');
    
    // Payment
    await page.fill('#card-number', '4242424242424242');
    await page.fill('#card-exp', '12/25');
    await page.fill('#card-cvc', '123');
    
    // Place order
    await page.click('#place-order');
    
    // Verify confirmation
    await expect(page).toHaveURL(/\/order-confirmation/);
    await expect(page.locator('.order-number')).toBeVisible();
});
```

### Example 2: File Processing Application

```javascript
// MCP Version - Testing file upload variations
async function testFileProcessingMCP() {
    const results = {
        singleFile: [],
        multipleFiles: [],
        largeFile: [],
        errors: []
    };
    
    // Test single file
    results.singleFile.push(await browser.uploadFiles(['test.pdf']));
    results.singleFile.push(await browser.waitForElement('Processing complete', 30));
    
    // Test multiple files
    results.multipleFiles.push(await browser.uploadFiles([
        'doc1.pdf',
        'doc2.pdf',
        'image.jpg'
    ]));
    results.multipleFiles.push(await browser.waitForElement('3 files processed', 45));
    
    // Test error case
    try {
        results.errors.push(await browser.uploadFiles(['corrupt.pdf']));
        results.errors.push(await browser.waitForElement('Error: Invalid file', 5));
    } catch (e) {
        results.errors.push({ error: e.message });
    }
    
    return results;
}

// Playwright Version - Robust file testing
test.describe('file processing', () => {
    test('single file upload', async ({ page }) => {
        await page.goto('/upload');
        await page.setInputFiles('input[type="file"]', 'test.pdf');
        
        await expect(page.locator('.progress')).toBeVisible();
        await expect(page.locator('.success')).toContainText('Processing complete', {
            timeout: 30000
        });
    });
    
    test('multiple files upload', async ({ page }) => {
        await page.goto('/upload');
        await page.setInputFiles('input[type="file"]', [
            'doc1.pdf',
            'doc2.pdf',
            'image.jpg'
        ]);
        
        await expect(page.locator('.file-count')).toContainText('3');
        await expect(page.locator('.success')).toContainText('3 files processed', {
            timeout: 45000
        });
    });
    
    test('handles corrupt file', async ({ page }) => {
        await page.goto('/upload');
        await page.setInputFiles('input[type="file"]', 'corrupt.pdf');
        
        await expect(page.locator('.error')).toContainText('Invalid file');
    });
});
```

## Conclusion

MCP Playwright revolutionizes E2E test development by providing:

1. **Instant Testing** - No setup required
2. **Interactive Development** - See what happens in real-time
3. **Easy Debugging** - Step through tests interactively
4. **Smooth Migration** - Easy conversion to traditional Playwright

### Recommended Workflow

1. **Prototype with MCP** - Quickly develop and debug tests
2. **Validate Interactively** - Ensure tests work correctly
3. **Convert to Playwright** - For CI/CD integration
4. **Maintain Both** - Use MCP for debugging production test failures

### Resources

- [Playwright Documentation](https://playwright.dev)
- [MCP Protocol Specification](https://modelcontextprotocol.org)
- [Example Test Repository](https://github.com/your-org/mcp-playwright-examples)

---

*This guide is based on real experience implementing E2E tests for the DabsFlow AI Quoting Co-Pilot feature using MCP Playwright tools.*
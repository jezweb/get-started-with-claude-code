# Modern CSS Patterns & Best Practices

Comprehensive guide to modern CSS techniques, patterns, and best practices for building maintainable, performant, and responsive web interfaces.

## 🎯 Modern CSS Overview

Modern CSS provides powerful features for creating robust, maintainable stylesheets:
- **CSS Grid & Flexbox** - Advanced layout systems
- **Custom Properties (CSS Variables)** - Dynamic styling
- **Container Queries** - Responsive components
- **CSS Modules** - Scoped styling
- **PostCSS** - CSS transformation and optimization

## 🚀 CSS Architecture

### BEM Methodology
```css
/* Block, Element, Modifier naming convention */

/* Block */
.card {
  padding: 1rem;
  border-radius: 0.5rem;
  background: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* Element */
.card__header {
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.card__title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1f2937;
}

.card__content {
  line-height: 1.6;
  color: #4b5563;
}

.card__footer {
  margin-top: 1rem;
  padding-top: 0.5rem;
  border-top: 1px solid #e5e7eb;
}

/* Modifiers */
.card--featured {
  border: 2px solid #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
}

.card--compact {
  padding: 0.75rem;
}

.card--large {
  padding: 2rem;
}

/* State modifiers */
.card--loading {
  opacity: 0.6;
  pointer-events: none;
}
```

### CSS Custom Properties (Variables)
```css
/* Design System with CSS Variables */
:root {
  /* Color palette */
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-900: #1e3a8a;

  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-500: #6b7280;
  --color-gray-900: #111827;

  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;

  /* Typography */
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-mono: 'JetBrains Mono', Consolas, monospace;

  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;

  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.25rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-10: 2.5rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Layout */
  --border-radius-sm: 0.125rem;
  --border-radius: 0.25rem;
  --border-radius-md: 0.375rem;
  --border-radius-lg: 0.5rem;
  --border-radius-xl: 0.75rem;

  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
  --transition-slow: 350ms ease;

  /* Z-index scale */
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-modal-backdrop: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
}

/* Dark theme */
[data-theme="dark"] {
  --color-primary-50: #1e3a8a;
  --color-primary-100: #1e40af;
  
  --color-gray-50: #111827;
  --color-gray-100: #1f2937;
  --color-gray-500: #9ca3af;
  --color-gray-900: #f9fafb;
}

/* Component using variables */
.button {
  font-family: var(--font-sans);
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  padding: var(--space-2) var(--space-4);
  border-radius: var(--border-radius);
  border: none;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.button--primary {
  background-color: var(--color-primary-500);
  color: white;
}

.button--primary:hover {
  background-color: var(--color-primary-600);
  box-shadow: var(--shadow-md);
}
```

## 📐 Layout Patterns

### CSS Grid Layouts
```css
/* Grid Container Patterns */

/* Basic Grid Layout */
.grid-basic {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--space-6);
}

/* Dashboard Layout */
.dashboard-layout {
  display: grid;
  grid-template-areas: 
    "header header header"
    "sidebar main aside"
    "footer footer footer";
  grid-template-columns: 250px 1fr 300px;
  grid-template-rows: 60px 1fr 60px;
  min-height: 100vh;
  gap: var(--space-4);
}

.dashboard-layout__header {
  grid-area: header;
  background: var(--color-gray-50);
  padding: var(--space-4);
}

.dashboard-layout__sidebar {
  grid-area: sidebar;
  background: var(--color-gray-100);
  padding: var(--space-4);
}

.dashboard-layout__main {
  grid-area: main;
  padding: var(--space-4);
}

.dashboard-layout__aside {
  grid-area: aside;
  background: var(--color-gray-50);
  padding: var(--space-4);
}

.dashboard-layout__footer {
  grid-area: footer;
  background: var(--color-gray-100);
  padding: var(--space-4);
}

/* Responsive Grid */
@media (max-width: 768px) {
  .dashboard-layout {
    grid-template-areas: 
      "header"
      "main"
      "sidebar"
      "aside"
      "footer";
    grid-template-columns: 1fr;
    grid-template-rows: 60px auto auto auto 60px;
  }
}

/* Card Grid with Auto-fit */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-6);
  padding: var(--space-6);
}

/* Masonry-style Grid */
.masonry-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  grid-auto-rows: 10px;
  gap: var(--space-4);
}

.masonry-grid__item {
  grid-row-end: span var(--span, 20);
}

/* Calculate span based on content height */
.masonry-grid__item--tall { --span: 40; }
.masonry-grid__item--medium { --span: 30; }
.masonry-grid__item--short { --span: 20; }
```

### Flexbox Patterns
```css
/* Flexible Component Layouts */

/* Center Everything */
.flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
}

/* Navigation Bar */
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-4) var(--space-6);
  background: white;
  box-shadow: var(--shadow-sm);
}

.navbar__brand {
  font-size: var(--text-xl);
  font-weight: var(--font-weight-bold);
  color: var(--color-primary-600);
}

.navbar__menu {
  display: flex;
  gap: var(--space-6);
  list-style: none;
  margin: 0;
  padding: 0;
}

.navbar__actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

/* Card with Header and Footer */
.flex-card {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: white;
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow);
  overflow: hidden;
}

.flex-card__header {
  padding: var(--space-4);
  background: var(--color-gray-50);
  border-bottom: 1px solid var(--color-gray-200);
}

.flex-card__content {
  flex: 1; /* Grows to fill available space */
  padding: var(--space-4);
}

.flex-card__footer {
  padding: var(--space-4);
  background: var(--color-gray-50);
  border-top: 1px solid var(--color-gray-200);
}

/* Flexible Form Layout */
.form-row {
  display: flex;
  gap: var(--space-4);
  margin-bottom: var(--space-4);
}

.form-row__field {
  flex: 1;
}

.form-row__field--narrow {
  flex: 0 0 200px;
}

.form-row__field--wide {
  flex: 2;
}

/* Media Object Pattern */
.media {
  display: flex;
  gap: var(--space-4);
}

.media__object {
  flex-shrink: 0;
}

.media__content {
  flex: 1;
  min-width: 0; /* Prevents flex item from overflowing */
}

.media__content h3 {
  margin: 0 0 var(--space-2) 0;
  font-size: var(--text-lg);
  font-weight: var(--font-weight-semibold);
}

.media__content p {
  margin: 0;
  color: var(--color-gray-600);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

## 🎨 Component Patterns

### Button Component System
```css
/* Base Button */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  font-family: var(--font-sans);
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  line-height: 1.5;
  text-decoration: none;
  border: 1px solid transparent;
  border-radius: var(--border-radius);
  cursor: pointer;
  transition: all var(--transition-fast);
  user-select: none;
  white-space: nowrap;
}

.btn:focus {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
}

/* Button Variants */
.btn--primary {
  background-color: var(--color-primary-500);
  color: white;
}

.btn--primary:hover {
  background-color: var(--color-primary-600);
  box-shadow: var(--shadow-md);
}

.btn--secondary {
  background-color: var(--color-gray-100);
  color: var(--color-gray-900);
  border-color: var(--color-gray-300);
}

.btn--secondary:hover {
  background-color: var(--color-gray-200);
}

.btn--outline {
  background-color: transparent;
  color: var(--color-primary-600);
  border-color: var(--color-primary-300);
}

.btn--outline:hover {
  background-color: var(--color-primary-50);
}

.btn--ghost {
  background-color: transparent;
  color: var(--color-gray-600);
}

.btn--ghost:hover {
  background-color: var(--color-gray-100);
  color: var(--color-gray-900);
}

.btn--danger {
  background-color: var(--color-error);
  color: white;
}

.btn--danger:hover {
  background-color: #dc2626;
}

/* Button Sizes */
.btn--xs {
  padding: var(--space-1) var(--space-2);
  font-size: var(--text-xs);
}

.btn--sm {
  padding: var(--space-2) var(--space-3);
  font-size: var(--text-sm);
}

.btn--lg {
  padding: var(--space-3) var(--space-6);
  font-size: var(--text-lg);
}

.btn--xl {
  padding: var(--space-4) var(--space-8);
  font-size: var(--text-xl);
}

/* Button States */
.btn:disabled,
.btn--disabled {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}

.btn--loading {
  position: relative;
  color: transparent;
}

.btn--loading::after {
  content: '';
  position: absolute;
  width: 16px;
  height: 16px;
  border: 2px solid currentColor;
  border-radius: 50%;
  border-top-color: transparent;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Button with Icon */
.btn--icon-only {
  padding: var(--space-2);
  aspect-ratio: 1;
}

.btn__icon {
  width: 1em;
  height: 1em;
  fill: currentColor;
}
```

### Form Component System
```css
/* Form Base Styles */
.form {
  max-width: 500px;
}

.form__group {
  margin-bottom: var(--space-5);
}

.form__label {
  display: block;
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-gray-700);
}

.form__label--required::after {
  content: ' *';
  color: var(--color-error);
}

/* Input Base */
.form__input {
  width: 100%;
  padding: var(--space-3);
  font-size: var(--text-base);
  line-height: 1.5;
  color: var(--color-gray-900);
  background-color: white;
  border: 1px solid var(--color-gray-300);
  border-radius: var(--border-radius);
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
}

.form__input:focus {
  outline: none;
  border-color: var(--color-primary-500);
  box-shadow: 0 0 0 3px var(--color-primary-100);
}

.form__input::placeholder {
  color: var(--color-gray-400);
}

/* Input States */
.form__input--error {
  border-color: var(--color-error);
}

.form__input--error:focus {
  border-color: var(--color-error);
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}

.form__input--success {
  border-color: var(--color-success);
}

.form__input:disabled {
  background-color: var(--color-gray-50);
  color: var(--color-gray-500);
  cursor: not-allowed;
}

/* Input Sizes */
.form__input--sm {
  padding: var(--space-2);
  font-size: var(--text-sm);
}

.form__input--lg {
  padding: var(--space-4);
  font-size: var(--text-lg);
}

/* Input with Icon */
.form__input-wrapper {
  position: relative;
}

.form__input--with-icon-left {
  padding-left: var(--space-10);
}

.form__input--with-icon-right {
  padding-right: var(--space-10);
}

.form__input-icon {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 1.25rem;
  height: 1.25rem;
  color: var(--color-gray-400);
  pointer-events: none;
}

.form__input-icon--left {
  left: var(--space-3);
}

.form__input-icon--right {
  right: var(--space-3);
}

/* Help Text and Errors */
.form__help {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  color: var(--color-gray-600);
}

.form__error {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  color: var(--color-error);
}

/* Checkbox and Radio */
.form__checkbox,
.form__radio {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
}

.form__checkbox input,
.form__radio input {
  margin-top: 0.125rem;
  width: 1rem;
  height: 1rem;
  accent-color: var(--color-primary-500);
}

.form__checkbox label,
.form__radio label {
  flex: 1;
  font-size: var(--text-sm);
  line-height: 1.5;
}

/* Select */
.form__select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
  background-position: right var(--space-3) center;
  background-repeat: no-repeat;
  background-size: 1rem;
  padding-right: var(--space-10);
}
```

### Modal Component
```css
/* Modal Overlay */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal-backdrop);
  opacity: 0;
  visibility: hidden;
  transition: all var(--transition-base);
}

.modal-overlay--open {
  opacity: 1;
  visibility: visible;
}

/* Modal Container */
.modal {
  background: white;
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-lg);
  max-width: 90vw;
  max-height: 90vh;
  overflow: hidden;
  transform: scale(0.95) translateY(-20px);
  transition: transform var(--transition-base);
  z-index: var(--z-modal);
}

.modal-overlay--open .modal {
  transform: scale(1) translateY(0);
}

/* Modal Sizes */
.modal--sm {
  width: 400px;
}

.modal--md {
  width: 500px;
}

.modal--lg {
  width: 700px;
}

.modal--xl {
  width: 900px;
}

.modal--full {
  width: 100vw;
  height: 100vh;
  max-width: none;
  max-height: none;
  border-radius: 0;
}

/* Modal Sections */
.modal__header {
  padding: var(--space-6);
  border-bottom: 1px solid var(--color-gray-200);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal__title {
  margin: 0;
  font-size: var(--text-xl);
  font-weight: var(--font-weight-semibold);
  color: var(--color-gray-900);
}

.modal__close {
  background: none;
  border: none;
  padding: var(--space-2);
  cursor: pointer;
  border-radius: var(--border-radius);
  transition: background-color var(--transition-fast);
}

.modal__close:hover {
  background-color: var(--color-gray-100);
}

.modal__body {
  padding: var(--space-6);
  overflow-y: auto;
}

.modal__footer {
  padding: var(--space-6);
  border-top: 1px solid var(--color-gray-200);
  display: flex;
  gap: var(--space-3);
  justify-content: flex-end;
}

/* Modal Animations */
@media (prefers-reduced-motion: reduce) {
  .modal-overlay,
  .modal {
    transition: none;
  }
}
```

## 📱 Responsive Design

### Container Queries (Modern)
```css
/* Container Query Setup */
.card-container {
  container-type: inline-size;
  container-name: card;
}

/* Container-based responsive design */
@container card (min-width: 300px) {
  .card {
    display: flex;
    gap: var(--space-4);
  }
  
  .card__image {
    flex: 0 0 120px;
  }
  
  .card__content {
    flex: 1;
  }
}

@container card (min-width: 500px) {
  .card {
    padding: var(--space-6);
  }
  
  .card__title {
    font-size: var(--text-2xl);
  }
}

/* Responsive Grid with Container Queries */
.grid-container {
  container-type: inline-size;
}

.responsive-grid {
  display: grid;
  gap: var(--space-4);
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
}

@container (min-width: 600px) {
  .responsive-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@container (min-width: 900px) {
  .responsive-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Traditional Media Queries
```css
/* Mobile-first approach */
.responsive-layout {
  padding: var(--space-4);
}

.responsive-grid {
  display: grid;
  gap: var(--space-4);
  grid-template-columns: 1fr;
}

.responsive-text {
  font-size: var(--text-base);
  line-height: 1.6;
}

/* Tablet */
@media (min-width: 768px) {
  .responsive-layout {
    padding: var(--space-6);
  }
  
  .responsive-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .responsive-text {
    font-size: var(--text-lg);
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .responsive-layout {
    padding: var(--space-8);
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .responsive-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-6);
  }
}

/* Large screens */
@media (min-width: 1280px) {
  .responsive-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* High DPI displays */
@media (min-resolution: 2dppx) {
  .high-res-image {
    background-image: url('image@2x.png');
    background-size: contain;
  }
}

/* Reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Dark mode preference */
@media (prefers-color-scheme: dark) {
  :root {
    --color-gray-50: #111827;
    --color-gray-100: #1f2937;
    --color-gray-900: #f9fafb;
  }
}

/* Print styles */
@media print {
  .no-print {
    display: none !important;
  }
  
  .print-block {
    display: block !important;
  }
  
  a[href^="http"]:after {
    content: " (" attr(href) ")";
  }
}
```

## 🎭 Animations & Transitions

### CSS Animations
```css
/* Loading Animations */
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

@keyframes bounce {
  0%, 20%, 53%, 80%, 100% {
    animation-timing-function: cubic-bezier(0.215, 0.61, 0.355, 1);
    transform: translate3d(0, 0, 0);
  }
  40%, 43% {
    animation-timing-function: cubic-bezier(0.755, 0.05, 0.855, 0.06);
    transform: translate3d(0, -30px, 0);
  }
  70% {
    animation-timing-function: cubic-bezier(0.755, 0.05, 0.855, 0.06);
    transform: translate3d(0, -15px, 0);
  }
  90% {
    transform: translate3d(0, -4px, 0);
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translate3d(0, 40px, 0);
  }
  to {
    opacity: 1;
    transform: translate3d(0, 0, 0);
  }
}

@keyframes slideInRight {
  from {
    transform: translate3d(100%, 0, 0);
  }
  to {
    transform: translate3d(0, 0, 0);
  }
}

/* Animation Classes */
.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.animate-bounce {
  animation: bounce 1s infinite;
}

.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out;
}

.animate-slide-in-right {
  animation: slideInRight 0.3s ease-out;
}

/* Staggered Animations */
.stagger-children > * {
  animation: fadeInUp 0.6s ease-out;
  animation-fill-mode: both;
}

.stagger-children > *:nth-child(1) { animation-delay: 0.1s; }
.stagger-children > *:nth-child(2) { animation-delay: 0.2s; }
.stagger-children > *:nth-child(3) { animation-delay: 0.3s; }
.stagger-children > *:nth-child(4) { animation-delay: 0.4s; }
.stagger-children > *:nth-child(5) { animation-delay: 0.5s; }

/* Hover Animations */
.hover-lift {
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.hover-lift:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.hover-scale {
  transition: transform var(--transition-fast);
}

.hover-scale:hover {
  transform: scale(1.05);
}

/* Loading Skeleton */
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

.skeleton--text {
  height: 1rem;
  border-radius: var(--border-radius-sm);
}

.skeleton--title {
  height: 1.5rem;
  border-radius: var(--border-radius-sm);
}

.skeleton--circle {
  border-radius: 50%;
  aspect-ratio: 1;
}
```

### Scroll Animations
```css
/* Scroll-triggered animations */
.scroll-reveal {
  opacity: 0;
  transform: translateY(40px);
  transition: opacity 0.6s ease, transform 0.6s ease;
}

.scroll-reveal.is-visible {
  opacity: 1;
  transform: translateY(0);
}

/* Parallax effect */
.parallax {
  transform: translateZ(0);
  will-change: transform;
}

/* Scroll progress indicator */
.scroll-progress {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 4px;
  background: var(--color-primary-200);
  z-index: var(--z-fixed);
}

.scroll-progress__bar {
  height: 100%;
  background: var(--color-primary-500);
  transform-origin: 0%;
  transform: scaleX(0);
  transition: transform 0.1s ease;
}
```

## 🛠️ Utility Classes

### Spacing Utilities
```css
/* Margin utilities */
.m-0 { margin: 0; }
.m-1 { margin: var(--space-1); }
.m-2 { margin: var(--space-2); }
.m-3 { margin: var(--space-3); }
.m-4 { margin: var(--space-4); }
.m-5 { margin: var(--space-5); }
.m-6 { margin: var(--space-6); }
.m-8 { margin: var(--space-8); }
.m-auto { margin: auto; }

/* Padding utilities */
.p-0 { padding: 0; }
.p-1 { padding: var(--space-1); }
.p-2 { padding: var(--space-2); }
.p-3 { padding: var(--space-3); }
.p-4 { padding: var(--space-4); }
.p-5 { padding: var(--space-5); }
.p-6 { padding: var(--space-6); }
.p-8 { padding: var(--space-8); }

/* Directional spacing */
.mt-4 { margin-top: var(--space-4); }
.mr-4 { margin-right: var(--space-4); }
.mb-4 { margin-bottom: var(--space-4); }
.ml-4 { margin-left: var(--space-4); }
.mx-4 { margin-left: var(--space-4); margin-right: var(--space-4); }
.my-4 { margin-top: var(--space-4); margin-bottom: var(--space-4); }

.pt-4 { padding-top: var(--space-4); }
.pr-4 { padding-right: var(--space-4); }
.pb-4 { padding-bottom: var(--space-4); }
.pl-4 { padding-left: var(--space-4); }
.px-4 { padding-left: var(--space-4); padding-right: var(--space-4); }
.py-4 { padding-top: var(--space-4); padding-bottom: var(--space-4); }
```

### Display & Layout Utilities
```css
/* Display */
.block { display: block; }
.inline { display: inline; }
.inline-block { display: inline-block; }
.flex { display: flex; }
.inline-flex { display: inline-flex; }
.grid { display: grid; }
.hidden { display: none; }

/* Flexbox utilities */
.flex-row { flex-direction: row; }
.flex-col { flex-direction: column; }
.flex-wrap { flex-wrap: wrap; }
.flex-nowrap { flex-wrap: nowrap; }

.items-start { align-items: flex-start; }
.items-center { align-items: center; }
.items-end { align-items: flex-end; }
.items-stretch { align-items: stretch; }

.justify-start { justify-content: flex-start; }
.justify-center { justify-content: center; }
.justify-end { justify-content: flex-end; }
.justify-between { justify-content: space-between; }
.justify-around { justify-content: space-around; }

.flex-1 { flex: 1 1 0%; }
.flex-auto { flex: 1 1 auto; }
.flex-none { flex: none; }

/* Grid utilities */
.grid-cols-1 { grid-template-columns: repeat(1, minmax(0, 1fr)); }
.grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.grid-cols-4 { grid-template-columns: repeat(4, minmax(0, 1fr)); }

.gap-2 { gap: var(--space-2); }
.gap-4 { gap: var(--space-4); }
.gap-6 { gap: var(--space-6); }
.gap-8 { gap: var(--space-8); }

/* Position */
.relative { position: relative; }
.absolute { position: absolute; }
.fixed { position: fixed; }
.sticky { position: sticky; }

.top-0 { top: 0; }
.right-0 { right: 0; }
.bottom-0 { bottom: 0; }
.left-0 { left: 0; }

/* Text utilities */
.text-left { text-align: left; }
.text-center { text-align: center; }
.text-right { text-align: right; }

.font-normal { font-weight: var(--font-weight-normal); }
.font-medium { font-weight: var(--font-weight-medium); }
.font-semibold { font-weight: var(--font-weight-semibold); }
.font-bold { font-weight: var(--font-weight-bold); }

.text-xs { font-size: var(--text-xs); }
.text-sm { font-size: var(--text-sm); }
.text-base { font-size: var(--text-base); }
.text-lg { font-size: var(--text-lg); }
.text-xl { font-size: var(--text-xl); }

/* Color utilities */
.text-gray-500 { color: var(--color-gray-500); }
.text-gray-900 { color: var(--color-gray-900); }
.text-primary { color: var(--color-primary-500); }
.text-success { color: var(--color-success); }
.text-error { color: var(--color-error); }

.bg-white { background-color: white; }
.bg-gray-50 { background-color: var(--color-gray-50); }
.bg-gray-100 { background-color: var(--color-gray-100); }
.bg-primary { background-color: var(--color-primary-500); }

/* Border utilities */
.border { border: 1px solid var(--color-gray-300); }
.border-0 { border: 0; }
.border-t { border-top: 1px solid var(--color-gray-300); }
.border-r { border-right: 1px solid var(--color-gray-300); }
.border-b { border-bottom: 1px solid var(--color-gray-300); }
.border-l { border-left: 1px solid var(--color-gray-300); }

.rounded { border-radius: var(--border-radius); }
.rounded-md { border-radius: var(--border-radius-md); }
.rounded-lg { border-radius: var(--border-radius-lg); }
.rounded-full { border-radius: 9999px; }

/* Shadow utilities */
.shadow-sm { box-shadow: var(--shadow-sm); }
.shadow { box-shadow: var(--shadow); }
.shadow-md { box-shadow: var(--shadow-md); }
.shadow-lg { box-shadow: var(--shadow-lg); }
.shadow-none { box-shadow: none; }
```

## 🎯 Performance Optimization

### CSS Performance Best Practices
```css
/* Use efficient selectors */
/* ✅ Good - class selectors are fast */
.navigation-item { }

/* ❌ Avoid - complex selectors are slow */
div > ul li:nth-child(odd) a { }

/* ✅ Use transform and opacity for animations */
.smooth-animation {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.smooth-animation:hover {
  transform: translateY(-2px);
  opacity: 0.8;
}

/* ❌ Avoid animating layout properties */
.expensive-animation {
  transition: height 0.3s ease; /* Causes layout */
}

/* GPU acceleration with will-change */
.gpu-accelerated {
  will-change: transform;
  transform: translateZ(0); /* Force GPU layer */
}

/* Remove will-change after animation */
.animation-complete {
  will-change: auto;
}

/* Critical CSS inlining pattern */
.above-fold {
  /* Critical styles for above-the-fold content */
}

/* Non-critical styles can be loaded separately */
.below-fold {
  /* Styles for content below the fold */
}

/* Efficient font loading */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-weight: 100 900;
  font-style: normal;
  font-display: swap; /* Improves loading performance */
}

/* Container queries for better performance than JS */
.responsive-component {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .responsive-component {
    /* Layout changes without JavaScript */
  }
}
```

### CSS Modules Pattern
```css
/* styles/Button.module.css */
.button {
  display: inline-flex;
  align-items: center;
  padding: var(--space-2) var(--space-4);
  border: none;
  border-radius: var(--border-radius);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.primary {
  background-color: var(--color-primary-500);
  color: white;
}

.secondary {
  background-color: var(--color-gray-100);
  color: var(--color-gray-900);
}

.loading {
  position: relative;
  color: transparent;
}

.loading::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 1rem;
  height: 1rem;
  margin: -0.5rem 0 0 -0.5rem;
  border: 2px solid currentColor;
  border-radius: 50%;
  border-top-color: transparent;
  animation: spin 1s linear infinite;
}

/* Usage in JavaScript/TypeScript */
/*
import styles from './Button.module.css';

const Button = ({ variant = 'primary', loading, children, ...props }) => (
  <button 
    className={`${styles.button} ${styles[variant]} ${loading ? styles.loading : ''}`}
    {...props}
  >
    {children}
  </button>
);
*/
```

## 🛠️ Best Practices Summary

### 1. Architecture & Organization
- Use a consistent naming convention (BEM recommended)
- Organize CSS with a scalable architecture (ITCSS, Atomic CSS)
- Leverage CSS custom properties for theming and consistency
- Keep specificity low and avoid `!important`
- Use CSS Modules or similar for component-scoped styles

### 2. Performance
- Minimize and compress CSS files
- Use efficient selectors (classes over complex selectors)
- Animate only `transform` and `opacity` properties
- Use `will-change` sparingly and remove after animations
- Implement critical CSS for above-the-fold content

### 3. Responsive Design
- Use mobile-first approach with progressive enhancement
- Prefer CSS Grid and Flexbox for layouts
- Implement container queries for component-level responsiveness
- Test across multiple devices and screen sizes
- Consider accessibility and reduced motion preferences

### 4. Maintainability
- Use semantic class names that describe purpose, not appearance
- Create reusable component systems
- Document CSS patterns and usage examples
- Implement linting and formatting tools
- Keep CSS DRY (Don't Repeat Yourself) with variables and utilities

### 5. Modern Features
- Leverage CSS Grid for complex layouts
- Use CSS custom properties for dynamic theming
- Implement container queries for responsive components
- Use logical properties for internationalization
- Take advantage of new CSS features with appropriate fallbacks

---

*Modern CSS provides powerful tools for creating maintainable, performant, and beautiful user interfaces. Following these patterns ensures scalable and efficient stylesheets.*
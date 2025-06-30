# Ship-Ready Checklist

I'll run through a comprehensive pre-deployment checklist to ensure your application is ready for production. This command validates everything from code quality to deployment configuration.

## ✅ Pre-Deployment Checklist

### 1. **Code Quality & Tests**
   - [ ] All tests passing (unit, integration, E2E)
   - [ ] Code coverage meets requirements
   - [ ] No linting errors or warnings
   - [ ] Type checking passes (if TypeScript)
   - [ ] No console.log statements in production code

### 2. **Security Review**
   - [ ] Environment variables properly secured
   - [ ] API keys not exposed in code
   - [ ] Authentication/authorization working
   - [ ] Input validation on all forms
   - [ ] CORS configured correctly
   - [ ] Dependencies up to date (no critical vulnerabilities)

### 3. **Performance Validation**
   - [ ] Bundle size within limits
   - [ ] Images optimized
   - [ ] Lazy loading implemented
   - [ ] Caching headers configured
   - [ ] Database queries optimized

### 4. **Build & Deployment**
   - [ ] Production build succeeds
   - [ ] Environment configs for production
   - [ ] Database migrations ready
   - [ ] Deployment scripts tested
   - [ ] Rollback plan documented

### 5. **User Experience**
   - [ ] All features working as expected
   - [ ] Error handling for edge cases
   - [ ] Loading states implemented
   - [ ] Mobile responsive design verified
   - [ ] Cross-browser testing complete

### 6. **Documentation**
   - [ ] README updated with setup instructions
   - [ ] API documentation current
   - [ ] Deployment guide created
   - [ ] Environment variables documented
   - [ ] Known issues/limitations noted

## 📋 Deployment Notes

I'll create a deployment summary including:
- Version number and changelog
- Migration instructions
- Configuration changes
- Monitoring setup
- Post-deployment verification steps

## 🎯 Specific Requirements

$ARGUMENTS

Running ship-ready validation...
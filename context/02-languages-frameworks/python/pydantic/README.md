# Pydantic v2 Modern Guide Documentation Resource

> **🎯 Use Case**: Modern Python web applications with robust data validation  
> **🐍 Framework**: Pydantic v2.11+ with FastAPI integration  
> **📊 Level**: Beginner to Advanced  
> **🔧 Tech Stack**: Python 3.10+, FastAPI, pydantic-settings

## 📁 What's in This Folder

| File | Purpose | Best For |
|------|---------|----------|
| **`pydantic-v2-fundamentals.md`** | Core concepts & migration guide | Understanding v2 changes, getting started |
| **`pydantic-v2-settings-configuration.md`** | Environment variables & settings | Configuration management, env setup |
| **`pydantic-v2-validation-serialization.md`** | Advanced validation features | Custom validators, computed fields |
| **`pydantic-v2-web-applications.md`** | FastAPI integration patterns | Building APIs, request/response models |
| **`pydantic-v2-production-patterns.md`** | Performance & best practices | Production deployment, optimization |

## 🚀 Quick Usage

### For AI Tools
Point your AI assistant to specific files:
```
Using the Pydantic v2 settings guide, help me set up environment variable configuration for my FastAPI application.

Using the Pydantic v2 validation guide, help me create custom validators for user input validation.
```

### Grab What You Need
```bash
# Just the fundamentals guide
curl -O https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/pydantic-v2-modern-guide/pydantic-v2-fundamentals.md

# Or get the whole folder
git clone https://github.com/jezweb/get-started-with-claude-code.git
cp -r get-started-with-claude-code/pydantic-v2-modern-guide ./my-project/
```

## 🎯 What You'll Learn

### Modern Pydantic v2 Features (2024-2025)
- **Performance**: 2x faster build times, 2-5x memory reduction
- **Rust Core**: Core validation written in Rust for maximum speed
- **Settings**: New `pydantic-settings` package for configuration
- **Validation**: Enhanced decorators and validation patterns
- **Serialization**: Duck-typing and context support

### Key Topics Covered
- **Migration from v1 to v2** with practical examples
- **Environment variable management** with BaseSettings
- **Advanced validation patterns** using new decorators
- **FastAPI integration** for modern web APIs
- **Production optimization** techniques and monitoring

## 📋 Complete Documentation Overview

This comprehensive guide covers Pydantic v2's latest features and best practices for building modern Python web applications. With Pydantic downloaded over 360M times per month and used by all FAANG companies, understanding v2's improvements is crucial for high-performance applications.

## 🔧 Documentation Contents

### 1. [Pydantic v2 Fundamentals](./pydantic-v2-fundamentals.md)
- **v2 vs v1 Changes** - Key differences and breaking changes
- **Installation & Setup** - Modern package structure and dependencies
- **Performance Improvements** - Rust core and speed optimizations
- **Migration Guide** - Step-by-step transition from v1

### 2. [Settings & Configuration](./pydantic-v2-settings-configuration.md)
- **BaseSettings Patterns** - Environment variable management
- **pydantic-settings Package** - New dedicated configuration package
- **Complex Configurations** - Nested settings and type validation
- **Performance Optimization** - Caching and build-time improvements

### 3. [Validation & Serialization](./pydantic-v2-validation-serialization.md)
- **New Decorators** - @field_validator, @model_validator, @computed_field
- **Custom Validation** - Advanced validation patterns and context
- **Serialization Features** - Duck-typing and context support (v2.7+)
- **JSON Schema** - OpenAPI v3.1.0 compliance and schema generation

### 4. [Web Application Integration](./pydantic-v2-web-applications.md)
- **FastAPI Patterns** - Request/response models and performance
- **API Design** - RESTful patterns with Pydantic models
- **Error Handling** - Validation errors and user-friendly responses
- **Async Support** - Async validation and context patterns

### 5. [Production Patterns](./pydantic-v2-production-patterns.md)
- **Memory Optimization** - 2-5x memory reduction techniques
- **Build Performance** - Schema reuse and optimization strategies
- **Monitoring** - Pydantic Logfire integration
- **Testing** - Best practices for model testing and validation

## 🎯 Target Audience

This documentation is designed for:
- **Python developers** building modern web applications
- **FastAPI users** wanting to leverage Pydantic v2's full potential
- **API developers** needing robust data validation and serialization
- **DevOps engineers** optimizing application performance and configuration

## 🚀 Why Pydantic v2?

### Performance Gains
- **2x faster** schema build times in v2.11
- **2-5x memory reduction** for complex model hierarchies
- **Rust-powered validation** for maximum speed

### Developer Experience
- **Better type support** with Python 3.12+ PEP 695 generics
- **Enhanced error messages** and debugging capabilities
- **Improved IDE support** with better type inference

### Production Ready
- **360M+ monthly downloads** showing widespread adoption
- **FAANG company usage** proving enterprise readiness
- **Active development** with regular performance improvements

---

*Part of the [Claude Code Documentation Resources](../README.md) collection*
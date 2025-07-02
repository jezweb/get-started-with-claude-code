#!/usr/bin/env python3
"""
Environment Configuration Validator
Validates your .env file configuration for AI applications
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Add colors for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'

def check_file_exists(filename: str) -> bool:
    """Check if a file exists in the current directory"""
    return Path(filename).exists()

def load_env_file(filename: str) -> Dict[str, str]:
    """Load environment variables from a file"""
    env_vars = {}
    if not check_file_exists(filename):
        return env_vars
    
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                env_vars[key.strip()] = value.strip()
    
    return env_vars

def validate_required_vars(env_vars: Dict[str, str]) -> List[Tuple[str, str]]:
    """Validate required environment variables"""
    issues = []
    
    # Required variables
    required = {
        'GEMINI_API_KEY': 'Google Gemini API key',
        'SECRET_KEY': 'Application secret key',
        'DATABASE_URL': 'Database connection string',
    }
    
    for var, description in required.items():
        if var not in env_vars:
            issues.append((var, f"Missing required: {description}"))
        elif env_vars[var] in ['', 'your-secret-key-here', 'your-gemini-api-key-here']:
            issues.append((var, f"Replace placeholder value for: {description}"))
    
    return issues

def validate_model_names(env_vars: Dict[str, str]) -> List[Tuple[str, str]]:
    """Validate AI model names are current"""
    issues = []
    valid_gemini_models = [
        'gemini-2.5-pro',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'models/text-embedding-004'
    ]
    
    model_vars = [key for key in env_vars if 'MODEL' in key and 'GEMINI' in key]
    
    for var in model_vars:
        model = env_vars[var]
        if model and model not in valid_gemini_models:
            issues.append((var, f"Invalid model '{model}'. Valid models: {', '.join(valid_gemini_models)}"))
    
    return issues

def validate_numeric_ranges(env_vars: Dict[str, str]) -> List[Tuple[str, str]]:
    """Validate numeric values are in acceptable ranges"""
    issues = []
    
    # Temperature should be between 0 and 2
    temp_vars = [key for key in env_vars if 'TEMPERATURE' in key]
    for var in temp_vars:
        try:
            temp = float(env_vars[var])
            if temp < 0 or temp > 2:
                issues.append((var, f"Temperature {temp} out of range (0-2)"))
        except ValueError:
            issues.append((var, f"Invalid temperature value: {env_vars[var]}"))
    
    # Max tokens should be reasonable
    token_vars = [key for key in env_vars if 'MAX_TOKENS' in key]
    for var in token_vars:
        try:
            tokens = int(env_vars[var])
            if tokens < 1 or tokens > 1000000:
                issues.append((var, f"Max tokens {tokens} seems unreasonable"))
        except ValueError:
            issues.append((var, f"Invalid token value: {env_vars[var]}"))
    
    return issues

def check_security(env_vars: Dict[str, str]) -> List[Tuple[str, str]]:
    """Check for security best practices"""
    warnings = []
    
    # Check if using default/weak values
    if env_vars.get('APP_DEBUG', '').lower() == 'true' and env_vars.get('APP_ENV') == 'production':
        warnings.append(('APP_DEBUG', "Debug mode should be disabled in production"))
    
    if env_vars.get('SECRET_KEY', '').startswith('your-'):
        warnings.append(('SECRET_KEY', "Using placeholder secret key - generate a secure one"))
    
    # Check CORS settings
    cors = env_vars.get('CORS_ORIGINS', '[]')
    if '*' in cors:
        warnings.append(('CORS_ORIGINS', "Using wildcard CORS origin is insecure"))
    
    return warnings

def print_results(env_file: str, env_vars: Dict[str, str], issues: List[Tuple[str, str]], warnings: List[Tuple[str, str]]):
    """Print validation results"""
    print(f"\n{Colors.BLUE}Environment Configuration Validator{Colors.END}")
    print(f"{Colors.BLUE}{'=' * 50}{Colors.END}")
    
    print(f"\n📄 Checking: {env_file}")
    print(f"📊 Total variables found: {len(env_vars)}")
    
    if not issues and not warnings:
        print(f"\n{Colors.GREEN}✅ All checks passed! Your configuration looks good.{Colors.END}")
    else:
        if issues:
            print(f"\n{Colors.RED}❌ Issues Found ({len(issues)}):{Colors.END}")
            for var, issue in issues:
                print(f"   {Colors.RED}• {var}: {issue}{Colors.END}")
        
        if warnings:
            print(f"\n{Colors.YELLOW}⚠️  Warnings ({len(warnings)}):{Colors.END}")
            for var, warning in warnings:
                print(f"   {Colors.YELLOW}• {var}: {warning}{Colors.END}")
    
    # Show some configuration details
    print(f"\n{Colors.BLUE}Current Configuration:{Colors.END}")
    print(f"   • Environment: {env_vars.get('APP_ENV', 'Not set')}")
    print(f"   • Default Model: {env_vars.get('GEMINI_MODEL', 'Not set')}")
    print(f"   • Chat Model: {env_vars.get('CHAT_MODEL', 'Not set')}")
    print(f"   • Debug Mode: {env_vars.get('APP_DEBUG', 'Not set')}")

def main():
    """Main validation function"""
    # Check which .env file to validate
    if len(sys.argv) > 1:
        env_file = sys.argv[1]
    else:
        env_file = '.env'
    
    if not check_file_exists(env_file):
        print(f"{Colors.RED}❌ Error: {env_file} not found!{Colors.END}")
        print(f"\nAvailable templates:")
        templates = ['.env.simple', '.env.complete', '.env.example']
        for template in templates:
            if check_file_exists(template):
                print(f"   • {template}")
        print(f"\nCopy a template to get started:")
        print(f"   cp .env.simple .env")
        return
    
    # Load and validate
    env_vars = load_env_file(env_file)
    
    # Run validations
    issues = []
    issues.extend(validate_required_vars(env_vars))
    issues.extend(validate_model_names(env_vars))
    issues.extend(validate_numeric_ranges(env_vars))
    
    warnings = check_security(env_vars)
    
    # Print results
    print_results(env_file, env_vars, issues, warnings)
    
    # Exit with error code if issues found
    sys.exit(1 if issues else 0)

if __name__ == "__main__":
    main()
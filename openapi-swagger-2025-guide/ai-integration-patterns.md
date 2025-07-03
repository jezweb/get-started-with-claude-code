# AI Integration Patterns for OpenAPI Documentation

## Overview

In 2025, AI agents have become first-class consumers of APIs. This guide covers how to design OpenAPI specifications that enable seamless AI integration, MCP (Model Context Protocol) server development, and automated API consumption by AI systems.

## 🤖 Understanding AI-Driven API Consumption

### How AI Agents Consume APIs

AI agents interact with APIs differently from human developers:

1. **Automatic Discovery**: AI agents can discover and understand APIs from OpenAPI specifications
2. **Dynamic Integration**: No custom code needed - AI agents adapt to new APIs automatically  
3. **Semantic Understanding**: Rich metadata enables intelligent decision-making
4. **Error Recovery**: AI agents can handle and recover from API errors autonomously
5. **Batch Processing**: AI systems often need to make multiple related API calls

### Key Requirements for AI-Friendly APIs:

- **Comprehensive Metadata**: Detailed descriptions for every component
- **Semantic Clarity**: Clear relationships between data models
- **Error Documentation**: Exhaustive error scenarios and handling
- **Usage Examples**: Multiple examples for different use cases
- **Rate Limiting Info**: Clear constraints for automated systems

## 🔌 Model Context Protocol (MCP) Integration

### What is MCP?

The Model Context Protocol enables Large Language Models to explore and interact with external APIs dynamically. MCP servers transform OpenAPI specifications into tools that AI agents can use automatically.

### MCP-Ready OpenAPI Specification

```yaml
openapi: 3.1.0
info:
  title: MCP-Ready User Management API
  version: 1.0.0
  description: |
    User management API designed for AI agent consumption via MCP.
    
    **MCP Capabilities:**
    - Automatic tool generation from endpoints
    - Schema-driven request validation
    - Error handling with contextual messages
    - Batch operations for efficiency
    
    **AI Agent Guidelines:**
    - Use pagination for large datasets
    - Implement exponential backoff for rate limits
    - Validate input data before API calls
    - Handle partial failures gracefully

  # Critical for MCP server generation
  contact:
    name: API Support
    email: api@example.com
  
  # MCP-specific metadata
  x-mcp-metadata:
    server_name: "user_management"
    version: "1.0"
    description: "User management operations for AI agents"
    capabilities:
      - "user_creation"
      - "user_retrieval" 
      - "user_updates"
      - "batch_operations"
    rate_limits:
      requests_per_minute: 100
      burst_capacity: 50
    authentication_required: true

servers:
  - url: https://api.example.com/v1
    description: Production server
    x-mcp-config:
      timeout_seconds: 30
      retry_attempts: 3
      connection_pool_size: 10

# Global security for AI agents
security:
  - BearerAuth: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        JWT authentication for AI agents.
        Token should include 'agent' scope for automated access.
        
        **MCP Integration:**
        The MCP server will handle token refresh automatically.
        Tokens expire after 1 hour.

  schemas:
    # AI-optimized user schema with rich metadata
    User:
      type: object
      required:
        - id
        - username
        - email
        - role
      properties:
        id:
          type: string
          format: uuid
          description: |
            Unique user identifier. Use this for all user-specific operations.
            **AI Note:** This ID is immutable and should be cached for efficiency.
          example: "123e4567-e89b-12d3-a456-426614174000"
          x-ai-metadata:
            key_field: true
            immutable: true
            cache_duration: "1h"
        
        username:
          type: string
          minLength: 3
          maxLength: 30
          pattern: '^[a-zA-Z0-9_]+$'
          description: |
            Unique username for the user.
            **AI Validation:** Must be unique across the system.
          example: "johndoe"
          x-ai-metadata:
            unique: true
            validation_endpoint: "/users/validate/username"
        
        email:
          type: string
          format: email
          description: |
            User's email address.
            **AI Note:** Used for notifications and password reset.
          example: "john@example.com"
          x-ai-metadata:
            unique: true
            notification_channel: true
            validation_endpoint: "/users/validate/email"
        
        role:
          type: string
          enum: [admin, user, moderator]
          description: |
            User's role determining permissions.
            **AI Authorization:** 
            - admin: Full access to all operations
            - moderator: Can manage users but not system settings
            - user: Basic operations only
          example: "user"
          x-ai-metadata:
            authorization_field: true
            permission_matrix:
              admin: ["create", "read", "update", "delete", "manage"]
              moderator: ["create", "read", "update"]
              user: ["read", "update_own"]
        
        created_at:
          type: string
          format: date-time
          description: Account creation timestamp
          example: "2025-01-15T10:30:00Z"
          readOnly: true
          x-ai-metadata:
            immutable: true
            sortable: true
        
        last_login:
          type: string
          format: date-time
          description: Last login timestamp
          example: "2025-01-15T10:30:00Z"
          readOnly: true
          x-ai-metadata:
            tracking_field: true
            privacy_sensitive: false

paths:
  # AI-optimized endpoint definitions
  /users:
    get:
      operationId: listUsers
      summary: List users with pagination
      description: |
        Retrieve a paginated list of users with optional filtering and sorting.
        
        **AI Usage Patterns:**
        - Use pagination for large datasets (recommended page size: 50)
        - Filter by role for specific user types
        - Sort by created_at for chronological processing
        - Cache results for 5 minutes to reduce API calls
        
        **Performance Notes:**
        - Response time: typically 100-300ms
        - Rate limit: 100 requests per minute
        - Maximum page size: 100 items
      
      # MCP tool metadata
      x-mcp-tool:
        name: "list_users"
        description: "Get a paginated list of users with filtering options"
        category: "user_management"
        requires_auth: true
        cache_duration: "5m"
        batch_capable: false
      
      tags:
        - Users
      
      parameters:
        - name: page
          in: query
          description: |
            Page number (1-based).
            **AI Note:** Start with page 1, increment for additional results.
          required: false
          schema:
            type: integer
            minimum: 1
            default: 1
            example: 1
          x-ai-metadata:
            pagination_param: true
            auto_increment: true
        
        - name: limit
          in: query
          description: |
            Items per page.
            **AI Recommendation:** Use 50 for balanced performance.
          required: false
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
            example: 50
          x-ai-metadata:
            pagination_param: true
            recommended_value: 50
        
        - name: role
          in: query
          description: |
            Filter users by role.
            **AI Usage:** Combine with sorting for efficient user management.
          required: false
          schema:
            type: string
            enum: [admin, user, moderator]
            example: "user"
          x-ai-metadata:
            filter_param: true
            combinable: true
        
        - name: sort_by
          in: query
          description: |
            Sort field.
            **AI Default:** Use 'created_at' for chronological processing.
          required: false
          schema:
            type: string
            enum: [username, email, created_at, last_login]
            default: created_at
            example: "created_at"
          x-ai-metadata:
            sort_param: true
            recommended_value: "created_at"
        
        - name: sort_order
          in: query
          description: Sort order
          required: false
          schema:
            type: string
            enum: [asc, desc]
            default: desc
            example: "desc"
          x-ai-metadata:
            sort_param: true
      
      responses:
        '200':
          description: Successful response with user list
          content:
            application/json:
              schema:
                type: object
                required:
                  - data
                  - pagination
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                    description: Array of user objects
                  pagination:
                    $ref: '#/components/schemas/PaginationMeta'
                  meta:
                    type: object
                    properties:
                      total_time_ms:
                        type: integer
                        description: Query execution time
                        example: 150
                      cache_hit:
                        type: boolean
                        description: Whether result was cached
                        example: false
                    x-ai-metadata:
                      performance_info: true
              
              examples:
                normal_response:
                  summary: Normal user list response
                  value:
                    data:
                      - id: "123e4567-e89b-12d3-a456-426614174000"
                        username: "johndoe"
                        email: "john@example.com"
                        role: "user"
                        created_at: "2025-01-15T10:30:00Z"
                        last_login: "2025-01-15T14:22:00Z"
                    pagination:
                      page: 1
                      limit: 20
                      total: 150
                      total_pages: 8
                      has_next: true
                      has_previous: false
                    meta:
                      total_time_ms: 150
                      cache_hit: false
                
                empty_response:
                  summary: Empty result set
                  value:
                    data: []
                    pagination:
                      page: 1
                      limit: 20
                      total: 0
                      total_pages: 0
                      has_next: false
                      has_previous: false
                    meta:
                      total_time_ms: 50
                      cache_hit: false
        
        '400':
          description: Bad request - invalid parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AIError'
              examples:
                invalid_page:
                  summary: Invalid page parameter
                  value:
                    error: "INVALID_PARAMETER"
                    message: "Page parameter must be a positive integer"
                    ai_guidance: "Use page >= 1. Current value was invalid."
                    recovery_action: "Retry with page=1"
                    parameter: "page"
                    request_id: "req_123456"
        
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AIError'
              examples:
                rate_limit:
                  summary: Rate limit exceeded
                  value:
                    error: "RATE_LIMIT_EXCEEDED"
                    message: "Too many requests"
                    ai_guidance: "Implement exponential backoff. Wait before retrying."
                    recovery_action: "Wait 60 seconds and retry"
                    retry_after_seconds: 60
                    request_id: "req_123456"
    
    post:
      operationId: createUser
      summary: Create a new user
      description: |
        Create a new user account with validation.
        
        **AI Workflow:**
        1. Validate input data against schema
        2. Check for existing username/email conflicts
        3. Create user with generated ID
        4. Return created user object
        
        **Error Handling:**
        - 409: Username or email already exists
        - 422: Validation errors with detailed field information
        
        **AI Best Practices:**
        - Always validate unique fields before creation
        - Use batch endpoint for multiple users
        - Handle validation errors gracefully
      
      x-mcp-tool:
        name: "create_user"
        description: "Create a new user account"
        category: "user_management"
        requires_auth: true
        validation_required: true
        conflict_detection: true
      
      tags:
        - Users
      
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - username
                - email
                - password
              properties:
                username:
                  type: string
                  minLength: 3
                  maxLength: 30
                  pattern: '^[a-zA-Z0-9_]+$'
                  description: |
                    Unique username.
                    **AI Validation:** Check uniqueness before creation.
                  example: "newuser"
                  x-ai-metadata:
                    unique: true
                    validation_required: true
                
                email:
                  type: string
                  format: email
                  description: |
                    User's email address.
                    **AI Validation:** Check uniqueness and format.
                  example: "newuser@example.com"
                  x-ai-metadata:
                    unique: true
                    validation_required: true
                
                password:
                  type: string
                  minLength: 8
                  description: |
                    User's password.
                    **AI Security:** Never log or cache passwords.
                  example: "securePassword123"
                  x-ai-metadata:
                    sensitive: true
                    never_cache: true
                    never_log: true
                
                role:
                  type: string
                  enum: [user, moderator]
                  default: user
                  description: |
                    User's initial role.
                    **AI Auth:** Only admins can create moderators.
                  example: "user"
                  x-ai-metadata:
                    authorization_required: ["admin"]
                    default_value: "user"
                
                first_name:
                  type: string
                  maxLength: 50
                  description: User's first name
                  example: "John"
                
                last_name:
                  type: string
                  maxLength: 50
                  description: User's last name
                  example: "Doe"
            
            examples:
              basic_user:
                summary: Basic user creation
                value:
                  username: "johndoe"
                  email: "john@example.com"
                  password: "securePassword123"
                  first_name: "John"
                  last_name: "Doe"
              
              moderator_user:
                summary: Moderator creation (admin only)
                value:
                  username: "moderator1"
                  email: "mod@example.com"
                  password: "securePassword123"
                  role: "moderator"
                  first_name: "Jane"
                  last_name: "Smith"
      
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    $ref: '#/components/schemas/User'
                  meta:
                    type: object
                    properties:
                      created_at:
                        type: string
                        format: date-time
                        description: Creation timestamp
                      welcome_email_sent:
                        type: boolean
                        description: Whether welcome email was sent
                    x-ai-metadata:
                      action_metadata: true
              
              examples:
                user_created:
                  summary: Successful user creation
                  value:
                    user:
                      id: "123e4567-e89b-12d3-a456-426614174000"
                      username: "johndoe"
                      email: "john@example.com"
                      role: "user"
                      first_name: "John"
                      last_name: "Doe"
                      created_at: "2025-01-15T10:30:00Z"
                      last_login: null
                    meta:
                      created_at: "2025-01-15T10:30:00Z"
                      welcome_email_sent: true
        
        '409':
          description: Conflict - username or email already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AIError'
              examples:
                username_exists:
                  summary: Username already exists
                  value:
                    error: "CONFLICT"
                    message: "Username already exists"
                    ai_guidance: "Try a different username or check if user already exists"
                    recovery_action: "Generate alternative username or use existing user"
                    conflicting_field: "username"
                    conflicting_value: "johndoe"
                    suggestions: ["johndoe2", "johndoe_2025", "john_doe"]
                    request_id: "req_123456"
        
        '422':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AIError'
              examples:
                validation_error:
                  summary: Input validation failed
                  value:
                    error: "VALIDATION_ERROR"
                    message: "Request validation failed"
                    ai_guidance: "Fix the validation errors and retry"
                    recovery_action: "Correct the specified fields and resubmit"
                    field_errors:
                      username: "Username must be at least 3 characters long"
                      email: "Invalid email format"
                      password: "Password must be at least 8 characters long"
                    request_id: "req_123456"

  # Batch operations for AI efficiency
  /users/batch:
    post:
      operationId: createUsersBatch
      summary: Create multiple users in batch
      description: |
        Create multiple users in a single request for AI efficiency.
        
        **AI Benefits:**
        - Reduced API calls for bulk operations
        - Atomic transaction handling
        - Partial success support
        - Detailed error reporting per user
        
        **Limitations:**
        - Maximum 100 users per batch
        - All users must be valid
        - Rollback on any critical error
      
      x-mcp-tool:
        name: "create_users_batch"
        description: "Create multiple users efficiently"
        category: "batch_operations"
        requires_auth: true
        max_batch_size: 100
        atomic_transaction: true
      
      tags:
        - Users
        - Batch Operations
      
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - users
              properties:
                users:
                  type: array
                  items:
                    type: object
                    required:
                      - username
                      - email
                      - password
                    properties:
                      username:
                        type: string
                        minLength: 3
                        maxLength: 30
                        pattern: '^[a-zA-Z0-9_]+$'
                      email:
                        type: string
                        format: email
                      password:
                        type: string
                        minLength: 8
                      role:
                        type: string
                        enum: [user, moderator]
                        default: user
                      first_name:
                        type: string
                        maxLength: 50
                      last_name:
                        type: string
                        maxLength: 50
                  minItems: 1
                  maxItems: 100
                  description: Array of users to create
                
                options:
                  type: object
                  properties:
                    fail_on_conflict:
                      type: boolean
                      default: false
                      description: |
                        Whether to fail entire batch on conflict.
                        **AI Recommendation:** Set to false for partial success.
                    send_welcome_emails:
                      type: boolean
                      default: true
                      description: Send welcome emails to created users
                  x-ai-metadata:
                    batch_options: true
            
            examples:
              small_batch:
                summary: Small batch of users
                value:
                  users:
                    - username: "user1"
                      email: "user1@example.com"
                      password: "password123"
                      first_name: "User"
                      last_name: "One"
                    - username: "user2"
                      email: "user2@example.com"
                      password: "password123"
                      first_name: "User"
                      last_name: "Two"
                  options:
                    fail_on_conflict: false
                    send_welcome_emails: true
      
      responses:
        '207':
          description: Multi-status response with partial success
          content:
            application/json:
              schema:
                type: object
                properties:
                  summary:
                    type: object
                    properties:
                      total_requested:
                        type: integer
                        description: Total users requested for creation
                      successful:
                        type: integer
                        description: Successfully created users
                      failed:
                        type: integer
                        description: Failed user creations
                      success_rate:
                        type: number
                        format: float
                        description: Success rate percentage
                    x-ai-metadata:
                      batch_summary: true
                  
                  results:
                    type: array
                    items:
                      type: object
                      properties:
                        index:
                          type: integer
                          description: Index in original request array
                        status:
                          type: string
                          enum: [success, error]
                        user:
                          $ref: '#/components/schemas/User'
                          description: Created user (if successful)
                        error:
                          $ref: '#/components/schemas/AIError'
                          description: Error details (if failed)
                    x-ai-metadata:
                      detailed_results: true
              
              examples:
                partial_success:
                  summary: Partial success response
                  value:
                    summary:
                      total_requested: 3
                      successful: 2
                      failed: 1
                      success_rate: 66.67
                    results:
                      - index: 0
                        status: "success"
                        user:
                          id: "123e4567-e89b-12d3-a456-426614174000"
                          username: "user1"
                          email: "user1@example.com"
                          role: "user"
                          created_at: "2025-01-15T10:30:00Z"
                      - index: 1
                        status: "error"
                        error:
                          error: "CONFLICT"
                          message: "Username already exists"
                          ai_guidance: "User already exists, consider updating instead"
                          conflicting_field: "username"
                      - index: 2
                        status: "success"
                        user:
                          id: "456e7890-e89b-12d3-a456-426614174001"
                          username: "user3"
                          email: "user3@example.com"
                          role: "user"
                          created_at: "2025-01-15T10:30:01Z"

components:
  schemas:
    # AI-optimized error schema
    AIError:
      type: object
      required:
        - error
        - message
        - ai_guidance
        - request_id
      properties:
        error:
          type: string
          description: Machine-readable error code
          example: "VALIDATION_ERROR"
          x-ai-metadata:
            machine_readable: true
            categorization: "error_type"
        
        message:
          type: string
          description: Human-readable error message
          example: "Request validation failed"
          x-ai-metadata:
            human_readable: true
        
        ai_guidance:
          type: string
          description: |
            Specific guidance for AI agents on handling this error.
            Includes context and suggested actions.
          example: "Fix the validation errors listed in field_errors and retry the request"
          x-ai-metadata:
            ai_specific: true
            actionable: true
        
        recovery_action:
          type: string
          description: Recommended action for error recovery
          example: "Correct the specified fields and resubmit"
          x-ai-metadata:
            recovery_guidance: true
        
        field_errors:
          type: object
          additionalProperties:
            type: string
          description: Field-specific validation errors
          example:
            username: "Username must be at least 3 characters"
            email: "Invalid email format"
          x-ai-metadata:
            field_specific: true
            validation_details: true
        
        retry_after_seconds:
          type: integer
          description: Seconds to wait before retrying (for rate limits)
          example: 60
          x-ai-metadata:
            retry_guidance: true
        
        request_id:
          type: string
          description: Unique request identifier for support
          example: "req_123456789"
          x-ai-metadata:
            tracking_id: true
        
        timestamp:
          type: string
          format: date-time
          description: Error occurrence timestamp
          example: "2025-01-15T10:30:00Z"
          x-ai-metadata:
            temporal_context: true
    
    PaginationMeta:
      type: object
      required:
        - page
        - limit
        - total
        - total_pages
        - has_next
        - has_previous
      properties:
        page:
          type: integer
          minimum: 1
          description: Current page number
          example: 1
          x-ai-metadata:
            pagination_field: true
            current_position: true
        
        limit:
          type: integer
          minimum: 1
          description: Items per page
          example: 20
          x-ai-metadata:
            pagination_field: true
            page_size: true
        
        total:
          type: integer
          minimum: 0
          description: Total number of items across all pages
          example: 150
          x-ai-metadata:
            pagination_field: true
            total_count: true
        
        total_pages:
          type: integer
          minimum: 0
          description: Total number of pages
          example: 8
          x-ai-metadata:
            pagination_field: true
            max_pages: true
        
        has_next:
          type: boolean
          description: Whether there are more pages after this one
          example: true
          x-ai-metadata:
            pagination_field: true
            navigation_hint: true
        
        has_previous:
          type: boolean
          description: Whether there are pages before this one
          example: false
          x-ai-metadata:
            pagination_field: true
            navigation_hint: true
        
        next_page:
          type: integer
          description: Next page number (if has_next is true)
          example: 2
          x-ai-metadata:
            pagination_field: true
            navigation_helper: true
        
        previous_page:
          type: integer
          description: Previous page number (if has_previous is true)
          example: null
          x-ai-metadata:
            pagination_field: true
            navigation_helper: true
```

## 🛠️ MCP Server Generation Tools

### Automatic MCP Server Generation

```yaml
# Speakeasy MCP Generator configuration
x-speakeasy-mcp:
  server_name: "user_management_mcp"
  version: "1.0.0"
  description: "MCP server for user management operations"
  
  # Tool generation settings
  tool_generation:
    include_all_operations: true
    operation_id_as_tool_name: true
    include_examples: true
    include_error_handling: true
  
  # Authentication configuration
  authentication:
    type: "bearer"
    token_refresh_endpoint: "/auth/refresh"
    auto_refresh: true
  
  # Rate limiting configuration
  rate_limiting:
    requests_per_minute: 100
    burst_capacity: 50
    backoff_strategy: "exponential"
  
  # Error handling configuration
  error_handling:
    include_ai_guidance: true
    include_recovery_actions: true
    log_errors: true
    retry_on_5xx: true
```

### FastAPI-MCP Integration

```python
# FastAPI-MCP integration example
from fastapi import FastAPI
from fastapi_mcp import MCPServer, mount_mcp_server

app = FastAPI(
    title="User Management API",
    description="API with automatic MCP server generation",
    version="1.0.0"
)

# Automatic MCP server mounting
mcp_server = MCPServer(
    name="user_management",
    description="User management operations for AI agents",
    version="1.0.0"
)

# Mount MCP server
mount_mcp_server(app, mcp_server)

# Your regular FastAPI endpoints
@app.get("/users")
async def list_users():
    """
    List users endpoint that automatically becomes an MCP tool.
    
    The MCP server will generate a tool called 'list_users' that
    AI agents can use to retrieve user data.
    """
    pass
```

## 🎯 AI-Specific Design Patterns

### 1. Semantic Relationships

```yaml
# Express relationships between entities
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        teams:
          type: array
          items:
            type: string
            format: uuid
          description: |
            Array of team IDs this user belongs to.
            **AI Relationship:** Use /teams/{id} to get team details.
          x-ai-metadata:
            relationship: "many_to_many"
            related_endpoint: "/teams/{id}"
            related_schema: "Team"
    
    Team:
      type: object
      properties:
        id:
          type: string
          format: uuid
        members:
          type: array
          items:
            type: string
            format: uuid
          description: |
            Array of user IDs who are team members.
            **AI Relationship:** Use /users/{id} to get user details.
          x-ai-metadata:
            relationship: "many_to_many"
            related_endpoint: "/users/{id}"
            related_schema: "User"
```

### 2. Workflow Guidance

```yaml
# Define workflows for AI agents
x-ai-workflows:
  user_onboarding:
    description: "Complete user onboarding workflow"
    steps:
      - operation: "createUser"
        description: "Create the user account"
        required_data: ["username", "email", "password"]
      - operation: "sendWelcomeEmail"
        description: "Send welcome email to new user"
        depends_on: ["createUser"]
      - operation: "assignDefaultRole"
        description: "Assign default permissions"
        depends_on: ["createUser"]
    error_handling:
      - condition: "user_exists"
        action: "use_existing_user"
      - condition: "invalid_email"
        action: "request_valid_email"
  
  user_management:
    description: "Complete user lifecycle management"
    decision_points:
      - condition: "user_inactive_90_days"
        action: "send_reactivation_email"
      - condition: "user_inactive_365_days"
        action: "archive_user_account"
```

### 3. AI Performance Hints

```yaml
# Performance guidance for AI systems
x-ai-performance:
  caching:
    user_data:
      duration: "5m"
      keys: ["user_id"]
      invalidate_on: ["user_update", "role_change"]
    
    user_lists:
      duration: "1m"
      keys: ["page", "limit", "role"]
      invalidate_on: ["user_create", "user_delete"]
  
  batch_operations:
    recommended_batch_size: 50
    max_batch_size: 100
    parallel_processing: true
  
  rate_limiting:
    burst_allowance: 50
    sustained_rate: "100/minute"
    backoff_strategy: "exponential"
    retry_attempts: 3
```

## 🔄 Error Handling for AI Systems

### Comprehensive Error Documentation

```yaml
components:
  schemas:
    # Error taxonomy for AI understanding
    ErrorTaxonomy:
      type: object
      properties:
        category:
          type: string
          enum: 
            - "validation"      # Input validation errors
            - "authentication"  # Auth/authorization errors  
            - "rate_limit"     # Rate limiting errors
            - "conflict"       # Resource conflicts
            - "not_found"      # Resource not found
            - "server_error"   # Internal server errors
            - "external"       # External service errors
          x-ai-metadata:
            error_classification: true
        
        severity:
          type: string
          enum: ["low", "medium", "high", "critical"]
          description: |
            Error severity for AI prioritization:
            - low: Continue with other operations
            - medium: Log and continue with caution
            - high: Stop current workflow, retry possible
            - critical: Stop all operations, human intervention needed
          x-ai-metadata:
            severity_guidance: true
        
        retry_strategy:
          type: object
          properties:
            retryable:
              type: boolean
              description: Whether this error is retryable
            max_attempts:
              type: integer
              description: Maximum retry attempts
            backoff_strategy:
              type: string
              enum: ["fixed", "linear", "exponential"]
            initial_delay_ms:
              type: integer
              description: Initial delay before retry
          x-ai-metadata:
            retry_guidance: true
        
        ai_actions:
          type: array
          items:
            type: object
            properties:
              condition:
                type: string
                description: When to perform this action
              action:
                type: string
                description: What action to take
              parameters:
                type: object
                description: Action parameters
          x-ai-metadata:
            automated_actions: true
```

### Context-Aware Error Responses

```yaml
# Error responses with AI guidance
responses:
  RateLimitError:
    description: Rate limit exceeded with AI guidance
    headers:
      Retry-After:
        description: Seconds to wait before retry
        schema:
          type: integer
          example: 60
      X-RateLimit-Limit:
        description: Request limit per time window
        schema:
          type: integer
          example: 100
      X-RateLimit-Remaining:
        description: Remaining requests in current window
        schema:
          type: integer
          example: 0
      X-RateLimit-Reset:
        description: Time when rate limit resets (Unix timestamp)
        schema:
          type: integer
          example: 1674567890
    content:
      application/json:
        schema:
          allOf:
            - $ref: '#/components/schemas/AIError'
            - type: object
              properties:
                rate_limit_info:
                  type: object
                  properties:
                    current_window_start:
                      type: string
                      format: date-time
                    current_window_end:
                      type: string
                      format: date-time
                    requests_made:
                      type: integer
                    limit:
                      type: integer
                    reset_in_seconds:
                      type: integer
                  x-ai-metadata:
                    rate_limit_context: true
        
        examples:
          rate_limit_exceeded:
            summary: Rate limit exceeded
            value:
              error: "RATE_LIMIT_EXCEEDED"
              message: "API rate limit exceeded"
              ai_guidance: |
                You've exceeded the rate limit. Implement exponential backoff:
                1. Wait 60 seconds before retry
                2. Reduce request frequency
                3. Consider batching operations
                4. Monitor rate limit headers
              recovery_action: "wait_and_retry_with_backoff"
              retry_after_seconds: 60
              rate_limit_info:
                current_window_start: "2025-01-15T10:00:00Z"
                current_window_end: "2025-01-15T11:00:00Z"
                requests_made: 100
                limit: 100
                reset_in_seconds: 2400
              request_id: "req_123456"
```

## 📊 Monitoring and Analytics for AI

### AI Usage Tracking

```yaml
# Custom extensions for AI monitoring
x-ai-monitoring:
  track_usage: true
  metrics:
    - name: "ai_agent_requests"
      description: "Number of requests from AI agents"
      labels: ["agent_type", "operation", "success"]
    
    - name: "ai_error_rate"
      description: "Error rate for AI agent requests"
      labels: ["error_type", "agent_type"]
    
    - name: "ai_batch_efficiency"
      description: "Efficiency of batch operations"
      labels: ["batch_size", "success_rate"]
  
  alerts:
    - condition: "ai_error_rate > 0.05"
      action: "notify_ops_team"
      message: "High AI agent error rate detected"
    
    - condition: "ai_agent_requests == 0 for 5m"
      action: "check_mcp_server_health"
      message: "No AI agent activity detected"

# Performance tracking
x-performance-sla:
  response_time_p95: "500ms"
  response_time_p99: "1s"
  availability: "99.9%"
  error_rate_threshold: "1%"
  
  ai_specific:
    batch_operation_timeout: "30s"
    mcp_tool_generation_time: "2s"
    cache_hit_rate_target: "80%"
```

---

*Next: [FastAPI OpenAPI Best Practices](./fastapi-openapi-best-practices.md) - Learn FastAPI-specific patterns for AI-ready API documentation*
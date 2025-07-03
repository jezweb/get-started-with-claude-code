# Structured Output Patterns

Comprehensive guide to generating reliable structured outputs from AI models, including JSON schemas, validation, and error handling strategies.

## 🎯 What is Structured Output?

Structured output ensures AI responses conform to specific formats:
- **Type Safety** - Guaranteed response structure
- **Validation** - Schema-based output validation  
- **Parsing** - Reliable data extraction
- **Integration** - Direct API/database compatibility
- **Error Handling** - Graceful failure modes
- **Consistency** - Predictable response formats

## 🚀 Quick Start

### Basic JSON Generation

```javascript
// Simple structured output with JSON
async function generateStructuredData(prompt, schema) {
  const systemPrompt = `You are a helpful assistant that always responds with valid JSON matching the provided schema.
  
Schema:
${JSON.stringify(schema, null, 2)}

Important: Respond ONLY with valid JSON. No explanations or markdown.`

  const response = await fetch('/api/ai/complete', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3, // Lower temperature for consistency
      response_format: { type: 'json_object' } // OpenAI JSON mode
    })
  })
  
  const data = await response.json()
  return JSON.parse(data.choices[0].message.content)
}

// Example usage
const schema = {
  type: 'object',
  properties: {
    name: { type: 'string' },
    age: { type: 'number' },
    skills: { 
      type: 'array',
      items: { type: 'string' }
    }
  },
  required: ['name', 'age']
}

const result = await generateStructuredData(
  'Extract person details from: John Doe is 28 years old and knows Python and JavaScript',
  schema
)
```

### Schema-First Approach

```javascript
// Define schemas using JSON Schema
const schemas = {
  product: {
    type: 'object',
    properties: {
      id: { type: 'string', pattern: '^[A-Z0-9]{8}$' },
      name: { type: 'string', minLength: 1, maxLength: 100 },
      price: { type: 'number', minimum: 0 },
      category: { 
        type: 'string',
        enum: ['electronics', 'clothing', 'food', 'other']
      },
      inStock: { type: 'boolean' },
      specifications: {
        type: 'object',
        additionalProperties: { type: 'string' }
      }
    },
    required: ['id', 'name', 'price', 'category', 'inStock']
  },
  
  customer: {
    type: 'object',
    properties: {
      id: { type: 'string', format: 'uuid' },
      email: { type: 'string', format: 'email' },
      name: {
        type: 'object',
        properties: {
          first: { type: 'string' },
          last: { type: 'string' }
        },
        required: ['first', 'last']
      },
      address: {
        type: 'object',
        properties: {
          street: { type: 'string' },
          city: { type: 'string' },
          state: { type: 'string', pattern: '^[A-Z]{2}$' },
          zip: { type: 'string', pattern: '^\\d{5}$' }
        }
      },
      preferences: {
        type: 'array',
        items: { type: 'string' }
      }
    },
    required: ['id', 'email', 'name']
  }
}
```

## 🧠 Core Patterns

### Reliable JSON Extraction

```javascript
// Robust JSON extraction with validation
class StructuredOutputExtractor {
  constructor(options = {}) {
    this.maxRetries = options.maxRetries || 3
    this.validator = options.validator || this.defaultValidator
  }
  
  async extract(prompt, schema, options = {}) {
    let lastError = null
    
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        // Generate response
        const response = await this.generateResponse(prompt, schema, options)
        
        // Extract JSON from response
        const extracted = this.extractJSON(response)
        
        // Validate against schema
        const validated = await this.validator(extracted, schema)
        
        if (validated.valid) {
          return {
            success: true,
            data: validated.data,
            attempts: attempt
          }
        }
        
        lastError = validated.errors
        
        // Add validation errors to prompt for retry
        if (attempt < this.maxRetries) {
          prompt = this.addErrorContext(prompt, validated.errors)
        }
        
      } catch (error) {
        lastError = error
        
        if (attempt === this.maxRetries) {
          throw new Error(`Failed after ${this.maxRetries} attempts: ${error.message}`)
        }
      }
    }
    
    return {
      success: false,
      error: lastError,
      attempts: this.maxRetries
    }
  }
  
  extractJSON(text) {
    // Try multiple extraction strategies
    
    // Strategy 1: Full response is JSON
    try {
      return JSON.parse(text)
    } catch (e) {}
    
    // Strategy 2: JSON in code blocks
    const codeBlockMatch = text.match(/```(?:json)?\s*\n([\s\S]*?)\n```/)
    if (codeBlockMatch) {
      try {
        return JSON.parse(codeBlockMatch[1])
      } catch (e) {}
    }
    
    // Strategy 3: Find JSON object/array
    const jsonMatch = text.match(/({[\s\S]*}|\[[\s\S]*\])/)
    if (jsonMatch) {
      try {
        return JSON.parse(jsonMatch[1])
      } catch (e) {}
    }
    
    // Strategy 4: Line by line search
    const lines = text.split('\n')
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (line.startsWith('{') || line.startsWith('[')) {
        try {
          // Try to parse from this line to the end
          const remaining = lines.slice(i).join('\n')
          return JSON.parse(remaining)
        } catch (e) {}
      }
    }
    
    throw new Error('No valid JSON found in response')
  }
  
  async generateResponse(prompt, schema, options) {
    const systemPrompt = this.buildSystemPrompt(schema, options)
    
    const response = await fetch('/api/ai/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: options.model || 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: prompt }
        ],
        temperature: options.temperature || 0.3,
        max_tokens: options.maxTokens || 1000
      })
    })
    
    const data = await response.json()
    return data.choices[0].message.content
  }
  
  buildSystemPrompt(schema, options) {
    let prompt = `You are a JSON generator. Always respond with valid JSON that matches this schema:

${JSON.stringify(schema, null, 2)}

Rules:
1. Output ONLY valid JSON - no explanations, markdown, or extra text
2. Ensure all required fields are present
3. Match exact data types specified
4. Use null for missing optional values
5. Follow any patterns or constraints in the schema`

    if (options.examples) {
      prompt += '\n\nExamples:\n'
      options.examples.forEach((example, i) => {
        prompt += `Example ${i + 1}: ${JSON.stringify(example)}\n`
      })
    }
    
    return prompt
  }
  
  async defaultValidator(data, schema) {
    // Simple validation - use a proper JSON Schema validator in production
    const errors = []
    
    if (schema.type === 'object' && schema.properties) {
      // Check required fields
      if (schema.required) {
        for (const field of schema.required) {
          if (!(field in data)) {
            errors.push(`Missing required field: ${field}`)
          }
        }
      }
      
      // Check property types
      for (const [key, propSchema] of Object.entries(schema.properties)) {
        if (key in data) {
          const value = data[key]
          const type = Array.isArray(value) ? 'array' : typeof value
          
          if (type !== propSchema.type && value !== null) {
            errors.push(`Invalid type for ${key}: expected ${propSchema.type}, got ${type}`)
          }
        }
      }
    }
    
    return {
      valid: errors.length === 0,
      errors,
      data
    }
  }
  
  addErrorContext(prompt, errors) {
    return `${prompt}

Previous attempt had these validation errors:
${errors.join('\n')}

Please fix these errors and provide valid JSON.`
  }
}
```

### Function Calling Pattern

```javascript
// Structured function calling implementation
class FunctionCallingSystem {
  constructor() {
    this.functions = new Map()
  }
  
  registerFunction(definition) {
    this.functions.set(definition.name, {
      definition,
      handler: definition.handler
    })
  }
  
  async processPrompt(prompt) {
    // Step 1: Determine function to call
    const functionCall = await this.selectFunction(prompt)
    
    if (!functionCall) {
      return {
        type: 'text',
        content: 'I cannot help with that request.'
      }
    }
    
    // Step 2: Extract parameters
    const parameters = await this.extractParameters(
      prompt,
      functionCall.function,
      functionCall.parameters
    )
    
    // Step 3: Validate parameters
    const validation = this.validateParameters(
      parameters,
      functionCall.function.parameters
    )
    
    if (!validation.valid) {
      return {
        type: 'error',
        content: `Invalid parameters: ${validation.errors.join(', ')}`
      }
    }
    
    // Step 4: Execute function
    try {
      const result = await functionCall.handler(parameters)
      
      return {
        type: 'function_result',
        function: functionCall.function.name,
        result
      }
    } catch (error) {
      return {
        type: 'error',
        content: `Function execution failed: ${error.message}`
      }
    }
  }
  
  async selectFunction(prompt) {
    const functionDefinitions = Array.from(this.functions.values())
      .map(f => f.definition)
    
    const systemPrompt = `You are a function selector. Given a user request, determine which function to call.

Available functions:
${JSON.stringify(functionDefinitions, null, 2)}

Respond with JSON in this format:
{
  "function": "function_name",
  "reasoning": "why this function matches the request"
}

If no function matches, respond with:
{
  "function": null,
  "reasoning": "why no function matches"
}`

    const response = await this.generateStructuredResponse(
      systemPrompt,
      prompt,
      {
        type: 'object',
        properties: {
          function: { type: ['string', 'null'] },
          reasoning: { type: 'string' }
        },
        required: ['function', 'reasoning']
      }
    )
    
    if (!response.function) return null
    
    const func = this.functions.get(response.function)
    return {
      function: func.definition,
      handler: func.handler
    }
  }
  
  async extractParameters(prompt, functionDef, parameterSchema) {
    const systemPrompt = `Extract parameters for the function "${functionDef.name}" from the user request.

Function description: ${functionDef.description}

Parameter schema:
${JSON.stringify(parameterSchema, null, 2)}

Respond with JSON containing the extracted parameters.`

    return await this.generateStructuredResponse(
      systemPrompt,
      prompt,
      parameterSchema
    )
  }
}

// Example function registration
const functionCalling = new FunctionCallingSystem()

functionCalling.registerFunction({
  name: 'searchProducts',
  description: 'Search for products in the catalog',
  parameters: {
    type: 'object',
    properties: {
      query: { type: 'string', description: 'Search query' },
      category: { 
        type: 'string',
        enum: ['electronics', 'clothing', 'food'],
        description: 'Product category'
      },
      maxPrice: { 
        type: 'number',
        description: 'Maximum price filter'
      },
      inStock: {
        type: 'boolean',
        description: 'Only show in-stock items'
      }
    },
    required: ['query']
  },
  handler: async (params) => {
    // Implementation
    return {
      products: [
        { id: '1', name: 'Product 1', price: 99.99 }
      ]
    }
  }
})
```

### Multi-Step Extraction

```javascript
// Complex multi-step data extraction
class MultiStepExtractor {
  constructor() {
    this.steps = []
  }
  
  addStep(name, extractor) {
    this.steps.push({ name, extractor })
    return this
  }
  
  async extract(input) {
    const results = {}
    let context = input
    
    for (const step of this.steps) {
      try {
        // Extract data for this step
        const stepResult = await step.extractor(context, results)
        
        // Store result
        results[step.name] = stepResult
        
        // Update context with accumulated results
        context = this.buildContext(input, results)
        
      } catch (error) {
        results[step.name] = {
          error: error.message,
          failed: true
        }
      }
    }
    
    return results
  }
  
  buildContext(originalInput, results) {
    return `Original input: ${originalInput}

Extracted so far:
${JSON.stringify(results, null, 2)}`
  }
}

// Example: Extract structured data from an email
const emailExtractor = new MultiStepExtractor()

emailExtractor
  .addStep('metadata', async (input) => {
    const schema = {
      type: 'object',
      properties: {
        from: { type: 'string', format: 'email' },
        to: { type: 'array', items: { type: 'string', format: 'email' } },
        subject: { type: 'string' },
        date: { type: 'string', format: 'date-time' },
        priority: { type: 'string', enum: ['low', 'normal', 'high'] }
      }
    }
    
    return await extractWithSchema(input, schema)
  })
  .addStep('intent', async (input, previous) => {
    const schema = {
      type: 'object',
      properties: {
        primaryIntent: { 
          type: 'string',
          enum: ['question', 'request', 'complaint', 'feedback', 'other']
        },
        urgency: { type: 'number', minimum: 1, maximum: 10 },
        requiresResponse: { type: 'boolean' },
        sentiment: { 
          type: 'string',
          enum: ['positive', 'neutral', 'negative']
        }
      }
    }
    
    return await extractWithSchema(input, schema)
  })
  .addStep('actionItems', async (input, previous) => {
    const schema = {
      type: 'object',
      properties: {
        tasks: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              description: { type: 'string' },
              assignee: { type: 'string' },
              deadline: { type: 'string', format: 'date' },
              priority: { type: 'string', enum: ['low', 'medium', 'high'] }
            }
          }
        },
        questions: {
          type: 'array',
          items: { type: 'string' }
        },
        decisions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              topic: { type: 'string' },
              options: { type: 'array', items: { type: 'string' } },
              deadline: { type: 'string', format: 'date' }
            }
          }
        }
      }
    }
    
    return await extractWithSchema(input, schema)
  })
```

### Constrained Generation

```javascript
// Generate text with strict constraints
class ConstrainedGenerator {
  async generateWithConstraints(prompt, constraints) {
    const {
      format,
      minLength,
      maxLength,
      allowedTokens,
      forbiddenTokens,
      pattern,
      validator
    } = constraints
    
    let attempts = 0
    const maxAttempts = 5
    
    while (attempts < maxAttempts) {
      attempts++
      
      // Build constrained prompt
      const constrainedPrompt = this.buildConstrainedPrompt(
        prompt,
        constraints
      )
      
      // Generate response
      const response = await this.generate(constrainedPrompt, {
        temperature: 0.3,
        max_tokens: maxLength ? Math.ceil(maxLength * 1.5) : 1000
      })
      
      // Validate response
      const validation = this.validateResponse(response, constraints)
      
      if (validation.valid) {
        return {
          success: true,
          content: validation.processed,
          attempts
        }
      }
      
      // Add validation feedback for next attempt
      prompt = `${prompt}\n\nPrevious attempt failed: ${validation.errors.join(', ')}`
    }
    
    throw new Error(`Failed to generate valid content after ${maxAttempts} attempts`)
  }
  
  buildConstrainedPrompt(prompt, constraints) {
    let systemPrompt = 'Generate a response with the following constraints:\n'
    
    if (constraints.format) {
      systemPrompt += `- Format: ${constraints.format}\n`
    }
    
    if (constraints.minLength) {
      systemPrompt += `- Minimum length: ${constraints.minLength} characters\n`
    }
    
    if (constraints.maxLength) {
      systemPrompt += `- Maximum length: ${constraints.maxLength} characters\n`
    }
    
    if (constraints.pattern) {
      systemPrompt += `- Must match pattern: ${constraints.pattern}\n`
    }
    
    if (constraints.allowedTokens) {
      systemPrompt += `- Can only use these words: ${constraints.allowedTokens.join(', ')}\n`
    }
    
    if (constraints.forbiddenTokens) {
      systemPrompt += `- Must NOT use these words: ${constraints.forbiddenTokens.join(', ')}\n`
    }
    
    return `${systemPrompt}\n\nRequest: ${prompt}`
  }
  
  validateResponse(response, constraints) {
    const errors = []
    let processed = response
    
    // Length validation
    if (constraints.minLength && response.length < constraints.minLength) {
      errors.push(`Too short: ${response.length} < ${constraints.minLength}`)
    }
    
    if (constraints.maxLength && response.length > constraints.maxLength) {
      errors.push(`Too long: ${response.length} > ${constraints.maxLength}`)
      processed = response.substring(0, constraints.maxLength)
    }
    
    // Pattern validation
    if (constraints.pattern) {
      const regex = new RegExp(constraints.pattern)
      if (!regex.test(response)) {
        errors.push(`Does not match pattern: ${constraints.pattern}`)
      }
    }
    
    // Token validation
    if (constraints.forbiddenTokens) {
      const found = constraints.forbiddenTokens.filter(token =>
        response.toLowerCase().includes(token.toLowerCase())
      )
      
      if (found.length > 0) {
        errors.push(`Contains forbidden tokens: ${found.join(', ')}`)
      }
    }
    
    // Custom validator
    if (constraints.validator) {
      const customValidation = constraints.validator(processed)
      if (!customValidation.valid) {
        errors.push(...customValidation.errors)
      }
    }
    
    return {
      valid: errors.length === 0,
      errors,
      processed
    }
  }
}
```

## 🔧 Advanced Patterns

### Type-Safe Generation with TypeScript

```typescript
// TypeScript interfaces for structured output
interface ProductOutput {
  id: string
  name: string
  description: string
  price: number
  currency: 'USD' | 'EUR' | 'GBP'
  availability: {
    inStock: boolean
    quantity?: number
    nextRestock?: string
  }
  categories: string[]
  specifications?: Record<string, string>
}

class TypedOutputGenerator<T> {
  constructor(private schema: JSONSchema) {}
  
  async generate(prompt: string): Promise<T> {
    const result = await this.generateStructured(prompt, this.schema)
    return this.validate<T>(result)
  }
  
  private async generateStructured(
    prompt: string,
    schema: JSONSchema
  ): Promise<unknown> {
    // Implementation
    const response = await this.callAI(prompt, schema)
    return JSON.parse(response)
  }
  
  private validate<T>(data: unknown): T {
    // Runtime validation matching TypeScript type
    // In production, use libraries like Zod or io-ts
    return data as T
  }
}

// Usage with type safety
const productGenerator = new TypedOutputGenerator<ProductOutput>(productSchema)
const product = await productGenerator.generate(
  'Extract product details from this description...'
)

// TypeScript knows the exact shape of 'product'
console.log(product.price) // number
console.log(product.availability.inStock) // boolean
```

### Streaming Structured Output

```javascript
// Stream structured data as it's generated
class StreamingStructuredOutput {
  async *streamJSON(prompt, schema) {
    const response = await fetch('/api/ai/stream', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt: this.buildPrompt(prompt, schema),
        stream: true
      })
    })
    
    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''
    let depth = 0
    let inString = false
    let escape = false
    
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      
      buffer += decoder.decode(value, { stream: true })
      
      // Parse JSON tokens as they arrive
      for (let i = 0; i < buffer.length; i++) {
        const char = buffer[i]
        
        if (!escape && char === '"') {
          inString = !inString
        } else if (!inString) {
          if (char === '{' || char === '[') depth++
          else if (char === '}' || char === ']') depth--
        }
        
        escape = !escape && char === '\\'
        
        // Yield complete JSON objects
        if (depth === 0 && (char === '}' || char === ']')) {
          const chunk = buffer.substring(0, i + 1)
          try {
            const parsed = JSON.parse(chunk)
            yield { type: 'partial', data: parsed }
            buffer = buffer.substring(i + 1)
            i = -1
          } catch (e) {
            // Continue accumulating
          }
        }
      }
    }
    
    // Final validation
    if (buffer.trim()) {
      try {
        const final = JSON.parse(buffer)
        yield { type: 'complete', data: final }
      } catch (e) {
        yield { type: 'error', error: 'Invalid JSON at end of stream' }
      }
    }
  }
  
  buildPrompt(userPrompt, schema) {
    return `Generate JSON matching this schema:
${JSON.stringify(schema, null, 2)}

Stream the JSON as you generate it. Start with { or [ immediately.

Request: ${userPrompt}`
  }
}

// Usage
const streamer = new StreamingStructuredOutput()

for await (const chunk of streamer.streamJSON(prompt, schema)) {
  if (chunk.type === 'partial') {
    console.log('Received partial:', chunk.data)
    // Update UI with partial data
  } else if (chunk.type === 'complete') {
    console.log('Complete:', chunk.data)
    // Final validation and processing
  }
}
```

### Self-Healing Output

```javascript
// Automatically fix common structured output errors
class SelfHealingOutput {
  constructor() {
    this.healers = [
      this.fixMissingQuotes,
      this.fixTrailingCommas,
      this.fixUnescapedQuotes,
      this.fixIncompleteJSON,
      this.fixMixedTypes
    ]
  }
  
  async extractAndHeal(text, schema) {
    // First attempt: direct parsing
    try {
      const parsed = JSON.parse(text)
      return this.validateAndFix(parsed, schema)
    } catch (e) {}
    
    // Apply healers
    let healed = text
    for (const healer of this.healers) {
      try {
        healed = healer.call(this, healed)
        const parsed = JSON.parse(healed)
        return this.validateAndFix(parsed, schema)
      } catch (e) {
        continue
      }
    }
    
    // Last resort: AI-assisted healing
    return this.aiAssistHeal(text, schema)
  }
  
  fixMissingQuotes(text) {
    // Fix unquoted keys
    return text.replace(/([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:/g, '$1"$2":')
  }
  
  fixTrailingCommas(text) {
    // Remove trailing commas
    return text.replace(/,\s*([}\]])/g, '$1')
  }
  
  fixUnescapedQuotes(text) {
    // Fix unescaped quotes in strings
    return text.replace(/"([^"]*)"([^:,}\]])/g, (match, p1, p2) => {
      const escaped = p1.replace(/"/g, '\\"')
      return `"${escaped}"${p2}`
    })
  }
  
  fixIncompleteJSON(text) {
    // Try to complete incomplete JSON
    const openBraces = (text.match(/{/g) || []).length
    const closeBraces = (text.match(/}/g) || []).length
    const openBrackets = (text.match(/\[/g) || []).length
    const closeBrackets = (text.match(/\]/g) || []).length
    
    let fixed = text
    
    // Add missing closing braces/brackets
    fixed += '}}'.repeat(openBraces - closeBraces)
    fixed += ']]'.repeat(openBrackets - closeBrackets)
    
    return fixed
  }
  
  fixMixedTypes(text) {
    // Fix common type mismatches
    let fixed = text
    
    // Convert string numbers to numbers
    fixed = fixed.replace(/"(\d+\.?\d*)"/g, '$1')
    
    // Convert string booleans to booleans
    fixed = fixed.replace(/"(true|false)"/g, '$1')
    
    // Convert 'null' strings to null
    fixed = fixed.replace(/"null"/g, 'null')
    
    return fixed
  }
  
  validateAndFix(data, schema) {
    // Apply schema-based fixes
    const fixed = this.applySchemaFixes(data, schema)
    
    // Validate fixed data
    const validation = this.validate(fixed, schema)
    
    if (validation.valid) {
      return fixed
    }
    
    throw new Error(`Validation failed: ${validation.errors.join(', ')}`)
  }
  
  applySchemaFixes(data, schema) {
    if (schema.type === 'object' && schema.properties) {
      const fixed = {}
      
      // Add required fields with defaults
      for (const [key, propSchema] of Object.entries(schema.properties)) {
        if (key in data) {
          fixed[key] = this.fixValue(data[key], propSchema)
        } else if (schema.required?.includes(key)) {
          fixed[key] = this.getDefault(propSchema)
        }
      }
      
      return fixed
    }
    
    return data
  }
  
  fixValue(value, schema) {
    // Type coercion based on schema
    switch (schema.type) {
      case 'number':
        return Number(value) || 0
        
      case 'boolean':
        return Boolean(value)
        
      case 'string':
        return String(value)
        
      case 'array':
        return Array.isArray(value) ? value : []
        
      case 'object':
        return typeof value === 'object' ? value : {}
        
      default:
        return value
    }
  }
  
  async aiAssistHeal(text, schema) {
    const prompt = `Fix this malformed JSON to match the schema:

Malformed JSON:
${text}

Target Schema:
${JSON.stringify(schema, null, 2)}

Respond with only the fixed JSON.`

    const response = await this.callAI(prompt)
    return JSON.parse(response)
  }
}
```

### Output Streaming with Validation

```javascript
// Stream and validate structured output in real-time
class ValidatingStreamProcessor {
  constructor(schema) {
    this.schema = schema
    this.validator = new StreamingValidator(schema)
  }
  
  async processStream(stream) {
    const reader = stream.getReader()
    const decoder = new TextDecoder()
    
    let buffer = ''
    const results = []
    
    while (true) {
      const { done, value } = await reader.read()
      
      if (done) {
        // Process remaining buffer
        if (buffer.trim()) {
          const final = await this.processBuffer(buffer)
          if (final) results.push(final)
        }
        break
      }
      
      buffer += decoder.decode(value, { stream: true })
      
      // Try to extract complete objects
      const { extracted, remaining } = this.extractObjects(buffer)
      buffer = remaining
      
      for (const obj of extracted) {
        const validated = await this.validateAndTransform(obj)
        if (validated) {
          results.push(validated)
          
          // Emit validated object immediately
          this.emit('object', validated)
        }
      }
    }
    
    return results
  }
  
  extractObjects(buffer) {
    const extracted = []
    let remaining = buffer
    
    // Simple extraction - in production use proper JSON streaming parser
    const lines = buffer.split('\n')
    
    for (const line of lines) {
      const trimmed = line.trim()
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          const obj = JSON.parse(trimmed)
          extracted.push(obj)
          remaining = remaining.replace(line + '\n', '')
        } catch (e) {
          // Keep in buffer
        }
      }
    }
    
    return { extracted, remaining }
  }
  
  async validateAndTransform(obj) {
    try {
      // Real-time validation
      const validated = await this.validator.validate(obj)
      
      // Apply transformations
      const transformed = this.transform(validated)
      
      return transformed
    } catch (error) {
      this.emit('validation-error', { object: obj, error })
      return null
    }
  }
  
  transform(obj) {
    // Apply business logic transformations
    return {
      ...obj,
      processed_at: new Date().toISOString(),
      version: '1.0'
    }
  }
}
```

## 🚀 Performance Optimization

### Caching Structured Outputs

```javascript
// Cache structured outputs for repeated queries
class StructuredOutputCache {
  constructor(options = {}) {
    this.cache = new Map()
    this.maxSize = options.maxSize || 1000
    this.ttl = options.ttl || 3600000 // 1 hour
  }
  
  async get(prompt, schema, generator) {
    const key = this.generateKey(prompt, schema)
    const cached = this.cache.get(key)
    
    if (cached && Date.now() - cached.timestamp < this.ttl) {
      return {
        ...cached.data,
        cached: true
      }
    }
    
    // Generate fresh
    const result = await generator(prompt, schema)
    
    // Cache result
    this.set(key, result)
    
    return result
  }
  
  generateKey(prompt, schema) {
    const hash = crypto.createHash('sha256')
    hash.update(prompt)
    hash.update(JSON.stringify(schema))
    return hash.digest('hex')
  }
  
  set(key, data) {
    // LRU eviction
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value
      this.cache.delete(firstKey)
    }
    
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    })
  }
}
```

### Batch Processing

```javascript
// Process multiple structured outputs efficiently
class BatchStructuredProcessor {
  constructor(options = {}) {
    this.batchSize = options.batchSize || 10
    this.concurrency = options.concurrency || 3
  }
  
  async processBatch(items, schema) {
    const batches = this.createBatches(items)
    const results = []
    
    // Process batches with controlled concurrency
    for (let i = 0; i < batches.length; i += this.concurrency) {
      const batchPromises = batches
        .slice(i, i + this.concurrency)
        .map(batch => this.processSingleBatch(batch, schema))
      
      const batchResults = await Promise.all(batchPromises)
      results.push(...batchResults.flat())
    }
    
    return results
  }
  
  createBatches(items) {
    const batches = []
    
    for (let i = 0; i < items.length; i += this.batchSize) {
      batches.push(items.slice(i, i + this.batchSize))
    }
    
    return batches
  }
  
  async processSingleBatch(batch, schema) {
    // Create batch prompt
    const batchPrompt = `Extract structured data for these ${batch.length} items:

${batch.map((item, i) => `Item ${i + 1}: ${item}`).join('\n\n')}

Return an array of JSON objects matching this schema:
${JSON.stringify(schema, null, 2)}`

    const response = await this.generateStructuredArray(batchPrompt, {
      type: 'array',
      items: schema
    })
    
    return response
  }
}
```

## 🔍 Testing & Validation

```javascript
// Comprehensive testing for structured outputs
class StructuredOutputTester {
  constructor(generator) {
    this.generator = generator
    this.testCases = []
  }
  
  addTestCase(name, input, schema, expected) {
    this.testCases.push({ name, input, schema, expected })
  }
  
  async runTests() {
    const results = []
    
    for (const testCase of this.testCases) {
      const startTime = Date.now()
      
      try {
        const output = await this.generator.generate(
          testCase.input,
          testCase.schema
        )
        
        const validation = this.validateOutput(
          output,
          testCase.schema,
          testCase.expected
        )
        
        results.push({
          name: testCase.name,
          success: validation.success,
          duration: Date.now() - startTime,
          details: validation
        })
      } catch (error) {
        results.push({
          name: testCase.name,
          success: false,
          error: error.message,
          duration: Date.now() - startTime
        })
      }
    }
    
    return this.generateReport(results)
  }
  
  validateOutput(output, schema, expected) {
    const validation = {
      schemaValid: this.validateSchema(output, schema),
      matchesExpected: expected ? this.compareOutput(output, expected) : null,
      metrics: this.calculateMetrics(output)
    }
    
    validation.success = validation.schemaValid && 
      (validation.matchesExpected?.match ?? true)
    
    return validation
  }
  
  generateReport(results) {
    const total = results.length
    const passed = results.filter(r => r.success).length
    const failed = total - passed
    const avgDuration = results.reduce((sum, r) => sum + r.duration, 0) / total
    
    return {
      summary: {
        total,
        passed,
        failed,
        successRate: (passed / total) * 100,
        avgDuration
      },
      results,
      recommendations: this.generateRecommendations(results)
    }
  }
}
```

## 📚 Best Practices

### 1. **Schema Design**
- Start with simple schemas and iterate
- Use strict types and constraints
- Include examples in schema documentation
- Version your schemas
- Test edge cases

### 2. **Prompt Engineering**
- Be explicit about output format
- Provide examples in prompts
- Use consistent terminology
- Include validation rules
- Handle ambiguity explicitly

### 3. **Error Handling**
- Implement retry logic
- Provide fallback responses
- Log failed attempts
- Monitor success rates
- Handle partial failures

### 4. **Performance**
- Cache common structures
- Batch similar requests
- Use streaming for large outputs
- Optimize token usage
- Monitor latency

### 5. **Validation**
- Validate at multiple levels
- Use schema validators
- Implement business logic checks
- Test with real data
- Handle missing fields gracefully

## 📖 Resources & References

### Schema Standards
- [JSON Schema](https://json-schema.org/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [TypeSchema](https://typeschema.org/)
- [Protocol Buffers](https://protobuf.dev/)

### Validation Libraries
- **Ajv** - JSON Schema validator
- **Joi** - Object schema validation
- **Zod** - TypeScript-first schema validation
- **Yup** - Schema builder for validation

### AI Platforms
- **OpenAI** - JSON mode and function calling
- **Anthropic** - Structured outputs
- **Google AI** - Structured generation
- **Cohere** - Structured endpoints

---

*This guide covers essential patterns for generating reliable structured outputs from AI models. Focus on schema design, validation, and error handling for production success.*
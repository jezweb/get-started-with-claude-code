# Gemini Structured Output Implementation Guide

*A comprehensive reference for implementing Google Gemini's structured output feature in Python applications*

## Overview

Google Gemini's structured output feature guarantees JSON-formatted responses that conform to a predefined schema. This eliminates JSON parsing errors and ensures reliable, predictable API responses.

## Benefits Over Manual JSON Parsing

### Before (Manual JSON Parsing)
```python
# Unreliable - prone to parsing errors
prompt = "Generate JSON with fields: analysis, document"
response = model.generate_content(prompt)
try:
    data = json.loads(response.text)  # Can fail with escape sequences
except json.JSONDecodeError:
    # Handle parsing errors
```

### After (Structured Output)
```python
# Guaranteed valid JSON structure
response_schema = types.Schema(
    type=types.Type.OBJECT,
    properties={
        "analysis": types.Schema(type=types.Type.STRING),
        "document": types.Schema(type=types.Type.STRING)
    },
    required=["analysis", "document"]
)
response = model.generate_content(prompt, generation_config={"response_schema": response_schema})
data = json.loads(response.text)  # Always succeeds
```

## Implementation Steps

### 1. Import Required Modules

```python
import google.generativeai as genai
import google.ai.generativelanguage as types
from typing import Tuple
import json
from pydantic import BaseModel, Field
```

### 2. Define Pydantic Models (Optional but Recommended)

```python
class AIDocumentResponse(BaseModel):
    analysis: str = Field(description="Internal analysis and reasoning process")
    document: str = Field(description="Complete professional document in Markdown format")
```

### 3. Create Response Schema

```python
def create_response_schema():
    """Create the structured output schema for Gemini API."""
    return types.Schema(
        type=types.Type.OBJECT,
        properties={
            "analysis": types.Schema(
                type=types.Type.STRING,
                description="Internal analysis and reasoning"
            ),
            "document": types.Schema(
                type=types.Type.STRING,
                description="Complete professional document"
            )
        },
        required=["analysis", "document"]
    )
```

### 4. Generate Content with Structured Output

```python
def generate_document_with_structured_output(
    contents: list, 
    model_name: str = 'gemini-2.0-flash-001'
) -> Tuple[str, str]:
    """
    Generate document using Gemini structured output.
    
    Args:
        contents: List of content parts (text, images, etc.)
        model_name: Gemini model to use
        
    Returns:
        Tuple of (analysis, document)
    """
    # Configure API
    genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
    model = genai.GenerativeModel(model_name)
    
    # Create schema
    response_schema = create_response_schema()
    
    # Generate with structured output
    response = model.generate_content(
        contents,
        generation_config={
            "response_schema": response_schema,
            "temperature": 0.7,
            "max_output_tokens": 8192
        }
    )
    
    # Parse guaranteed-valid JSON
    data = json.loads(response.text)
    
    return data["analysis"], data["document"]
```

## Complete Working Example

```python
import os
import json
import google.generativeai as genai
import google.ai.generativelanguage as types
from typing import Tuple
from pydantic import BaseModel, Field

class DocumentResponse(BaseModel):
    analysis: str = Field(description="AI's internal analysis")
    document: str = Field(description="Generated document content")

def generate_structured_document(prompt: str, document_type: str) -> Tuple[str, str]:
    """Generate a document with guaranteed JSON structure."""
    
    # Configure API
    genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
    model = genai.GenerativeModel('gemini-2.0-flash-001')
    
    # Define response schema
    response_schema = types.Schema(
        type=types.Type.OBJECT,
        properties={
            "analysis": types.Schema(
                type=types.Type.STRING,
                description="Internal analysis, reasoning, and observations"
            ),
            "document": types.Schema(
                type=types.Type.STRING,
                description="Complete professional document in Markdown format"
            )
        },
        required=["analysis", "document"]
    )
    
    # Enhanced prompt for structured output
    full_prompt = f"""
    You are a professional {document_type} specialist. 
    
    TASK: {prompt}
    
    RESPONSE FORMAT:
    - analysis: Your internal reasoning, calculations, and observations
    - document: The complete professional document in Markdown format
    
    Ensure the document is properly formatted with clear headings and professional structure.
    """
    
    try:
        # Generate content with structured output
        response = model.generate_content(
            full_prompt,
            generation_config={
                "response_schema": response_schema,
                "temperature": 0.7,
                "max_output_tokens": 8192
            }
        )
        
        # Parse the guaranteed-valid JSON
        data = json.loads(response.text)
        
        # Validate with Pydantic (optional)
        validated = DocumentResponse(**data)
        
        return validated.analysis, validated.document
        
    except Exception as e:
        raise Exception(f"Error generating structured document: {e}")

# Usage example
if __name__ == "__main__":
    analysis, document = generate_structured_document(
        prompt="Create an electrical quote for a 3-bedroom house",
        document_type="electrical contractor"
    )
    
    print("AI Analysis:")
    print(analysis)
    print("\nGenerated Document:")
    print(document)
```

## Schema Types Reference

### Basic Types
```python
# String
types.Schema(type=types.Type.STRING)

# Number (integer or float)
types.Schema(type=types.Type.NUMBER)

# Integer only
types.Schema(type=types.Type.INTEGER)

# Boolean
types.Schema(type=types.Type.BOOLEAN)

# Array
types.Schema(
    type=types.Type.ARRAY,
    items=types.Schema(type=types.Type.STRING)
)

# Object
types.Schema(
    type=types.Type.OBJECT,
    properties={
        "field1": types.Schema(type=types.Type.STRING),
        "field2": types.Schema(type=types.Type.NUMBER)
    },
    required=["field1"]
)
```

### Complex Schema Example
```python
def create_complex_schema():
    return types.Schema(
        type=types.Type.OBJECT,
        properties={
            "metadata": types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "document_type": types.Schema(type=types.Type.STRING),
                    "client_name": types.Schema(type=types.Type.STRING),
                    "date_generated": types.Schema(type=types.Type.STRING)
                }
            ),
            "analysis": types.Schema(type=types.Type.STRING),
            "document": types.Schema(type=types.Type.STRING),
            "line_items": types.Schema(
                type=types.Type.ARRAY,
                items=types.Schema(
                    type=types.Type.OBJECT,
                    properties={
                        "description": types.Schema(type=types.Type.STRING),
                        "quantity": types.Schema(type=types.Type.INTEGER),
                        "price": types.Schema(type=types.Type.NUMBER)
                    }
                )
            ),
            "total_cost": types.Schema(type=types.Type.NUMBER)
        },
        required=["analysis", "document", "total_cost"]
    )
```

## Error Handling Best Practices

```python
def safe_structured_generation(prompt: str) -> dict:
    """Generate content with comprehensive error handling."""
    try:
        # Configure API
        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
        
        if not os.getenv('GEMINI_API_KEY'):
            raise ValueError("GEMINI_API_KEY environment variable not set")
        
        model = genai.GenerativeModel('gemini-2.0-flash-001')
        response_schema = create_response_schema()
        
        # Generate with structured output
        response = model.generate_content(
            prompt,
            generation_config={
                "response_schema": response_schema,
                "temperature": 0.7,
                "max_output_tokens": 8192
            }
        )
        
        # Parse JSON (should always succeed with structured output)
        data = json.loads(response.text)
        
        # Additional validation
        if not data.get("analysis") or not data.get("document"):
            raise ValueError("Response missing required fields")
            
        return data
        
    except json.JSONDecodeError as e:
        # This should never happen with structured output
        raise Exception(f"Unexpected JSON parsing error: {e}")
    except Exception as e:
        # Log the error and provide fallback
        print(f"Error in structured generation: {e}")
        raise
```

## FastAPI Integration Example

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class DocumentRequest(BaseModel):
    document_type: str
    prompt: str
    client_name: str = None

class DocumentResponse(BaseModel):
    analysis: str
    document: str
    document_id: str

@app.post("/generate-document", response_model=DocumentResponse)
async def generate_document(request: DocumentRequest):
    """Generate document using Gemini structured output."""
    try:
        analysis, document = generate_structured_document(
            prompt=request.prompt,
            document_type=request.document_type
        )
        
        # Save to database and get ID
        document_id = save_document_to_db(analysis, document, request.client_name)
        
        return DocumentResponse(
            analysis=analysis,
            document=document,
            document_id=document_id
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Prompt Engineering for Structured Output

### Effective Prompt Structure
```python
def create_structured_prompt(document_type: str, context: str) -> str:
    return f"""
You are a professional {document_type} specialist with extensive experience.

CONTEXT: {context}

INSTRUCTIONS:
1. Analyze the provided information thoroughly
2. Generate a professional {document_type}
3. Structure your response with both analysis and final document

ANALYSIS FIELD REQUIREMENTS:
- Document your reasoning process
- Note any assumptions made
- Include relevant calculations or observations
- Mention standards or regulations considered

DOCUMENT FIELD REQUIREMENTS:
- Use proper Markdown formatting
- Include clear headings and sections
- Provide itemized details where appropriate
- Ensure professional presentation suitable for clients

Generate your response in the specified JSON structure.
"""
```

## Migration Guide: Manual JSON → Structured Output

### Step 1: Identify Current JSON Parsing
```python
# OLD CODE
response = model.generate_content(prompt + "\n\nProvide response as JSON")
try:
    data = json.loads(response.text)
except:
    # Handle errors
```

### Step 2: Define Schema
```python
# NEW CODE
response_schema = types.Schema(
    type=types.Type.OBJECT,
    properties={
        # Define your expected fields here
    },
    required=["required_field_names"]
)
```

### Step 3: Update Generation Call
```python
# NEW CODE
response = model.generate_content(
    prompt,  # Remove JSON instructions from prompt
    generation_config={"response_schema": response_schema}
)
data = json.loads(response.text)  # Will always succeed
```

## Troubleshooting

### Common Issues

1. **Schema Validation Errors**
   - Ensure all required fields are specified
   - Check that property names match exactly
   - Verify nested object structures

2. **API Key Issues**
   ```python
   # Always check API key is set
   if not os.getenv('GEMINI_API_KEY'):
       raise ValueError("GEMINI_API_KEY not configured")
   ```

3. **Model Compatibility**
   - Use `gemini-2.0-flash-001` or newer
   - Older models may not support structured output

4. **Response Size Limits**
   - Set appropriate `max_output_tokens`
   - Consider breaking large documents into sections

### Debug Output
```python
def debug_structured_response(response):
    """Debug helper for structured output responses."""
    print(f"Response text length: {len(response.text)}")
    print(f"Response text preview: {response.text[:200]}...")
    
    try:
        data = json.loads(response.text)
        print(f"Parsed JSON keys: {data.keys()}")
        for key, value in data.items():
            print(f"  {key}: {type(value)} ({len(str(value))} chars)")
    except Exception as e:
        print(f"JSON parsing failed: {e}")
```

## Performance Considerations

- **Caching**: Consider caching schemas for reuse
- **Timeouts**: Set appropriate timeout values for long documents
- **Rate Limiting**: Implement rate limiting for production use
- **Model Selection**: Use `gemini-2.0-flash-001` for best performance

## Security Notes

- Never include sensitive data in prompts
- Validate all user inputs before sending to API
- Store API keys securely using environment variables
- Implement proper error handling to avoid data leaks

---

*This guide covers Google Gemini structured output implementation as used in SparkyAI MVP-04. For latest API documentation, see [Google AI Platform docs](https://ai.google.dev/gemini-api/docs/structured-output).*
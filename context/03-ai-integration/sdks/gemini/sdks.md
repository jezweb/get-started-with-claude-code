# Google Gemini SDKs and Programming Language Support

## Overview
Google provides comprehensive SDKs for integrating Gemini API capabilities across multiple programming languages. The new Google GenAI SDK offers a unified interface for accessing all Gemini features with consistent APIs across platforms.

## Available SDKs

### Current Generation (Recommended)
These SDKs provide the latest features and long-term support:

#### Python SDK
- **Package**: `google-genai`
- **Installation**: `pip install google-genai`
- **Features**: Full API support, async operations, streaming
- **Documentation**: Complete with examples and tutorials

#### JavaScript/TypeScript SDK
- **Package**: `@google/genai`
- **Installation**: `npm install @google/genai`
- **Features**: Browser and Node.js support, TypeScript definitions
- **Compatibility**: Works with modern JavaScript frameworks

#### Go SDK
- **Package**: `google.golang.org/genai`
- **Installation**: `go get google.golang.org/genai`
- **Features**: Idiomatic Go interfaces, concurrent operations
- **Performance**: Optimized for high-throughput applications

#### Java SDK
- **Package**: `google-genai`
- **Distribution**: Maven Central
- **Features**: Enterprise-ready, Spring Boot integration
- **Compatibility**: Java 8+ support

### Legacy SDKs (Maintenance Mode)
Support until September 2025, migration recommended:

#### Previous Python SDK
- **Package**: `google-generativeai`
- **Status**: Maintenance mode
- **Migration**: Recommended to switch to `google-genai`

#### Platform-Specific SDKs
- **Dart/Flutter**: Not actively maintained
- **Swift**: Not actively maintained
- **Android**: Not actively maintained

## Python SDK

### Installation and Setup
```bash
# Install the SDK
pip install google-genai

# For development with additional features
pip install google-genai[dev]
```

### Basic Usage
```python
from google import genai

# Initialize client (API key from environment variable GEMINI_API_KEY)
client = genai.Client()

# Alternative: Pass API key directly
# client = genai.Client(api_key=\"your-api-key\")

# Generate content
response = client.models.generate_content(
    model=\"gemini-2.5-flash\",
    contents=\"Explain quantum computing\"
)
print(response.text)
```

### Advanced Python Features
```python
# Async operations
import asyncio

async def async_generation():
    client = genai.Client()
    response = await client.models.generate_content_async(
        model="gemini-2.5-flash",
        contents=\"Write a short story\")
    return response.text

# Streaming responses
def streaming_example():
    client = genai.Client()
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=\"Count from 1 to 10\", stream=True)
    
    for chunk in response:
        print(chunk.text, end='', flush=True)

# Batch processing
def batch_processing():
    client = genai.Client()
    
    prompts = [\"Explain AI\", \"Describe machine learning\", \"What is deep learning?\"]
    responses = []
    
    for prompt in prompts:\n        response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt)\n        responses.append(response.text)\n    \n    return responses\n\n# File handling\ndef file_upload_example():\n    # Upload file\n    file = client.files.upload(path=\"document.pdf\")\n    \n    # Use in generation\n    client = genai.Client()\n    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[\"Summarize this document\", file])\n    \n    return response.text\n```\n\n### Error Handling\n```python\nfrom google.genai import types\nfrom google import genai\n\ndef robust_generation(prompt: str):\n    \"\"\"Generate content with comprehensive error handling.\"\"\"\n    try:\n        model = genai.GenerativeModel(\n            'gemini-2.5-flash',\n            generation_config=GenerationConfig(\n                temperature=0.7,\n                max_output_tokens=1000,\n            )\n        )\n        \n        response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt)\n        \n        # Check for safety blocks\n        if response.candidates[0].finish_reason == \"SAFETY\":\n            return {\"error\": \"Content blocked by safety filters\", \"content\": None}\n        \n        # Check for length limits\n        if response.candidates[0].finish_reason == \"MAX_TOKENS\":\n            return {\"warning\": \"Response truncated\", \"content\": response.text}\n        \n        return {\"success\": True, \"content\": response.text}\n        \n    except Exception as e:\n        return {\"error\": f\"Generation failed: {str(e)}\", \"content\": None}\n```\n\n## JavaScript/TypeScript SDK\n\n### Installation and Setup\n```bash\n# Install via npm\nnpm install @google/genai\n\n# Install via yarn\nyarn add @google/genai\n```\n\n### Basic Usage\n```javascript\nimport { GoogleGenerativeAI } from '@google/genai';\n\n// Initialize the client\nconst genAI = new GoogleGenerativeAI('your-api-key');\n\n// Get a model\nconst model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });\n\n// Generate content\nasync function generateContent() {\n  const result = await model.generateContent('Explain the solar system');\n  const response = await result.response;\n  console.log(response.text());\n}\n\ngenerateContent();\n```\n\n### TypeScript Support\n```typescript\nimport { \n  GoogleGenerativeAI, \n  GenerativeModel, \n  GenerateContentResult \n} from '@google/genai';\n\ninterface GenerationOptions {\n  temperature?: number;\n  maxOutputTokens?: number;\n  topK?: number;\n  topP?: number;\n}\n\nclass GeminiClient {\n  private model: GenerativeModel;\n  \n  constructor(apiKey: string, modelName: string = 'gemini-2.5-flash') {\n    const genAI = new GoogleGenerativeAI(apiKey);\n    this.model = genAI.getGenerativeModel({ model: modelName });\n  }\n  \n  async generateText(\n    prompt: string, \n    options?: GenerationOptions\n  ): Promise<string> {\n    try {\n      const generationConfig = {\n        temperature: options?.temperature ?? 0.7,\n        maxOutputTokens: options?.maxOutputTokens ?? 1000,\n        topK: options?.topK ?? 40,\n        topP: options?.topP ?? 0.95,\n      };\n      \n      const result = await this.model.generateContent({\n        contents: [{ role: 'user', parts: [{ text: prompt }] }],\n        generationConfig\n      });\n      \n      const response = await result.response;\n      return response.text();\n      \n    } catch (error) {\n      throw new Error(`Generation failed: ${error}`);\n    }\n  }\n  \n  async streamContent(prompt: string): Promise<AsyncGenerator<string>> {\n    const result = await this.model.generateContentStream(prompt);\n    \n    for await (const chunk of result.stream) {\n      const chunkText = chunk.text();\n      if (chunkText) {\n        yield chunkText;\n      }\n    }\n  }\n}\n\n// Usage\nconst client = new GeminiClient('your-api-key');\n\nasync function example() {\n  // Basic generation\n  const response = await client.generateText('Explain machine learning');\n  console.log(response);\n  \n  // Streaming\n  for await (const chunk of client.streamContent('Write a story')) {\n    process.stdout.write(chunk);\n  }\n}\n```\n\n### Browser Integration\n```html\n<!DOCTYPE html>\n<html>\n<head>\n    <title>Gemini Web App</title>\n</head>\n<body>\n    <div id=\"output\"></div>\n    <input type=\"text\" id=\"prompt\" placeholder=\"Enter your prompt\">\n    <button onclick=\"generateContent()\">Generate</button>\n    \n    <script type=\"module\">\n        import { GoogleGenerativeAI } from 'https://esm.run/@google/genai';\n        \n        const genAI = new GoogleGenerativeAI('your-api-key');\n        const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });\n        \n        window.generateContent = async function() {\n            const prompt = document.getElementById('prompt').value;\n            const output = document.getElementById('output');\n            \n            try {\n                const result = await model.generateContent(prompt);\n                const response = await result.response;\n                output.innerHTML = response.text();\n            } catch (error) {\n                output.innerHTML = `Error: ${error.message}`;\n            }\n        }\n    </script>\n</body>\n</html>\n```\n\n## Go SDK\n\n### Installation and Setup\n```bash\n# Install the SDK\ngo get google.golang.org/genai\n```\n\n### Basic Usage\n```go\npackage main\n\nimport (\n    \"context\"\n    \"fmt\"\n    \"log\"\n    \n    \"google.golang.org/genai\"\n)\n\nfunc main() {\n    ctx := context.Background()\n    \n    // Create client\n    client, err := genai.NewClient(ctx, \"your-api-key\")\n    if err != nil {\n        log.Fatal(err)\n    }\n    defer client.Close()\n    \n    // Get model\n    model := client.GenerativeModel(\"gemini-2.5-flash\")\n    \n    // Generate content\n    response, err := model.GenerateContent(ctx, genai.Text(\"Explain Go programming\"))\n    if err != nil {\n        log.Fatal(err)\n    }\n    \n    fmt.Println(response.Candidates[0].Content.Parts[0])\n}\n```\n\n### Advanced Go Features\n```go\npackage main\n\nimport (\n    \"context\"\n    \"fmt\"\n    \"io\"\n    \"log\"\n    \n    \"google.golang.org/genai\"\n)\n\n// GeminiService wraps the Gemini client with additional functionality\ntype GeminiService struct {\n    client *genai.Client\n    model  *genai.GenerativeModel\n}\n\n// NewGeminiService creates a new service instance\nfunc NewGeminiService(ctx context.Context, apiKey string) (*GeminiService, error) {\n    client, err := genai.NewClient(ctx, apiKey)\n    if err != nil {\n        return nil, err\n    }\n    \n    model := client.GenerativeModel(\"gemini-2.5-flash\")\n    model.SetTemperature(0.7)\n    model.SetMaxOutputTokens(1000)\n    \n    return &GeminiService{\n        client: client,\n        model:  model,\n    }, nil\n}\n\n// GenerateText generates text from a prompt\nfunc (g *GeminiService) GenerateText(ctx context.Context, prompt string) (string, error) {\n    response, err := g.model.GenerateContent(ctx, genai.Text(prompt))\n    if err != nil {\n        return \"\", fmt.Errorf(\"generation failed: %w\", err)\n    }\n    \n    if len(response.Candidates) == 0 {\n        return \"\", fmt.Errorf(\"no candidates in response\")\n    }\n    \n    return fmt.Sprintf(\"%v\", response.Candidates[0].Content.Parts[0]), nil\n}\n\n// StreamContent streams content generation\nfunc (g *GeminiService) StreamContent(ctx context.Context, prompt string, output io.Writer) error {\n    iter := g.model.GenerateContentStream(ctx, genai.Text(prompt))\n    \n    for {\n        response, err := iter.Next()\n        if err == iterator.Done {\n            break\n        }\n        if err != nil {\n            return fmt.Errorf(\"stream error: %w\", err)\n        }\n        \n        for _, candidate := range response.Candidates {\n            for _, part := range candidate.Content.Parts {\n                fmt.Fprint(output, part)\n            }\n        }\n    }\n    \n    return nil\n}\n\n// ProcessWithFile processes content with file input\nfunc (g *GeminiService) ProcessWithFile(ctx context.Context, prompt string, filePath string) (string, error) {\n    file, err := g.client.UploadFile(ctx, filePath, nil)\n    if err != nil {\n        return \"\", fmt.Errorf(\"file upload failed: %w\", err)\n    }\n    \n    response, err := g.model.GenerateContent(ctx, \n        genai.Text(prompt),\n        genai.FileData{URI: file.URI},\n    )\n    if err != nil {\n        return \"\", fmt.Errorf(\"generation with file failed: %w\", err)\n    }\n    \n    return fmt.Sprintf(\"%v\", response.Candidates[0].Content.Parts[0]), nil\n}\n\n// Close closes the client connection\nfunc (g *GeminiService) Close() error {\n    return g.client.Close()\n}\n\nfunc main() {\n    ctx := context.Background()\n    \n    service, err := NewGeminiService(ctx, \"your-api-key\")\n    if err != nil {\n        log.Fatal(err)\n    }\n    defer service.Close()\n    \n    // Generate text\n    text, err := service.GenerateText(ctx, \"Explain concurrency in Go\")\n    if err != nil {\n        log.Fatal(err)\n    }\n    fmt.Println(text)\n    \n    // Stream content\n    fmt.Println(\"\\n--- Streaming content ---\")\n    err = service.StreamContent(ctx, \"Write a short poem about programming\", os.Stdout)\n    if err != nil {\n        log.Fatal(err)\n    }\n}\n```\n\n## Java SDK\n\n### Installation and Setup\n```xml\n<!-- Maven dependency -->\n<dependency>\n    <groupId>com.google.genai</groupId>\n    <artifactId>google-genai</artifactId>\n    <version>1.0.0</version>\n</dependency>\n```\n\n```gradle\n// Gradle dependency\nimplementation 'com.google.genai:google-genai:1.0.0'\n```\n\n### Basic Usage\n```java\nimport com.google.genai.GenerativeAI;\nimport com.google.genai.GenerativeModel;\nimport com.google.genai.GenerateContentResponse;\n\npublic class GeminiExample {\n    public static void main(String[] args) {\n        // Initialize client\n        GenerativeAI genAI = new GenerativeAI(\"your-api-key\");\n        \n        // Get model\n        GenerativeModel model = genAI.getGenerativeModel(\"gemini-2.5-flash\");\n        \n        try {\n            // Generate content\n            GenerateContentResponse response = model.generateContent(\"Explain Java programming\");\n            System.out.println(response.getText());\n        } catch (Exception e) {\n            System.err.println(\"Generation failed: \" + e.getMessage());\n        }\n    }\n}\n```\n\n### Spring Boot Integration\n```java\nimport org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\nimport org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\nimport org.springframework.web.bind.annotation.*;\n\nimport com.google.genai.GenerativeAI;\nimport com.google.genai.GenerativeModel;\n\n@SpringBootApplication\npublic class GeminiApplication {\n    public static void main(String[] args) {\n        SpringApplication.run(GeminiApplication.class, args);\n    }\n}\n\n@Configuration\nclass GeminiConfig {\n    \n    @Bean\n    public GenerativeAI generativeAI() {\n        return new GenerativeAI(System.getenv(\"GEMINI_API_KEY\"));\n    }\n    \n    @Bean\n    public GenerativeModel generativeModel(GenerativeAI genAI) {\n        return genAI.getGenerativeModel(\"gemini-2.5-flash\");\n    }\n}\n\n@RestController\n@RequestMapping(\"/api/gemini\")\nclass GeminiController {\n    \n    private final GenerativeModel model;\n    \n    public GeminiController(GenerativeModel model) {\n        this.model = model;\n    }\n    \n    @PostMapping(\"/generate\")\n    public ResponseEntity<String> generateContent(@RequestBody GenerationRequest request) {\n        try {\n            var response = model.generateContent(request.getPrompt());\n            return ResponseEntity.ok(response.getText());\n        } catch (Exception e) {\n            return ResponseEntity.status(500).body(\"Error: \" + e.getMessage());\n        }\n    }\n    \n    @PostMapping(\"/chat\")\n    public ResponseEntity<String> chatCompletion(@RequestBody ChatRequest request) {\n        try {\n            var chat = model.startChat();\n            var response = chat.sendMessage(request.getMessage());\n            return ResponseEntity.ok(response.getText());\n        } catch (Exception e) {\n            return ResponseEntity.status(500).body(\"Error: \" + e.getMessage());\n        }\n    }\n}\n\nclass GenerationRequest {\n    private String prompt;\n    \n    // getters and setters\n    public String getPrompt() { return prompt; }\n    public void setPrompt(String prompt) { this.prompt = prompt; }\n}\n\nclass ChatRequest {\n    private String message;\n    \n    // getters and setters\n    public String getMessage() { return message; }\n    public void setMessage(String message) { this.message = message; }\n}\n```\n\n## REST API\n\n### Direct HTTP Requests\n```bash\n# Basic content generation\ncurl -X POST \\\n  https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent \\\n  -H \"Content-Type: application/json\" \\\n  -H \"x-goog-api-key: YOUR_API_KEY\" \\\n  -d '{\n    \"contents\": [{\n      \"parts\": [{\n        \"text\": \"Explain quantum computing\"\n      }]\n    }]\n  }'\n\n# With configuration\ncurl -X POST \\\n  https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent \\\n  -H \"Content-Type: application/json\" \\\n  -H \"x-goog-api-key: YOUR_API_KEY\" \\\n  -d '{\n    \"contents\": [{\n      \"parts\": [{\n        \"text\": \"Write a creative story\"\n      }]\n    }],\n    \"generationConfig\": {\n      \"temperature\": 0.9,\n      \"maxOutputTokens\": 1000,\n      \"topK\": 40,\n      \"topP\": 0.95\n    }\n  }'\n```\n\n### Python requests library\n```python\nimport requests\nimport json\n\ndef gemini_api_request(prompt: str, api_key: str):\n    \"\"\"Make direct API request to Gemini.\"\"\"\n    url = \"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent\"\n    \n    headers = {\n        \"Content-Type\": \"application/json\",\n        \"x-goog-api-key\": api_key\n    }\n    \n    data = {\n        \"contents\": [{\n            \"parts\": [{\n                \"text\": prompt\n            }]\n        }],\n        \"generationConfig\": {\n            \"temperature\": 0.7,\n            \"maxOutputTokens\": 1000\n        }\n    }\n    \n    response = requests.post(url, headers=headers, json=data)\n    \n    if response.status_code == 200:\n        result = response.json()\n        return result['candidates'][0]['content']['parts'][0]['text']\n    else:\n        raise Exception(f\"API request failed: {response.status_code} - {response.text}\")\n\n# Usage\napi_key = \"your-api-key\"\nresponse = gemini_api_request(\"Explain machine learning\", api_key)\nprint(response)\n```\n\n## Migration Guide\n\n### From Legacy Python SDK\n```python\n# Old (google-generativeai)\nfrom google import genai\n\ngenai.configure(api_key=\"your-api-key\")\nmodel = genai.GenerativeModel('gemini-pro')\nresponse = model.generate_content(\"Hello\")\n\n# New (google-genai) - Very similar!\nfrom google import genai  # Same import!\n\ngenai.configure(api_key=\"your-api-key\")\nmodel = genai.GenerativeModel('gemini-2.5-flash')  # Updated model name\nresponse = model.generate_content(\"Hello\")\n\n# Key differences:\n# 1. Model names updated (gemini-pro -> gemini-2.5-flash)\n# 2. Some advanced features have updated APIs\n# 3. New features available (thinking, improved grounding, etc.)\n```\n\n### Migration Checklist\n1. **Update dependencies**: Install new SDK packages\n2. **Update model names**: Use current model names (gemini-2.5-flash, etc.)\n3. **Review API changes**: Check for any breaking changes in advanced features\n4. **Test thoroughly**: Validate functionality with new SDK\n5. **Update documentation**: Update internal documentation and examples\n\n## Best Practices\n\n### SDK Selection\n1. **Use current generation SDKs**: Prefer google-genai packages\n2. **Language-specific**: Choose SDK that matches your tech stack\n3. **Feature requirements**: Ensure SDK supports needed features\n4. **Performance needs**: Consider async/streaming requirements\n5. **Maintenance**: Choose actively maintained SDKs\n\n### Development Practices\n1. **Error handling**: Implement comprehensive error handling\n2. **Rate limiting**: Respect API rate limits\n3. **Security**: Never expose API keys in client-side code\n4. **Caching**: Cache responses where appropriate\n5. **Monitoring**: Track usage and performance metrics\n\n### Production Considerations\n1. **Environment management**: Use environment variables for API keys\n2. **Logging**: Implement proper logging for debugging\n3. **Retry logic**: Handle transient failures gracefully\n4. **Performance monitoring**: Monitor response times and success rates\n5. **Cost optimization**: Track and optimize token usage\n\n## Troubleshooting\n\n### Common Issues\n1. **Authentication errors**: Check API key configuration\n2. **Rate limiting**: Implement backoff strategies\n3. **Network issues**: Handle connection timeouts\n4. **Model availability**: Verify model names and availability\n5. **Response format**: Handle different response structures\n\n### Debug Techniques\n```python\n# Enable debug logging\nimport logging\nlogging.basicConfig(level=logging.DEBUG)\n\n# Detailed error information\ntry:\n    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt)\nexcept Exception as e:\n    print(f\"Error type: {type(e).__name__}\")\n    print(f\"Error message: {str(e)}\")\n    print(f\"Error details: {getattr(e, 'details', 'No details available')}\")\n```\n\n---\n\n**Last Updated:** Based on Google Gemini API documentation as of 2025\n**Reference:** https://ai.google.dev/gemini-api/docs/sdks
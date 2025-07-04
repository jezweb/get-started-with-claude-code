# Google Gemini API Documentation Verification

This document tracks the sources used to verify and update the Google Gemini API documentation.

## Verification Date
**July 3, 2025**

## Primary Sources

### 1. Official Google AI Documentation
- **Main Documentation**: https://ai.google.dev/gemini-api/docs
- **Models Page**: https://ai.google.dev/gemini-api/docs/models
- **Libraries/SDK Page**: https://ai.google.dev/gemini-api/docs/libraries
- **API Reference**: https://ai.google.dev/api

### 2. Key Findings

#### New Google Gen AI SDK
- Google has introduced a new unified SDK: `@google/genai`
- Old SDK `@google/generative-ai` will lose support by September 2025
- New SDK provides access to all latest features including multi-modal outputs

#### Latest Models (as of June 2025)
1. **Gemini 2.5 Pro** (`gemini-2.5-pro`)
   - Most powerful thinking model
   - 1,048,576 input tokens, 65,536 output tokens
   - Knowledge cutoff: January 2025

2. **Gemini 2.5 Flash** (`gemini-2.5-flash`)
   - Best price-performance ratio
   - Adaptive thinking capabilities
   - 1,048,576 input tokens, 65,536 output tokens

3. **Gemini 2.5 Flash-Lite** (`gemini-2.5-flash-lite-preview-06-17`)
   - Most cost-efficient model
   - 1,000,000 input tokens, 64,000 output tokens

4. **Gemini 2.0 Flash** (`gemini-2.0-flash`)
   - Next-gen features, native tool use
   - 1,048,576 input tokens, 8,192 output tokens

#### Specialized Models
- **Text-to-Speech**: `gemini-2.5-flash-preview-tts`, `gemini-2.5-pro-preview-tts`
- **Native Audio**: `gemini-2.5-flash-preview-native-audio-dialog`
- **Live API**: `gemini-live-2.5-flash-preview`
- **Image Generation**: `gemini-2.0-flash-preview-image-generation`

#### New Features
1. **Thinking Models** - Complex reasoning capabilities
2. **Live API** - Real-time bidirectional audio/video
3. **URL Context** - Direct web page processing
4. **Google Search Grounding** - Built-in search capabilities
5. **Native Audio Generation** - Direct audio output
6. **Multi-modal Outputs** - Text, images, and audio in responses

## Migration Notes

### SDK Migration
```javascript
// Old SDK (deprecated)
import { GoogleGenerativeAI } from '@google/generative-ai'

// New SDK (recommended)
import { GoogleGenerativeAI } from '@google/genai'
```

### Model Updates
- `gemini-pro` → `gemini-2.5-flash` or `gemini-2.5-pro`
- `gemini-pro-vision` → `gemini-2.5-flash` (all models are multimodal)

## Additional Resources
- **GitHub Cookbook**: https://github.com/google-gemini/cookbook
- **Firebase AI Logic**: https://firebase.google.com/docs/ai-logic
- **Vertex AI Integration**: https://cloud.google.com/vertex-ai/generative-ai/docs

## Verification Process
1. Searched for latest Google Gemini API documentation (July 2025)
2. Reviewed official Google AI documentation site
3. Verified new SDK information from libraries page
4. Confirmed model specifications from models page
5. Cross-referenced with web search results for latest updates

## Notes
- Google Gemini API is rapidly evolving with frequent updates
- Preview models may change without notice
- Rate limits vary by model and account type
- Some features (like Gemini 1.5 models) have restrictions for new projects starting April 2025
# Google Gemini Vision Capabilities

## Overview
Gemini's vision capabilities enable advanced image understanding, analysis, and processing. The multimodal AI can perform various tasks including image captioning, object detection, segmentation, and complex visual reasoning.

## Supported Image Formats

### File Types
- **PNG** (Portable Network Graphics)
- **JPEG** (Joint Photographic Experts Group)
- **WEBP** (Web Picture format)
- **HEIC** (High Efficiency Image Container)
- **HEIF** (High Efficiency Image File Format)

### Technical Specifications
- **Maximum request size**: 20MB total
- **Recommended resolution**: Up to 3072x3072 pixels
- **Token calculation**: 258 tokens for images ≤384 pixels
- **Large image handling**: Automatically tiled into 768x768 pixel sections

## Core Vision Features

### Basic Image Understanding
- **Image captioning**: Generate descriptive text about image content
- **Scene analysis**: Understand context and setting of images
- **Content recognition**: Identify objects, people, animals, and concepts
- **Text extraction**: Read and transcribe text within images (OCR)
- **Visual question answering**: Answer specific questions about image content

### Advanced Capabilities (Gemini 2.0+)

#### Object Detection
- **Bounding boxes**: Precise coordinate locations of detected objects
- **Multi-object detection**: Identify multiple objects in single image
- **Classification**: Categorize detected objects
- **Confidence scores**: Probability ratings for detections

#### Segmentation (Gemini 2.5+)
- **Contour masks**: Detailed object boundaries
- **Instance segmentation**: Separate individual object instances
- **Semantic segmentation**: Classify every pixel in the image
- **Precision mapping**: Pixel-level accuracy for object boundaries

## Image Processing Methods

### Inline Image Data
Direct image upload within the request:

```python
from google import genai
from google.genai import types
import PIL.Image

client = genai.Client()

# Load and process image
image_path = "example.jpg"
image_file = client.files.upload(path=image_path)

# Generate response
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Describe this image in detail"),
            types.Part(file_data=types.FileData(file_uri=image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Base64 Encoding
```python
from google import genai
from google.genai import types
import base64

client = genai.Client()

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

base64_image = encode_image("example.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="What do you see in this image?"),
            types.Part(inline_data=types.Blob(mime_type="image/jpeg", data=base64_image))
        ])
    ]
)
```

### File API Upload (Recommended for Large Files)
```python
from google import genai
from google.genai import types

client = genai.Client()

# Upload file first
uploaded_file = client.files.upload(path="large_image.png")

# Use in multiple requests
response1 = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Describe this image"),
            types.Part(file_data=types.FileData(file_uri=uploaded_file.uri, mime_type="image/png"))
        ])
    ]
)

response2 = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="What colors are prominent in this image?"),
            types.Part(file_data=types.FileData(file_uri=uploaded_file.uri, mime_type="image/png"))
        ])
    ]
)
```

## Use Cases

### Content Analysis
- **Social media monitoring**: Analyze user-generated visual content
- **Brand detection**: Identify logos and brand elements
- **Content moderation**: Detect inappropriate visual content
- **Accessibility**: Generate alt-text for images

### E-commerce and Retail
- **Product cataloging**: Automatically describe and categorize products
- **Visual search**: Find similar products based on images
- **Quality control**: Identify defects or issues in product photos
- **Inventory management**: Count and track items visually

### Healthcare and Science
- **Medical imaging**: Analyze diagnostic images (with appropriate permissions)
- **Research analysis**: Process scientific diagrams and charts
- **Laboratory work**: Identify specimens and analyze results
- **Documentation**: Extract information from medical charts

### Education and Research
- **Document processing**: Extract text and data from scanned documents
- **Historical analysis**: Analyze historical photographs and artifacts
- **Scientific visualization**: Interpret charts, graphs, and diagrams
- **Language learning**: Analyze images for vocabulary and context

### Security and Surveillance
- **Activity recognition**: Identify activities and behaviors
- **Anomaly detection**: Spot unusual patterns or events
- **Access control**: Facial recognition and identification
- **Safety monitoring**: Detect safety hazards and violations

## Advanced Vision Techniques

### Multi-Image Analysis
```python
from google import genai
from google.genai import types

client = genai.Client()

# Upload multiple images
image_files = [
    client.files.upload(path="image1.jpg"),
    client.files.upload(path="image2.jpg"),
    client.files.upload(path="image3.jpg")
]

# Create parts for all images
parts = [types.Part(text="Compare these three images and identify the differences")]
for i, img_file in enumerate(image_files):
    parts.append(types.Part(file_data=types.FileData(file_uri=img_file.uri, mime_type="image/jpeg")))

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[types.Content(parts=parts)]
)
```

### Visual Chain-of-Thought
```python
from google import genai
from google.genai import types

client = genai.Client()
image_file = client.files.upload(path="image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="""
            Analyze this image step by step:
            1. First, identify the main objects
            2. Then, describe their relationships
            3. Finally, interpret the overall scene
            """),
            types.Part(file_data=types.FileData(file_uri=image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Structured Visual Analysis
```python
from google import genai
from google.genai import types

client = genai.Client()
product_image_file = client.files.upload(path="product_image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="""
            Analyze this product image and provide:
            - Product name and category
            - Key features visible
            - Color and material
            - Condition assessment
            - Estimated value range
            """),
            types.Part(file_data=types.FileData(file_uri=product_image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

## Object Detection Examples

### Basic Object Detection
```python
from google import genai
from google.genai import types

client = genai.Client()
image_file = client.files.upload(path="image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Detect all objects in this image and provide their bounding box coordinates"),
            types.Part(file_data=types.FileData(file_uri=image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Specific Object Search
```python
from google import genai
from google.genai import types

client = genai.Client()
street_image_file = client.files.upload(path="street_image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Find all cars in this image and describe their locations"),
            types.Part(file_data=types.FileData(file_uri=street_image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Object Counting
```python
from google import genai
from google.genai import types

client = genai.Client()
group_photo_file = client.files.upload(path="group_photo.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Count how many people are in this group photo"),
            types.Part(file_data=types.FileData(file_uri=group_photo_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

## Segmentation Applications

### Instance Segmentation
```python
from google import genai
from google.genai import types

client = genai.Client()
crowd_image_file = client.files.upload(path="crowd_image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Create contour masks for each individual person in this image"),
            types.Part(file_data=types.FileData(file_uri=crowd_image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Background Removal
```python
from google import genai
from google.genai import types

client = genai.Client()
portrait_image_file = client.files.upload(path="portrait_image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Identify the main subject and separate it from the background"),
            types.Part(file_data=types.FileData(file_uri=portrait_image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

### Area Calculation
```python
from google import genai
from google.genai import types

client = genai.Client()
aerial_image_file = client.files.upload(path="aerial_image.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Calculate the approximate area covered by vegetation in this aerial image"),
            types.Part(file_data=types.FileData(file_uri=aerial_image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)
```

## Best Practices

### Image Quality
1. **Use clear, well-lit images**: Better lighting improves recognition accuracy
2. **Avoid blurry images**: Sharp focus produces better results
3. **Check orientation**: Ensure images are properly rotated
4. **Optimal resolution**: Balance quality with processing speed
5. **Remove noise**: Clean images work better than cluttered ones

### Prompt Engineering
1. **Be specific**: Clearly state what you want to identify or analyze
2. **Provide context**: Explain the purpose of the analysis
3. **Ask focused questions**: Specific queries yield better results
4. **Use structured formats**: Request organized responses
5. **Include examples**: Show desired output format

### Performance Optimization
1. **Choose appropriate model**: Balance capability with cost
2. **Optimize image size**: Resize large images when possible
3. **Use File API**: For multiple requests with same image
4. **Batch processing**: Group related image analysis tasks
5. **Cache results**: Store frequently analyzed images

### Content Handling
1. **Respect privacy**: Follow data protection guidelines
2. **Verify accuracy**: Cross-check important visual information
3. **Handle edge cases**: Plan for unclear or ambiguous images
4. **Implement safety**: Use content filtering for user-generated content
5. **Monitor performance**: Track analysis quality and accuracy

## Integration Examples

### Python with PIL
```python
from google import genai
from google.genai import types
import PIL.Image

client = genai.Client(api_key="your-api-key")

# Load and analyze image
image_file = client.files.upload(path="photo.jpg")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        types.Content(parts=[
            types.Part(text="Describe everything you see in this image, including objects, people, and setting"),
            types.Part(file_data=types.FileData(file_uri=image_file.uri, mime_type="image/jpeg"))
        ])
    ]
)

print(response.text)
```

### JavaScript with Canvas
```javascript
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI("your-api-key");
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

// Convert image to base64
function imageToBase64(file) {
    return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.readAsDataURL(file);
    });
}

const base64Image = await imageToBase64(imageFile);
const result = await model.generateContent([
    "What objects can you identify in this image?",
    {
        inlineData: {
            data: base64Image,
            mimeType: "image/jpeg"
        }
    }
]);
```

### REST API
```bash
curl -X POST \
  https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: your-api-key" \
  -d '{
    "contents": [{
      "parts": [
        {"text": "Analyze this image for safety hazards"},
        {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": "base64-encoded-image-data"
          }
        }
      ]
    }]
  }'
```

## Error Handling

### Common Issues
1. **Unsupported format**: Image format not supported
2. **Size limits**: Image too large for processing
3. **Quality issues**: Image too blurry or unclear
4. **Privacy restrictions**: Content blocked by safety filters

### Troubleshooting
```python
from google import genai
from google.genai import types

client = genai.Client()
image_file = client.files.upload(path="image.jpg")

try:
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            types.Content(parts=[
                types.Part(text=prompt),
                types.Part(file_data=types.FileData(file_uri=image_file.uri, mime_type="image/jpeg"))
            ])
        ]
    )
    
    if not response.candidates:
        print("No response generated - check image format and content")
    elif response.candidates[0].finish_reason == "SAFETY":
        print("Content blocked by safety filters")
    else:
        print(response.text)
        
except Exception as e:
    print(f"Error processing image: {e}")
```

## Token Usage and Pricing

### Token Calculation
- **Small images (≤384px)**: 258 tokens
- **Larger images**: Calculated based on tiled sections
- **Multiple images**: Tokens calculated per image

### Cost Optimization
1. **Image size optimization**: Resize when appropriate
2. **Batch processing**: Group related analyses
3. **Model selection**: Use appropriate model for task complexity
4. **Caching**: Reuse analysis results when possible

## Limitations

### Technical Limitations
- **Resolution limits**: Very high-resolution images may be downsampled
- **Processing time**: Complex analysis may take longer
- **Format restrictions**: Limited to supported image formats
- **Content restrictions**: Some content may be filtered

### Accuracy Considerations
1. **Lighting conditions**: Poor lighting affects accuracy
2. **Perspective issues**: Extreme angles may reduce recognition
3. **Occlusion**: Partially hidden objects may not be detected
4. **Cultural context**: May miss culturally specific elements
5. **Fine details**: Very small objects may not be detected

---

**Last Updated:** Based on Google Gemini API documentation as of 2025
**Reference:** https://ai.google.dev/gemini-api/docs/vision
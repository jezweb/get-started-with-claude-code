# Getting PDF Uploads to Work with Google Gemini: A Complete Journey

## Table of Contents
1. [The Challenge](#the-challenge)
2. [Initial Attempts and Failures](#initial-attempts-and-failures)
3. [Key Discoveries](#key-discoveries)
4. [The Solution](#the-solution)
5. [Implementation Guide](#implementation-guide)
6. [Performance Comparison](#performance-comparison)
7. [Lessons Learned](#lessons-learned)
8. [Quick Reference](#quick-reference)

## The Challenge

We needed to process PDF architectural plans with Google's Gemini AI to generate electrical quotes and documentation. The challenge was that Gemini needs to "see" the PDF visually (not just extract text) to understand diagrams, measurements, and spatial layouts.

### Requirements
- Process architectural PDFs with diagrams and technical drawings
- Support various file sizes (from 1KB to 50MB+)
- Maintain visual context (not just text extraction)
- Fast processing for better user experience

## Initial Attempts and Failures

### 1. Text Extraction Approach ❌
**What we tried:**
```python
# Extract text from PDF
pdf_text = ""
doc = fitz.open(pdf_path)
for page in doc:
    pdf_text += page.get_text()

# Send text to Gemini
response = model.generate_content(prompt + pdf_text)
```

**Why it failed:**
- Lost all visual context (diagrams, layouts, measurements)
- Error: "No text could be extracted from the PDF"
- Gemini couldn't understand spatial relationships

### 2. File Upload Attempt (Old SDK) ❌
**What we tried:**
```python
# This doesn't exist in google.generativeai!
uploaded_file = genai.upload_file(tmp_path, mime_type="application/pdf")
```

**Why it failed:**
- `AttributeError: module 'google.generativeai' has no attribute 'upload_file'`
- The old SDK (`google-generativeai`) doesn't support file uploads

### 3. Inline Data with Old SDK ✅ (Partial Success)
**What worked:**
```python
with open(pdf_path, 'rb') as f:
    pdf_data = f.read()

response = model.generate_content([
    {"mime_type": "application/pdf", "data": pdf_data},
    prompt
])
```

**Limitations:**
- Only works for PDFs under 20MB
- No way to handle larger files

## Key Discoveries

### 1. Two Different Google SDKs Exist

| Old SDK | New SDK |
|---------|---------|
| `google-generativeai` | `google-genai` |
| `pip install google-generativeai` | `pip install google-genai` |
| No file upload API | Full file upload support |
| Dictionary-based content | Type-safe objects |
| Model: `gemini-1.5-flash` | Model: `gemini-2.0-flash-001` |

### 2. Gemini Needs Visual PDF Access
- Text extraction is NOT sufficient
- Gemini must "see" the PDF to understand diagrams
- Visual analysis is crucial for architectural plans

### 3. Size Matters
- Inline data method: Limited to 20MB
- File upload API: Supports 50MB+ files
- Different methods have different performance characteristics

## The Solution

### Step 1: Install the New SDK
```bash
pip install google-genai
```

### Step 2: Implement Hybrid Approach
```python
from google import genai
from google.genai import types

# Initialize client
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

def process_pdf(pdf_path, prompt):
    file_size = os.path.getsize(pdf_path)
    
    if file_size <= 20 * 1024 * 1024:  # 20MB or less
        # Use direct method (faster)
        with open(pdf_path, 'rb') as f:
            pdf_data = f.read()
        
        response = client.models.generate_content(
            model='gemini-2.0-flash-001',
            contents=[
                prompt,
                types.Part.from_bytes(
                    data=pdf_data,
                    mime_type='application/pdf'
                )
            ]
        )
    else:
        # Use file upload API for large files
        uploaded_file = client.files.upload(file=pdf_path)
        
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash-001',
                contents=[prompt, uploaded_file]
            )
        finally:
            # Always cleanup
            client.files.delete(name=uploaded_file.name)
    
    return response.text
```

## Implementation Guide

### 1. Update Requirements
```txt
# requirements.txt
google-genai>=0.1.0  # New SDK
# Keep old SDK during transition if needed
google-generativeai==0.3.1
```

### 2. Migration Path

**Old SDK Pattern:**
```python
import google.generativeai as genai
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")
```

**New SDK Pattern:**
```python
from google import genai
client = genai.Client(api_key=API_KEY)
# Use client.models.generate_content()
```

### 3. Error Handling
```python
from google.genai import errors

try:
    response = client.models.generate_content(...)
except errors.APIError as e:
    print(f"API Error {e.code}: {e.message}")
```

## Performance Comparison

Based on our testing with real architectural PDFs:

| File Size | Old SDK | New SDK (Direct) | New SDK (Upload) | Improvement |
|-----------|---------|------------------|------------------|-------------|
| 0.001MB | 10.52s | 4.25s | 5.47s | **60% faster** |
| 2.6MB | 13.47s | 9.62s | 10.01s | **28% faster** |
| 3.9MB | 20.55s | 12.39s | 12.58s | **40% faster** |
| >20MB | ❌ Fails | ❌ N/A | ✅ Works | **Enables large files** |

## Lessons Learned

### 1. SDK Confusion
- Google maintains two Python SDKs
- Documentation often mixes examples from both
- Always verify which SDK you're using

### 2. Visual Processing is Key
- Text extraction destroys spatial information
- Gemini needs the actual PDF data, not extracted text
- Architectural plans require visual understanding

### 3. Size-Based Routing Works Best
- Small files: Direct method is fastest
- Large files: File upload API is necessary
- Hybrid approach gives best of both worlds

### 4. Always Check API Limits
- Inline data: 20MB maximum
- File upload: Much larger (50MB+ tested)
- Consider chunking for huge files

## Quick Reference

### Install New SDK
```bash
pip install google-genai
```

### Simple Usage
```python
from google import genai
from google.genai import types

client = genai.Client(api_key="YOUR_API_KEY")

# For PDFs under 20MB
with open('plan.pdf', 'rb') as f:
    pdf_data = f.read()

response = client.models.generate_content(
    model='gemini-2.0-flash-001',
    contents=[
        "Analyze this electrical plan",
        types.Part.from_bytes(data=pdf_data, mime_type='application/pdf')
    ]
)
print(response.text)
```

### Large File Support
```python
# For PDFs over 20MB
uploaded_file = client.files.upload(file='large_plan.pdf')
response = client.models.generate_content(
    model='gemini-2.0-flash-001',
    contents=["Analyze this plan", uploaded_file]
)
client.files.delete(name=uploaded_file.name)
```

### Model Names
- Old: `gemini-1.5-flash`
- New: `gemini-2.0-flash-001`

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "No text could be extracted" | Using text extraction | Send PDF data directly |
| "has no attribute 'upload_file'" | Using old SDK | Switch to `google-genai` |
| "File too large" | >20MB with inline method | Use file upload API |
| "Module not found" | Wrong import | Use `from google import genai` |

## Summary

Getting PDF uploads to work with Gemini required:
1. Understanding that visual processing is essential (not text extraction)
2. Discovering the newer `google-genai` SDK with file upload support
3. Implementing a hybrid approach for optimal performance
4. Proper error handling and cleanup

The new SDK not only solves the file size limitation but also provides significant performance improvements (28-60% faster) and better developer experience.

---

*Document created: 2025-07-01*  
*Project: SparkyAI MVP-02*  
*Tested with: Google Gemini 2.0 Flash*
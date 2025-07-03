# Google Gemini Code Execution

## Overview
Gemini's code execution capability allows models to generate and run Python code iteratively within a sandboxed environment. This powerful feature enables dynamic programming, data analysis, mathematical calculations, and interactive problem-solving.

## Key Features

### Supported Language
- **Python only**: Currently supports Python code execution
- **Runtime limit**: Maximum 30 seconds per code environment
- **Sandboxed execution**: Secure, isolated environment
- **Iterative development**: Can generate and refine code step-by-step

### Built-in Libraries
Over 30 pre-installed libraries including:
- **Data Processing**: numpy, pandas, scipy
- **Visualization**: matplotlib, seaborn, plotly
- **Machine Learning**: scikit-learn, tensorflow, pytorch
- **Web Requests**: requests, urllib
- **File Processing**: csv, json, xml
- **Mathematical**: math, statistics, sympy
- **Image Processing**: PIL (Pillow)

### Capabilities
- **File input**: Process CSV, text, and other file formats
- **Mathematical computation**: Complex calculations and analysis
- **Data visualization**: Generate charts and graphs
- **Algorithm implementation**: Write and test algorithms
- **Data manipulation**: Process and transform datasets

## Basic Usage

### Enabling Code Execution
```python
import google.generativeai as genai

# Configure model with code execution
model = genai.GenerativeModel(
    'gemini-2.5-flash',
    tools=[{'code_execution': {}}]
)

# Generate response with code execution capability
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=
    \"Calculate the mean and standard deviation of the numbers: 10, 15, 20, 25, 30\"
)

print(response.text)
```

### Simple Mathematical Calculation
```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Calculate the compound interest for:
    - Principal: $10,000
    - Annual interest rate: 5%
    - Time: 10 years
    - Compounded annually
    
    Show the calculation step by step and create a growth chart.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

### Data Analysis Example
```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Create a dataset of 100 random temperatures between -10°C and 40°C.
    Calculate statistics and create a histogram showing the distribution.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

## Advanced Use Cases

### File Processing and Analysis
```python
# Upload a CSV file first
file = genai.upload_file(\"sales_data.csv\")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
    \"Analyze this sales data CSV file. Calculate monthly totals, growth rates, and create visualizations.\",
    file
])
```

### Algorithm Implementation
```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Implement a binary search algorithm and demonstrate it with an example.
    Then compare its performance with linear search using time measurements.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

### Statistical Analysis
```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Generate sample data for a A/B test with:
    - Group A: 1000 users, 12% conversion rate
    - Group B: 1000 users, 14% conversion rate
    
    Perform a statistical significance test and visualize the results.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

### Machine Learning Example
```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Create a simple machine learning model to predict house prices based on:
    - Square footage
    - Number of bedrooms
    - Age of house
    
    Generate synthetic data, train a model, and evaluate its performance.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

## Practical Applications

### Data Science Workflows
```python
def analyze_dataset(data_description: str):
    prompt = f\"\"\"
    I have a dataset with the following characteristics: {data_description}
    
    Please:
    1. Generate representative sample data
    2. Perform exploratory data analysis
    3. Create appropriate visualizations
    4. Identify patterns and insights
    5. Suggest next steps for analysis
    \"\"\"
    
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )
    return response.text

# Usage
analysis = analyze_dataset(\"Customer purchase data with user_id, product_category, purchase_amount, and purchase_date\")
```

### Financial Calculations
```python
def financial_analysis(scenario: str):
    prompt = f\"\"\"
    Perform financial analysis for: {scenario}
    
    Include:
    - Detailed calculations
    - Multiple scenarios (best case, worst case, realistic)
    - Visualizations showing trends
    - Risk assessment
    - Recommendations
    \"\"\"
    
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )
    return response.text

# Usage
analysis = financial_analysis(\"Investment portfolio of $100,000 across stocks, bonds, and real estate over 20 years\")
```

### Scientific Computing
```python
def solve_physics_problem(problem: str):
    prompt = f\"\"\"
    Solve this physics problem: {problem}
    
    Show:
    - Mathematical formulation
    - Step-by-step solution
    - Units and dimensional analysis
    - Graphical representation if applicable
    - Verification of results
    \"\"\"
    
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )
    return response.text

# Usage
solution = solve_physics_problem(\"A projectile is launched at 45° with initial velocity 50 m/s. Calculate range, maximum height, and time of flight.\")
```

## Working with Files

### CSV Data Processing
```python
# Upload CSV file
csv_file = genai.upload_file(\"data.csv\")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
    \"\"\"
    Analyze this CSV data:
    1. Show basic statistics for all numeric columns
    2. Identify any missing values or outliers
    3. Create correlation matrix for numeric variables
    4. Generate appropriate plots for key relationships
    5. Summarize main findings
    \"\"\",
    csv_file
])
```

### Text File Analysis
```python
# Upload text file
text_file = genai.upload_file(\"document.txt\")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
    \"\"\"
    Analyze this text file:
    1. Count words, sentences, and paragraphs
    2. Identify most common words (excluding stop words)
    3. Calculate readability scores
    4. Create word frequency visualization
    5. Extract key themes or topics
    \"\"\",
    text_file
])
```

### Image Analysis with Code
```python
# Upload image file
image_file = genai.upload_file(\"chart.png\")

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
    \"\"\"
    Analyze this image and if it contains data or charts:
    1. Extract the data points if possible
    2. Recreate the chart using matplotlib
    3. Perform additional analysis on the extracted data
    4. Suggest improvements to the visualization
    \"\"\",
    image_file
])
```

## Visualization Examples

### Creating Interactive Charts
```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Create an interactive dashboard showing:
    1. Sales data over 12 months with seasonal trends
    2. Product category performance comparison
    3. Regional sales distribution map
    4. Customer acquisition funnel
    
    Use plotly for interactivity and include insights from the data.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

### Statistical Visualizations
```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\"\"\"
    Generate and visualize:
    1. Normal distribution comparison with different parameters
    2. Central Limit Theorem demonstration
    3. Confidence interval visualization
    4. Hypothesis testing example with p-values
    
    Include explanatory text for each visualization.
    \"\"\",
    config=types.GenerateContentConfig(
        tools=[types.Tool(code_execution=types.CodeExecution())]
    )
)
```

## Error Handling and Debugging

### Handling Code Errors
```python
def robust_code_execution(prompt: str, max_retries: int = 3):
    \"\"\"Execute code with error handling and retries.\"\"\"
    from google import genai
    from google.genai import types
    
    client = genai.Client()\n    \n    for attempt in range(max_retries):\n        try:\n            response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )\n            \n            # Check if code executed successfully\n            if \"error\" not in response.text.lower():\n                return response.text\n            else:\n                print(f\"Attempt {attempt + 1} had errors, retrying...\")\n                if attempt < max_retries - 1:\n                    prompt += \"\\n\\nThe previous attempt had errors. Please fix them and try again.\"\n                    \n        except Exception as e:\n            print(f\"Execution error on attempt {attempt + 1}: {e}\")\n            if attempt == max_retries - 1:\n                return f\"Failed after {max_retries} attempts\"\n    \n    return \"Maximum retries exceeded\"\n```\n\n### Debugging Code Issues\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    I'm trying to calculate the correlation between two variables but getting an error.\n    Here's my code:\n    \n    import pandas as pd\n    data = pd.DataFrame({'x': [1, 2, 3], 'y': ['a', 'b', 'c']})\n    correlation = data['x'].corr(data['y'])\n    \n    Please identify the issue, explain why it's happening, and provide a corrected version.\n    \"\"\"\n)\n```\n\n## Performance Optimization\n\n### Efficient Data Processing\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Demonstrate efficient vs inefficient approaches for:\n    1. Processing large datasets (vectorization vs loops)\n    2. Memory management for big data\n    3. Optimizing matplotlib plots for large datasets\n    4. Using pandas efficiently for data manipulation\n    \n    Show timing comparisons and memory usage.\n    \"\"\"\n)\n```\n\n### Code Optimization Examples\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Take this inefficient code and optimize it:\n    \n    result = []\n    for i in range(100000):\n        if i % 2 == 0:\n            result.append(i * 2)\n    \n    Show multiple optimization approaches and compare their performance.\n    \"\"\"\n)\n```\n\n## Integration Patterns\n\n### Jupyter Notebook Style Analysis\n```python\ndef notebook_analysis(problem_description: str):\n    \"\"\"Create a notebook-style analysis.\"\"\"\n    prompt = f\"\"\"\n    Create a comprehensive analysis for: {problem_description}\n    \n    Structure it like a Jupyter notebook with:\n    - Clear markdown headers and explanations\n    - Code cells with comments\n    - Output interpretation\n    - Visualizations with descriptions\n    - Conclusions and recommendations\n    \n    Make it educational and well-documented.\n    \"\"\"\n    \n    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )\n    return response.text\n\n# Usage\nanalysis = notebook_analysis(\"Comparing the effectiveness of different sorting algorithms\")\n```\n\n### Report Generation\n```python\ndef generate_data_report(data_description: str):\n    \"\"\"Generate a complete data analysis report.\"\"\"\n    prompt = f\"\"\"\n    Create a professional data analysis report for: {data_description}\n    \n    Include:\n    1. Executive Summary\n    2. Data Overview and Quality Assessment\n    3. Statistical Analysis\n    4. Key Findings with Visualizations\n    5. Recommendations\n    6. Technical Appendix with code\n    \n    Use professional formatting and clear explanations.\n    \"\"\"\n    \n    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(code_execution=types.CodeExecution())]
        )
    )\n    return response.text\n```\n\n## Educational Applications\n\n### Teaching Programming Concepts\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Teach the concept of recursion by:\n    1. Explaining what recursion is with simple examples\n    2. Implementing factorial function recursively\n    3. Showing the call stack visualization\n    4. Comparing recursive vs iterative solutions\n    5. Providing practice problems with solutions\n    \n    Make it beginner-friendly with clear explanations.\n    \"\"\"\n)\n```\n\n### Algorithm Visualization\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Create an educational demonstration of sorting algorithms:\n    1. Implement bubble sort, selection sort, and quicksort\n    2. Visualize how each algorithm works step-by-step\n    3. Compare their time complexities with actual timing tests\n    4. Show when to use each algorithm\n    \n    Include animated-style visualizations using matplotlib.\n    \"\"\"\n)\n```\n\n## Best Practices\n\n### Code Quality\n1. **Clear documentation**: Include comments and explanations\n2. **Error handling**: Plan for potential issues\n3. **Modular design**: Break complex problems into smaller parts\n4. **Testing**: Verify results with known test cases\n5. **Performance awareness**: Consider efficiency for large datasets\n\n### Effective Prompting\n1. **Specific requirements**: Clearly state what you want\n2. **Context provision**: Include relevant background information\n3. **Output format**: Specify desired format and style\n4. **Examples**: Provide examples when helpful\n5. **Constraints**: Mention any limitations or requirements\n\n### Resource Management\n1. **Time limits**: Be aware of 30-second execution limit\n2. **Memory usage**: Monitor memory for large datasets\n3. **Library limitations**: Use only available libraries\n4. **File handling**: Properly manage file uploads and processing\n5. **Output size**: Consider output length limitations\n\n## Common Use Case Patterns\n\n### Data Science Pipeline\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Create a complete data science pipeline:\n    1. Data ingestion and cleaning\n    2. Exploratory data analysis\n    3. Feature engineering\n    4. Model training and evaluation\n    5. Results visualization and interpretation\n    \n    Use synthetic e-commerce data as an example.\n    \"\"\"\n)\n```\n\n### Financial Modeling\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Build a comprehensive financial model:\n    1. Monte Carlo simulation for investment returns\n    2. Risk assessment and Value at Risk calculation\n    3. Portfolio optimization\n    4. Scenario analysis\n    5. Interactive dashboard for results\n    \n    Include sensitivity analysis and stress testing.\n    \"\"\"\n)\n```\n\n### Scientific Research\n```python\nresponse = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=\n    \"\"\"\n    Conduct a scientific analysis:\n    1. Hypothesis formulation\n    2. Experimental design and data generation\n    3. Statistical testing\n    4. Results visualization\n    5. Conclusion and significance assessment\n    \n    Use a biological research example like drug effectiveness testing.\n    \"\"\"\n)\n```\n\n## Limitations and Considerations\n\n### Technical Limitations\n- **Python only**: No support for other programming languages\n- **Library restrictions**: Cannot install custom libraries\n- **Execution time**: 30-second maximum runtime\n- **Memory limits**: Limited memory for large datasets\n- **No persistent state**: Code environments are isolated\n\n### Output Limitations\n- **File generation**: Cannot return actual files, only code and results\n- **External access**: No internet access from code environment\n- **Persistence**: Results don't persist between conversations\n- **Size limits**: Very large outputs may be truncated\n\n### Best Practice Recommendations\n1. **Break down complex problems**: Split large tasks into smaller parts\n2. **Test incrementally**: Build and test code step by step\n3. **Optimize for time**: Be mindful of execution time limits\n4. **Validate results**: Cross-check important calculations\n5. **Document thoroughly**: Include clear explanations and comments\n\n### Security Considerations\n1. **Sandboxed environment**: Code runs in secure isolation\n2. **No external access**: Cannot access external networks or systems\n3. **Safe libraries**: Only pre-approved libraries are available\n4. **Data handling**: Be cautious with sensitive data\n5. **Output review**: Review generated code before using elsewhere\n\n---\n\n**Last Updated:** Based on Google Gemini API documentation as of 2025\n**Reference:** https://ai.google.dev/gemini-api/docs/code-execution
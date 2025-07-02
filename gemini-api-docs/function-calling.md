# Google Gemini Function Calling

## Overview
Function calling enables Gemini models to connect with external tools, APIs, and services. This powerful feature allows the model to understand when to call specific functions, provide appropriate parameters, and integrate real-world actions into conversational AI workflows.

## Core Concepts

### Function Calling Process
1. **Function Declaration**: Define available functions with descriptions and parameters
2. **Prompt Analysis**: Model analyzes user request and determines needed functions
3. **Function Suggestion**: Model suggests function calls with parameters
4. **Execution**: Application executes the suggested function
5. **Response Integration**: Function results are integrated into model response

### Primary Use Cases
- **Augment Knowledge**: Access real-time data and external information
- **Extend Capabilities**: Perform actions beyond text generation
- **Take Actions**: Execute operations in external systems

## Supported Models
- Gemini 2.5 Pro
- Gemini 2.5 Flash
- Gemini 2.5 Flash-Lite
- Gemini 2.0 Flash

## Function Calling Modes

### AUTO Mode (Default)
Model automatically decides whether to call functions or provide direct responses:
```python
# Model chooses between function calling or direct response
response = model.generate_content(
    "What's the weather like in Sydney?",
    tools=[weather_tool]
)
```

### ANY Mode
Forces the model to call at least one function:
```python
response = model.generate_content(
    "Get current information",
    tools=[news_tool, weather_tool],
    tool_config={'function_calling_config': {'mode': 'ANY'}}
)
```

### NONE Mode
Prevents function calling entirely:
```python
response = model.generate_content(
    "Tell me about weather patterns",
    tools=[weather_tool],
    tool_config={'function_calling_config': {'mode': 'NONE'}}
)
```

## Function Declaration

### Basic Function Structure
```python
import google.generativeai as genai

# Define a function
def get_weather(location: str) -> str:
    """Get current weather for a location."""
    # Implementation here
    return f"Weather in {location}: Sunny, 25°C"

# Declare function for the model
weather_tool = genai.protos.Tool(
    function_declarations=[
        genai.protos.FunctionDeclaration(
            name="get_weather",
            description="Get the current weather for a specific location",
            parameters=genai.protos.Schema(
                type=genai.protos.Type.OBJECT,
                properties={
                    "location": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="The city and country, e.g., Sydney, Australia"
                    )
                },
                required=["location"]
            )
        )
    ]
)
```

### Complex Function with Multiple Parameters
```python
def book_restaurant(
    restaurant_name: str,
    date: str,
    time: str,
    party_size: int,
    special_requests: str = None
) -> str:
    """Book a restaurant reservation."""
    # Implementation
    return f"Booked {restaurant_name} for {party_size} on {date} at {time}"

restaurant_tool = genai.protos.Tool(
    function_declarations=[
        genai.protos.FunctionDeclaration(
            name="book_restaurant",
            description="Book a restaurant reservation",
            parameters=genai.protos.Schema(
                type=genai.protos.Type.OBJECT,
                properties={
                    "restaurant_name": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Name of the restaurant"
                    ),
                    "date": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Reservation date in YYYY-MM-DD format"
                    ),
                    "time": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Reservation time in HH:MM format"
                    ),
                    "party_size": genai.protos.Schema(
                        type=genai.protos.Type.INTEGER,
                        description="Number of people in the party"
                    ),
                    "special_requests": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Any special dietary requirements or requests"
                    )
                },
                required=["restaurant_name", "date", "time", "party_size"]
            )
        )
    ]
)
```

## Complete Function Calling Workflow

### Full Implementation Example
```python
import google.generativeai as genai
import json
from typing import Dict, Any

# Configure API
genai.configure(api_key="your-api-key")

# Function implementations
def get_current_weather(location: str) -> str:
    """Get current weather for a location."""
    # In real implementation, call weather API
    weather_data = {
        "Sydney": "Sunny, 25°C, light breeze",
        "New York": "Cloudy, 18°C, chance of rain",
        "London": "Overcast, 12°C, foggy"
    }
    return weather_data.get(location, "Weather data not available")

def send_email(recipient: str, subject: str, body: str) -> str:
    """Send an email."""
    # In real implementation, integrate with email service
    return f"Email sent to {recipient} with subject '{subject}'"

# Function declarations
weather_tool = genai.protos.Tool(
    function_declarations=[
        genai.protos.FunctionDeclaration(
            name="get_current_weather",
            description="Get current weather information for a city",
            parameters=genai.protos.Schema(
                type=genai.protos.Type.OBJECT,
                properties={
                    "location": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="City name"
                    )
                },
                required=["location"]
            )
        )
    ]
)

email_tool = genai.protos.Tool(
    function_declarations=[
        genai.protos.FunctionDeclaration(
            name="send_email",
            description="Send an email message",
            parameters=genai.protos.Schema(
                type=genai.protos.Type.OBJECT,
                properties={
                    "recipient": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Email address of recipient"
                    ),
                    "subject": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Email subject line"
                    ),
                    "body": genai.protos.Schema(
                        type=genai.protos.Type.STRING,
                        description="Email message content"
                    )
                },
                required=["recipient", "subject", "body"]
            )
        )
    ]
)

# Function executor
def execute_function_call(function_call) -> str:
    """Execute a function call and return the result."""
    function_name = function_call.name
    function_args = {key: val for key, val in function_call.args.items()}
    
    if function_name == "get_current_weather":
        return get_current_weather(**function_args)
    elif function_name == "send_email":
        return send_email(**function_args)
    else:
        return f"Unknown function: {function_name}"

# Model with tools
model = genai.GenerativeModel(
    'gemini-2.5-flash',
    tools=[weather_tool, email_tool]
)

# Generate response with function calling
def chat_with_functions(user_input: str):
    response = model.generate_content(user_input)
    
    # Check if model wants to call functions
    if response.candidates[0].content.parts[0].function_call:
        function_call = response.candidates[0].content.parts[0].function_call
        
        # Execute the function
        function_result = execute_function_call(function_call)
        
        # Send result back to model for final response
        final_response = model.generate_content([
            {"role": "user", "parts": [user_input]},
            {"role": "model", "parts": [response.candidates[0].content.parts[0]]},
            {"role": "function", "parts": [{"function_response": {
                "name": function_call.name,
                "response": {"result": function_result}
            }}]}
        ])
        
        return final_response.text
    else:
        return response.text

# Usage
result = chat_with_functions("What's the weather like in Sydney?")
print(result)
```

## Advanced Function Calling Features

### Parallel Function Calling
Execute multiple functions simultaneously:
```python
# Model can call multiple functions in one response
response = model.generate_content(
    "Check weather in Sydney and New York, then send a summary email to john@example.com"
)

# Handle multiple function calls
for part in response.candidates[0].content.parts:
    if part.function_call:
        result = execute_function_call(part.function_call)
        # Process each function result
```

### Compositional Function Calling
Chain function calls where one depends on another:
```python
def get_restaurant_info(location: str) -> str:
    """Get restaurant recommendations for a location."""
    return "Top restaurants: Pizza Palace, Burger Barn, Sushi Supreme"

def make_reservation(restaurant: str, time: str) -> str:
    """Make a restaurant reservation."""
    return f"Reserved table at {restaurant} for {time}"

# Model can chain these calls:
# 1. Get restaurant info for location
# 2. Make reservation at recommended restaurant
```

### Error Handling in Functions
```python
def robust_function_executor(function_call):
    """Execute function with error handling."""
    try:
        function_name = function_call.name
        function_args = {key: val for key, val in function_call.args.items()}
        
        # Validate required parameters
        if function_name == "get_weather" and "location" not in function_args:
            return "Error: Location parameter is required"
        
        # Execute function
        result = execute_function(function_name, function_args)
        return result
        
    except Exception as e:
        return f"Error executing {function_call.name}: {str(e)}"
```

## Best Practices

### Function Design
1. **Clear descriptions**: Write detailed function descriptions
2. **Specific parameters**: Define precise parameter types and descriptions
3. **Required vs optional**: Clearly mark required parameters
4. **Return consistency**: Maintain consistent return formats
5. **Error handling**: Include robust error handling

### Parameter Specification
```python
# Good parameter definition
genai.protos.Schema(
    type=genai.protos.Type.STRING,
    description="The city name including country if ambiguous (e.g., 'Paris, France' or 'Paris, Texas')",
    # Optional: Add format examples
)

# Avoid vague descriptions
genai.protos.Schema(
    type=genai.protos.Type.STRING,
    description="Location"  # Too vague
)
```

### Tool Organization
1. **Limit tool count**: Recommended 10-20 tools maximum
2. **Group related functions**: Organize by functionality
3. **Avoid redundancy**: Don't duplicate similar functions
4. **Test combinations**: Verify tools work well together
5. **Documentation**: Maintain clear tool documentation

### Performance Optimization
1. **Fast execution**: Keep functions lightweight and fast
2. **Caching**: Cache frequently accessed data
3. **Async operations**: Use async for I/O operations when possible
4. **Timeout handling**: Implement timeouts for external calls
5. **Resource limits**: Monitor memory and CPU usage

## Common Integration Patterns

### API Integration
```python
import requests

def call_external_api(endpoint: str, params: dict) -> str:
    """Call external REST API."""
    try:
        response = requests.get(f"https://api.example.com/{endpoint}", params=params)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return f"API call failed: {str(e)}"
```

### Database Operations
```python
import sqlite3

def query_database(query: str) -> str:
    """Execute database query."""
    try:
        conn = sqlite3.connect('database.db')
        cursor = conn.cursor()
        cursor.execute(query)
        results = cursor.fetchall()
        conn.close()
        return str(results)
    except Exception as e:
        return f"Database error: {str(e)}"
```

### File Operations
```python
def read_file(filename: str) -> str:
    """Read content from a file."""
    try:
        with open(filename, 'r') as file:
            return file.read()
    except FileNotFoundError:
        return f"File {filename} not found"
    except Exception as e:
        return f"Error reading file: {str(e)}"
```

## Use Case Examples

### Customer Support Assistant
```python
# Functions for customer support
support_tools = [
    get_order_status_tool,
    update_customer_info_tool,
    create_support_ticket_tool,
    search_knowledge_base_tool
]

# Customer can ask: "What's the status of my order #12345?"
# Model will call get_order_status function automatically
```

### Smart Home Controller
```python
# Functions for smart home
home_tools = [
    control_lights_tool,
    adjust_thermostat_tool,
    check_security_cameras_tool,
    set_alarm_tool
]

# User can say: "Turn off all lights and set temperature to 22°C"
# Model will call multiple functions as needed
```

### Data Analysis Assistant
```python
# Functions for data analysis
analysis_tools = [
    load_dataset_tool,
    generate_chart_tool,
    calculate_statistics_tool,
    export_results_tool
]

# User can request: "Load sales data and create a monthly trend chart"
# Model will chain function calls appropriately
```

## Security Considerations

### Function Security
1. **Input validation**: Validate all function parameters
2. **Access control**: Implement proper authorization
3. **Rate limiting**: Prevent function abuse
4. **Audit logging**: Log function executions
5. **Error exposure**: Don't expose sensitive error details

### Safe Function Design
```python
def secure_function(user_id: str, action: str) -> str:
    """Securely execute user action."""
    # Validate user permissions
    if not is_authorized(user_id, action):
        return "Access denied"
    
    # Validate input parameters
    if not validate_input(action):
        return "Invalid input"
    
    # Execute with error handling
    try:
        result = execute_action(action)
        log_action(user_id, action, "success")
        return result
    except Exception as e:
        log_action(user_id, action, "error")
        return "Operation failed"
```

## Testing and Debugging

### Function Testing
```python
def test_function_calling():
    """Test function calling implementation."""
    test_cases = [
        {
            "input": "What's the weather in Sydney?",
            "expected_function": "get_weather",
            "expected_params": {"location": "Sydney"}
        }
    ]
    
    for test in test_cases:
        response = model.generate_content(test["input"])
        assert response.function_call.name == test["expected_function"]
        # Additional assertions
```

### Debug Function Calls
```python
def debug_function_calling(user_input: str):
    """Debug function calling process."""
    print(f"User input: {user_input}")
    
    response = model.generate_content(user_input)
    
    if response.candidates[0].content.parts[0].function_call:
        function_call = response.candidates[0].content.parts[0].function_call
        print(f"Function called: {function_call.name}")
        print(f"Parameters: {dict(function_call.args)}")
        
        result = execute_function_call(function_call)
        print(f"Function result: {result}")
    else:
        print("No function called")
        print(f"Direct response: {response.text}")
```

## Limitations and Considerations

### Model Limitations
- **Function selection**: Model may not always choose optimal function
- **Parameter accuracy**: Parameters may occasionally be incorrect
- **Context awareness**: May miss context clues for function selection
- **Complex chains**: Very complex function chains may fail

### Implementation Considerations
1. **Fallback handling**: Plan for function failures
2. **User confirmation**: Confirm destructive actions
3. **Cost monitoring**: Track function call costs
4. **Performance impact**: Functions add latency
5. **Maintenance**: Keep function definitions updated

### Best Practice Recommendations
1. **Start simple**: Begin with basic functions
2. **Test thoroughly**: Validate all function combinations
3. **Monitor usage**: Track function call patterns
4. **User feedback**: Collect feedback on function accuracy
5. **Iterate design**: Continuously improve function definitions

---

**Last Updated:** Based on Google Gemini API documentation as of 2025
**Reference:** https://ai.google.dev/gemini-api/docs/function-calling
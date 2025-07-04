# LangChain Integration with Vertex AI

Comprehensive guide for building AI agents and applications using LangChain with Google Vertex AI, including the new Vertex AI Agent Engine.

## 🎯 Overview

LangChain + Vertex AI provides:
- **Unified Interface** - Access all Vertex AI models through LangChain
- **Agent Engine** - Build production-ready conversational agents
- **Tool Integration** - Connect to external APIs and functions
- **Memory Management** - Persistent conversation history
- **RAG Support** - Retrieval-augmented generation with Vertex AI Search

## 🚀 Quick Start

### Installation

```bash
# Install LangChain Vertex AI integration
pip install langchain-google-vertexai==2.0.27
pip install langchain langchain-community
pip install google-cloud-aiplatform

# Additional dependencies
pip install chromadb faiss-cpu  # For vector stores
pip install google-cloud-firestore  # For chat history
pip install pandas numpy  # For data processing
```

### Basic Setup

```python
from langchain_google_vertexai import ChatVertexAI, VertexAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain
import vertexai

# Initialize Vertex AI
PROJECT_ID = "your-project-id"
LOCATION = "us-central1"

vertexai.init(project=PROJECT_ID, location=LOCATION)

# Initialize chat model (defaults to gemini-2.0-flash-001)
chat = ChatVertexAI(
    model="gemini-2.5-flash",
    temperature=0.7,
    max_tokens=2048,
    top_p=0.95,
    top_k=40
)

# Simple conversation
response = chat.invoke("Explain quantum computing in simple terms")
print(response.content)
```

## 🤖 Vertex AI Agent Engine

### Creating an Agent

```python
from langchain.agents import AgentExecutor, create_react_agent
from langchain.tools import Tool
from langchain_google_vertexai import ChatVertexAI
from langchain.prompts import PromptTemplate

# Define tools
def search_knowledge_base(query: str) -> str:
    """Search internal knowledge base"""
    # Implementation here
    return f"Results for: {query}"

def calculate(expression: str) -> str:
    """Perform calculations"""
    try:
        result = eval(expression)
        return str(result)
    except:
        return "Invalid expression"

# Create tools
tools = [
    Tool(
        name="KnowledgeBase",
        func=search_knowledge_base,
        description="Search the company knowledge base for information"
    ),
    Tool(
        name="Calculator",
        func=calculate,
        description="Perform mathematical calculations"
    )
]

# Agent prompt
agent_prompt = PromptTemplate.from_template("""
You are a helpful AI assistant with access to tools.

You have access to the following tools:
{tools}

Use the following format:
Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Question: {input}
{agent_scratchpad}
""")

# Create agent
llm = ChatVertexAI(model="gemini-2.5-pro", temperature=0)
agent = create_react_agent(llm, tools, agent_prompt)
agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

# Use agent
result = agent_executor.invoke({"input": "What is 25 * 4 and search for quantum computing basics"})
```

### Production Agent with Memory

```python
from langchain.memory import ConversationBufferMemory
from langchain_google_firestore import FirestoreChatMessageHistory
from langchain.agents import ConversationChain

# Setup Firestore for chat history
message_history = FirestoreChatMessageHistory(
    project_id=PROJECT_ID,
    session_id="user-123",
    collection_name="chat_histories"
)

# Create memory
memory = ConversationBufferMemory(
    chat_memory=message_history,
    return_messages=True,
    memory_key="chat_history"
)

# Create conversational agent
conversation = ConversationChain(
    llm=ChatVertexAI(model="gemini-2.5-flash"),
    memory=memory,
    verbose=True
)

# Conversation with memory
response1 = conversation.run("My name is John")
response2 = conversation.run("What's my name?")  # Will remember John
```

## 🔍 RAG with Vertex AI Search

### Document Retrieval Setup

```python
from langchain_google_vertexai import VertexAISearchRetriever
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Initialize Vertex AI Search retriever
retriever = VertexAISearchRetriever(
    project_id=PROJECT_ID,
    location=LOCATION,
    data_store_id="your-datastore-id",
    max_documents=5,
    filter="category:documentation"  # Optional filter
)

# Create RAG chain
rag_chain = RetrievalQA.from_chain_type(
    llm=ChatVertexAI(model="gemini-2.5-pro"),
    chain_type="stuff",
    retriever=retriever,
    return_source_documents=True
)

# Query with retrieval
result = rag_chain({"query": "How do I configure authentication?"})
print(result["result"])
for doc in result["source_documents"]:
    print(f"Source: {doc.metadata}")
```

### Custom RAG Pipeline

```python
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_google_vertexai import VertexAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.document_loaders import TextLoader
from langchain.text_splitter import CharacterTextSplitter

class CustomRAGPipeline:
    def __init__(self, project_id: str, location: str):
        self.embeddings = VertexAIEmbeddings(
            model_name="text-embedding-004",
            project=project_id,
            location=location
        )
        self.llm = ChatVertexAI(model="gemini-2.5-flash")
        self.vector_store = None
        
    def load_documents(self, file_paths: List[str]):
        """Load and process documents"""
        documents = []
        for path in file_paths:
            loader = TextLoader(path)
            documents.extend(loader.load())
        
        # Split documents
        text_splitter = CharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        chunks = text_splitter.split_documents(documents)
        
        # Create vector store
        self.vector_store = Chroma.from_documents(
            documents=chunks,
            embedding=self.embeddings,
            persist_directory="./chroma_db"
        )
        
    def query(self, question: str, k: int = 4):
        """Query the RAG system"""
        # Retrieve relevant documents
        docs = self.vector_store.similarity_search(question, k=k)
        
        # Format context
        context = "\n\n".join([doc.page_content for doc in docs])
        
        # Generate answer
        prompt = PromptTemplate(
            template="""Use the following context to answer the question. 
            If you cannot answer based on the context, say "I don't have enough information."
            
            Context: {context}
            
            Question: {question}
            
            Answer:""",
            input_variables=["context", "question"]
        )
        
        chain = LLMChain(llm=self.llm, prompt=prompt)
        answer = chain.run(context=context, question=question)
        
        return {
            "answer": answer,
            "sources": [doc.metadata for doc in docs]
        }

# Usage
rag = CustomRAGPipeline(PROJECT_ID, LOCATION)
rag.load_documents(["doc1.txt", "doc2.txt"])
result = rag.query("What is the deployment process?")
```

## 🛠️ Advanced Agent Features

### Multi-Modal Agent

```python
from langchain_google_vertexai import ChatVertexAI
from langchain.schema import HumanMessage
import base64

class MultiModalAgent:
    def __init__(self):
        self.llm = ChatVertexAI(model="gemini-2.5-flash")
    
    def analyze_image(self, image_path: str, question: str):
        """Analyze image with question"""
        with open(image_path, "rb") as f:
            image_bytes = f.read()
        
        image_base64 = base64.b64encode(image_bytes).decode()
        
        message = HumanMessage(
            content=[
                {"type": "text", "text": question},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{image_base64}"
                    }
                }
            ]
        )
        
        response = self.llm.invoke([message])
        return response.content
    
    def process_audio(self, audio_path: str):
        """Process audio file"""
        # Gemini 2.5 supports native audio
        with open(audio_path, "rb") as f:
            audio_bytes = f.read()
        
        audio_base64 = base64.b64encode(audio_bytes).decode()
        
        message = HumanMessage(
            content=[
                {"type": "text", "text": "Transcribe and summarize this audio"},
                {
                    "type": "audio_url",
                    "audio_url": {
                        "url": f"data:audio/mp3;base64,{audio_base64}"
                    }
                }
            ]
        )
        
        response = self.llm.invoke([message])
        return response.content
```

### Function Calling Agent

```python
from langchain.tools import StructuredTool
from pydantic import BaseModel, Field
from typing import Optional

# Define function schemas
class WeatherInput(BaseModel):
    location: str = Field(description="The city and state, e.g., San Francisco, CA")
    unit: Optional[str] = Field(default="celsius", description="Temperature unit")

class DatabaseQuery(BaseModel):
    query: str = Field(description="SQL query to execute")
    database: str = Field(description="Database name")

# Create structured tools
def get_weather(location: str, unit: str = "celsius") -> str:
    """Get weather for a location"""
    # Mock implementation
    return f"Weather in {location}: 22°{unit[0].upper()} and sunny"

def query_database(query: str, database: str) -> str:
    """Execute database query"""
    # Mock implementation
    return f"Executed query on {database}: {query}"

weather_tool = StructuredTool.from_function(
    func=get_weather,
    name="get_weather",
    description="Get current weather for a location",
    args_schema=WeatherInput
)

db_tool = StructuredTool.from_function(
    func=query_database,
    name="query_database",
    description="Execute a database query",
    args_schema=DatabaseQuery
)

# Create agent with structured tools
tools = [weather_tool, db_tool]
agent = create_react_agent(
    ChatVertexAI(model="gemini-2.5-pro"),
    tools,
    agent_prompt
)

executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
```

### Streaming Agent

```python
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler
from typing import AsyncIterator

class StreamingAgent:
    def __init__(self):
        self.llm = ChatVertexAI(
            model="gemini-2.5-flash",
            streaming=True,
            callbacks=[StreamingStdOutCallbackHandler()]
        )
    
    async def stream_response(self, prompt: str) -> AsyncIterator[str]:
        """Stream response tokens"""
        async for chunk in self.llm.astream(prompt):
            yield chunk.content
    
    def chat_with_streaming(self):
        """Interactive chat with streaming"""
        print("Chat started. Type 'quit' to exit.")
        
        while True:
            user_input = input("\nYou: ")
            if user_input.lower() == 'quit':
                break
            
            print("\nAssistant: ", end="", flush=True)
            self.llm.invoke(user_input)
            print()  # New line after response

# Usage
async def main():
    agent = StreamingAgent()
    async for token in agent.stream_response("Tell me a story"):
        print(token, end="", flush=True)
```

## 💾 State Management

### Persistent Agent State

```python
from google.cloud import firestore
from langchain.schema import BaseMessage
import json

class AgentStateManager:
    def __init__(self, project_id: str):
        self.db = firestore.Client(project=project_id)
        
    def save_agent_state(self, session_id: str, state: dict):
        """Save agent state to Firestore"""
        doc_ref = self.db.collection('agent_states').document(session_id)
        doc_ref.set({
            'state': json.dumps(state),
            'updated_at': firestore.SERVER_TIMESTAMP
        })
    
    def load_agent_state(self, session_id: str) -> dict:
        """Load agent state from Firestore"""
        doc_ref = self.db.collection('agent_states').document(session_id)
        doc = doc_ref.get()
        
        if doc.exists:
            return json.loads(doc.to_dict()['state'])
        return {}
    
    def save_conversation(self, session_id: str, messages: List[BaseMessage]):
        """Save conversation history"""
        doc_ref = self.db.collection('conversations').document(session_id)
        doc_ref.set({
            'messages': [
                {
                    'type': msg.__class__.__name__,
                    'content': msg.content,
                    'additional_kwargs': msg.additional_kwargs
                }
                for msg in messages
            ],
            'updated_at': firestore.SERVER_TIMESTAMP
        })
```

## 🔧 Production Deployment

### Agent Service

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import asyncio

app = FastAPI()

class ChatRequest(BaseModel):
    message: str
    session_id: str
    context: Optional[dict] = None

class ChatResponse(BaseModel):
    response: str
    sources: Optional[List[dict]] = None
    session_id: str

class ProductionAgentService:
    def __init__(self):
        self.agents = {}  # Cache agents by session
        self.llm = ChatVertexAI(
            model="gemini-2.5-flash",
            temperature=0.7,
            max_tokens=2048
        )
        
    def get_or_create_agent(self, session_id: str):
        """Get cached agent or create new one"""
        if session_id not in self.agents:
            memory = ConversationBufferMemory(
                return_messages=True,
                memory_key="chat_history"
            )
            
            self.agents[session_id] = ConversationChain(
                llm=self.llm,
                memory=memory
            )
            
        return self.agents[session_id]
    
    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """Process chat message"""
        try:
            agent = self.get_or_create_agent(request.session_id)
            
            # Add context if provided
            if request.context:
                prompt = f"Context: {request.context}\n\nUser: {request.message}"
            else:
                prompt = request.message
            
            # Get response
            response = await asyncio.to_thread(agent.run, prompt)
            
            return ChatResponse(
                response=response,
                session_id=request.session_id
            )
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

# Initialize service
agent_service = ProductionAgentService()

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    return await agent_service.process_message(request)

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### Deployment Configuration

```yaml
# app.yaml for App Engine
runtime: python39
env: standard
instance_class: F4

automatic_scaling:
  min_instances: 1
  max_instances: 10
  target_cpu_utilization: 0.7

env_variables:
  PROJECT_ID: "your-project-id"
  LOCATION: "us-central1"

handlers:
- url: /.*
  script: auto
```

## 📊 Monitoring & Observability

```python
from langchain.callbacks import LangChainTracer
from google.cloud import logging
import time

class AgentMonitor:
    def __init__(self, project_id: str):
        self.logger = logging.Client(project=project_id).logger("vertex-ai-agent")
        self.tracer = LangChainTracer(project_name="vertex-ai-agents")
        
    def log_request(self, session_id: str, request: dict, response: dict, 
                    duration: float):
        """Log agent request/response"""
        self.logger.log_struct({
            "session_id": session_id,
            "request": request,
            "response": response,
            "duration_ms": duration * 1000,
            "model": "gemini-2.5-flash",
            "timestamp": time.time()
        })
    
    def track_metrics(self, metric_name: str, value: float, labels: dict = None):
        """Track custom metrics"""
        self.logger.log_struct({
            "metric": metric_name,
            "value": value,
            "labels": labels or {},
            "timestamp": time.time()
        })
```

## 💰 Cost Optimization

```python
class CostOptimizedAgent:
    def __init__(self):
        # Use different models for different tasks
        self.simple_llm = ChatVertexAI(
            model="gemini-2.5-flash-lite",  # Cheapest
            temperature=0.3
        )
        self.complex_llm = ChatVertexAI(
            model="gemini-2.5-pro",  # Most capable
            temperature=0.7
        )
        
    def route_request(self, query: str, complexity: str = "auto"):
        """Route to appropriate model based on complexity"""
        if complexity == "auto":
            # Simple heuristic - use complex model for longer queries
            complexity = "complex" if len(query) > 100 else "simple"
        
        if complexity == "simple":
            return self.simple_llm.invoke(query)
        else:
            return self.complex_llm.invoke(query)
    
    def batch_process(self, queries: List[str]):
        """Batch process for efficiency"""
        # Batch similar queries together
        return self.simple_llm.batch(queries)
```

## 🎯 Best Practices

1. **Model Selection**:
   - Use Gemini 2.5 Flash for general tasks
   - Use Gemini 2.5 Pro for complex reasoning
   - Use Flash-Lite for high-volume, simple tasks

2. **Memory Management**:
   - Implement conversation pruning for long chats
   - Use Firestore/Bigtable for persistent storage
   - Cache frequently accessed data

3. **Error Handling**:
   - Implement retry logic with exponential backoff
   - Have fallback responses for failures
   - Log all errors for debugging

4. **Performance**:
   - Use streaming for better UX
   - Implement request batching
   - Cache common responses

## 📚 Resources

- [LangChain Vertex AI Docs](https://python.langchain.com/docs/integrations/platforms/google)
- [Vertex AI Agent Builder](https://cloud.google.com/vertex-ai/docs/builder/introduction)
- [Gemini API Reference](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Pricing Calculator](https://cloud.google.com/products/calculator)

---

*Note: Vertex AI Agent Engine billing starts March 4, 2025. Plan your budget accordingly based on vCPU and memory usage.*
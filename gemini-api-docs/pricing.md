# Google Gemini API Pricing

## Overview
Google Gemini API offers flexible pricing with both free and paid tiers to accommodate different usage patterns, from development and testing to enterprise-scale deployments.

## Pricing Tiers

### Free Tier
**Perfect for development, testing, and small applications**
- **Rate limits**: Lower rate limits suitable for development
- **Features**: Access to all model capabilities
- **Data handling**: Different data retention and usage policies
- **Support**: Community support
- **Best for**: Prototyping, learning, small personal projects

### Paid Tier
**Designed for production applications and enterprise use**
- **Rate limits**: Higher rate limits for production workloads
- **Features**: Access to all models and capabilities
- **Data handling**: Enhanced data protection and retention options
- **Support**: Professional support options
- **Best for**: Production applications, commercial use, high-volume processing

## Model Pricing

### Gemini 2.5 Pro
**Most powerful model with advanced thinking capabilities**

#### Input Pricing
- **Text/Image/Video**: $1.25 - $2.50 per 1M tokens
- **Audio**: $5.00 per 1M tokens
- **Context caching**: $0.31 - $0.625 per 1M tokens

#### Output Pricing
- **Text**: $10.00 - $15.00 per 1M tokens
- **Thinking tokens**: Additional cost for thinking capabilities

#### Use Cases
- Complex reasoning and analysis
- Multi-modal content processing
- Advanced coding and technical tasks
- Research and detailed analysis

### Gemini 2.5 Flash
**Optimal balance of performance and cost**

#### Input Pricing
- **Text/Image/Video**: $0.30 per 1M tokens
- **Audio**: $1.00 per 1M tokens
- **Context caching**: $0.075 per 1M tokens

#### Output Pricing
- **Text**: $2.50 per 1M tokens
- **Thinking tokens**: Lower cost than Pro model

#### Use Cases
- Production applications
- Real-time processing
- Balanced performance needs
- Cost-sensitive deployments

### Gemini 2.5 Flash-Lite
**Most cost-effective option for high-volume use**

#### Input Pricing
- **Text/Image/Video**: $0.15 per 1M tokens
- **Audio**: $0.50 per 1M tokens
- **Context caching**: $0.0375 per 1M tokens

#### Output Pricing
- **Text**: $1.25 per 1M tokens
- **Thinking tokens**: Basic thinking capabilities included

#### Use Cases
- High-volume applications
- Simple content generation
- Budget-conscious projects
- Real-time chat applications

## Specialized Services Pricing

### Image Generation (Imagen 4)
- **Standard images**: $0.04 per image
- **Ultra-quality images**: $0.06 per image
- **Image resolution**: Pricing varies by output size
- **Batch processing**: Volume discounts available

### Video Generation (Veo 2)
- **Video generation**: $0.35 per second of generated video
- **Quality options**: Different pricing for various quality levels
- **Length limits**: Maximum video length restrictions apply

### Search Grounding
- **Free allowance**: 1,500 requests per day
- **Paid requests**: $35 per 1,000 requests after free tier
- **Real-time data**: Access to current web information
- **Citation metadata**: Included with grounded responses

### Embeddings
- **Text embeddings**: $0.025 per 1M tokens
- **Batch processing**: Reduced rates for large volumes
- **Vector dimensions**: Pricing consistent across dimension counts
- **Storage**: Separate charges may apply for vector storage

## Token Calculation

### Text Tokens
- **English text**: ~4 characters per token
- **Other languages**: May vary slightly
- **Code**: Similar to English text
- **Special characters**: Counted as tokens

### Multimodal Tokens

#### Images
- **Small images (≤384px)**: 258 tokens
- **Larger images**: Calculated based on tiled sections
- **Processing**: Automatic optimization for token efficiency

#### Audio
- **Rate**: 32 tokens per second of audio
- **Quality**: Token count independent of audio quality
- **Formats**: Consistent across all supported audio formats

#### Video
- **Rate**: Varies by video length and quality
- **Processing**: Optimized for content analysis
- **Frames**: Intelligent frame sampling for efficiency

## Cost Optimization Strategies

### Model Selection
```python\n# Choose appropriate model for task complexity\ndef select_optimal_model(task_complexity: str):\n    \"\"\"Select the most cost-effective model for the task.\"\"\"\n    if task_complexity == \"simple\":\n        return \"gemini-2.5-flash-lite\"  # Most cost-effective\n    elif task_complexity == \"moderate\":\n        return \"gemini-2.5-flash\"       # Balanced cost/performance\n    else:\n        return \"gemini-2.5-pro\"         # Maximum capability\n\n# Usage-based model selection\nclass CostOptimizedClient:\n    def __init__(self):\n        self.models = {\n            \"lite\": genai.GenerativeModel(\"gemini-2.5-flash-lite\"),\n            \"standard\": genai.GenerativeModel(\"gemini-2.5-flash\"),\n            \"pro\": genai.GenerativeModel(\"gemini-2.5-pro\")\n        }\n    \n    def generate_content(self, prompt: str, complexity: str = \"moderate\"):\n        model_key = self.select_model_tier(complexity)\n        return self.models[model_key].generate_content(prompt)\n    \n    def select_model_tier(self, complexity: str) -> str:\n        complexity_map = {\n            \"simple\": \"lite\",\n            \"moderate\": \"standard\",\n            \"complex\": \"pro\"\n        }\n        return complexity_map.get(complexity, \"standard\")\n```\n\n### Token Optimization\n```python\n# Optimize prompts for token efficiency\ndef optimize_prompt_length(prompt: str, max_tokens: int = 1000) -> str:\n    \"\"\"Optimize prompt length while maintaining clarity.\"\"\"\n    if len(prompt.split()) <= max_tokens:\n        return prompt\n    \n    # Truncate while preserving key information\n    words = prompt.split()\n    optimized = \" \".join(words[:max_tokens])\n    return optimized + \"...\" if len(words) > max_tokens else optimized\n\n# Batch processing for efficiency\ndef batch_process_efficiently(prompts: list, batch_size: int = 10):\n    \"\"\"Process multiple prompts efficiently.\"\"\"\n    results = []\n    \n    for i in range(0, len(prompts), batch_size):\n        batch = prompts[i:i + batch_size]\n        \n        # Process batch with appropriate model\n        for prompt in batch:\n            result = model.generate_content(prompt)\n            results.append(result)\n        \n        # Optional: Add delay between batches to manage rate limits\n        time.sleep(0.1)\n    \n    return results\n```\n\n### Context Caching\n```python\n# Use context caching for repeated contexts\nclass CachedContextManager:\n    def __init__(self):\n        self.cached_contexts = {}\n    \n    def generate_with_cached_context(self, context: str, prompt: str):\n        \"\"\"Generate content using cached context when possible.\"\"\"\n        context_hash = hash(context)\n        \n        if context_hash not in self.cached_contexts:\n            # First use - cache the context\n            model = genai.GenerativeModel(\n                \"gemini-2.5-flash\",\n                system_instruction=context\n            )\n            self.cached_contexts[context_hash] = model\n        \n        cached_model = self.cached_contexts[context_hash]\n        return cached_model.generate_content(prompt)\n    \n    def estimate_cache_savings(self, context_length: int, reuse_count: int):\n        \"\"\"Estimate savings from context caching.\"\"\"\n        context_tokens = context_length // 4  # Rough estimate\n        cache_cost_per_use = context_tokens * 0.075 / 1000000  # Cache pricing\n        regular_cost_per_use = context_tokens * 0.30 / 1000000  # Regular input pricing\n        \n        total_cache_cost = cache_cost_per_use * reuse_count\n        total_regular_cost = regular_cost_per_use * reuse_count\n        \n        return {\n            \"cache_cost\": total_cache_cost,\n            \"regular_cost\": total_regular_cost,\n            \"savings\": total_regular_cost - total_cache_cost,\n            \"savings_percentage\": ((total_regular_cost - total_cache_cost) / total_regular_cost) * 100\n        }\n```\n\n## Usage Monitoring and Cost Control\n\n### Usage Tracking\n```python\nclass UsageTracker:\n    def __init__(self):\n        self.usage_stats = {\n            \"total_requests\": 0,\n            \"total_input_tokens\": 0,\n            \"total_output_tokens\": 0,\n            \"total_cost\": 0.0,\n            \"model_usage\": {},\n            \"daily_usage\": {}\n        }\n    \n    def track_request(self, model_name: str, input_tokens: int, output_tokens: int):\n        \"\"\"Track usage for a single request.\"\"\"\n        cost = self.calculate_cost(model_name, input_tokens, output_tokens)\n        \n        self.usage_stats[\"total_requests\"] += 1\n        self.usage_stats[\"total_input_tokens\"] += input_tokens\n        self.usage_stats[\"total_output_tokens\"] += output_tokens\n        self.usage_stats[\"total_cost\"] += cost\n        \n        # Track by model\n        if model_name not in self.usage_stats[\"model_usage\"]:\n            self.usage_stats[\"model_usage\"][model_name] = {\n                \"requests\": 0, \"input_tokens\": 0, \"output_tokens\": 0, \"cost\": 0.0\n            }\n        \n        model_stats = self.usage_stats[\"model_usage\"][model_name]\n        model_stats[\"requests\"] += 1\n        model_stats[\"input_tokens\"] += input_tokens\n        model_stats[\"output_tokens\"] += output_tokens\n        model_stats[\"cost\"] += cost\n        \n        # Track daily usage\n        today = datetime.now().strftime(\"%Y-%m-%d\")\n        if today not in self.usage_stats[\"daily_usage\"]:\n            self.usage_stats[\"daily_usage\"][today] = {\"requests\": 0, \"cost\": 0.0}\n        \n        self.usage_stats[\"daily_usage\"][today][\"requests\"] += 1\n        self.usage_stats[\"daily_usage\"][today][\"cost\"] += cost\n    \n    def calculate_cost(self, model_name: str, input_tokens: int, output_tokens: int) -> float:\n        \"\"\"Calculate cost for a request.\"\"\"\n        pricing = {\n            \"gemini-2.5-pro\": {\"input\": 2.50, \"output\": 15.00},\n            \"gemini-2.5-flash\": {\"input\": 0.30, \"output\": 2.50},\n            \"gemini-2.5-flash-lite\": {\"input\": 0.15, \"output\": 1.25}\n        }\n        \n        if model_name not in pricing:\n            return 0.0\n        \n        rates = pricing[model_name]\n        input_cost = (input_tokens / 1000000) * rates[\"input\"]\n        output_cost = (output_tokens / 1000000) * rates[\"output\"]\n        \n        return input_cost + output_cost\n    \n    def get_usage_report(self) -> dict:\n        \"\"\"Generate comprehensive usage report.\"\"\"\n        return {\n            \"summary\": {\n                \"total_requests\": self.usage_stats[\"total_requests\"],\n                \"total_cost\": round(self.usage_stats[\"total_cost\"], 4),\n                \"avg_cost_per_request\": round(\n                    self.usage_stats[\"total_cost\"] / max(1, self.usage_stats[\"total_requests\"]), 4\n                )\n            },\n            \"by_model\": self.usage_stats[\"model_usage\"],\n            \"daily_usage\": self.usage_stats[\"daily_usage\"]\n        }\n```\n\n### Budget Controls\n```python\nclass BudgetController:\n    def __init__(self, daily_budget: float, monthly_budget: float):\n        self.daily_budget = daily_budget\n        self.monthly_budget = monthly_budget\n        self.usage_tracker = UsageTracker()\n    \n    def check_budget_before_request(self, estimated_cost: float) -> bool:\n        \"\"\"Check if request fits within budget constraints.\"\"\"\n        today = datetime.now().strftime(\"%Y-%m-%d\")\n        month = datetime.now().strftime(\"%Y-%m\")\n        \n        # Check daily budget\n        daily_usage = self.usage_tracker.usage_stats[\"daily_usage\"].get(today, {\"cost\": 0.0})\n        if daily_usage[\"cost\"] + estimated_cost > self.daily_budget:\n            return False\n        \n        # Check monthly budget\n        monthly_cost = sum(\n            day_usage[\"cost\"] for date, day_usage in self.usage_tracker.usage_stats[\"daily_usage\"].items()\n            if date.startswith(month)\n        )\n        if monthly_cost + estimated_cost > self.monthly_budget:\n            return False\n        \n        return True\n    \n    def safe_generate_content(self, model_name: str, prompt: str, estimated_tokens: int = 1000):\n        \"\"\"Generate content with budget checking.\"\"\"\n        estimated_cost = self.usage_tracker.calculate_cost(model_name, len(prompt.split()), estimated_tokens)\n        \n        if not self.check_budget_before_request(estimated_cost):\n            raise Exception(\"Request would exceed budget limits\")\n        \n        # Proceed with generation\n        model = genai.GenerativeModel(model_name)\n        response = model.generate_content(prompt)\n        \n        # Track actual usage\n        actual_input_tokens = len(prompt.split())  # Simplified\n        actual_output_tokens = len(response.text.split())  # Simplified\n        self.usage_tracker.track_request(model_name, actual_input_tokens, actual_output_tokens)\n        \n        return response\n```\n\n## Enterprise Pricing\n\n### Volume Discounts\n- **High-volume usage**: Custom pricing for enterprise customers\n- **Commitment discounts**: Reduced rates for usage commitments\n- **Multi-year agreements**: Additional discounts for longer terms\n- **Custom SLAs**: Service level agreements for enterprise needs\n\n### Enterprise Features\n- **Dedicated instances**: Isolated compute resources\n- **Custom models**: Fine-tuned models for specific use cases\n- **Priority support**: Enhanced support options\n- **Data residency**: Geographic data processing options\n- **Compliance**: Enhanced compliance and security features\n\n## Regional Pricing Variations\n\n### Availability by Region\n- **Primary regions**: Full feature availability\n- **Secondary regions**: May have limited features\n- **Pricing differences**: Minor variations by region\n- **Data processing**: Location of data processing may affect pricing\n\n### Google AI Studio\n- **Free usage**: Available in supported regions\n- **Regional restrictions**: Some regions may have limited access\n- **Feature parity**: Core features available globally\n\n## Billing and Payment\n\n### Payment Methods\n- **Credit cards**: Standard payment method\n- **Google Cloud billing**: Integration with existing GCP accounts\n- **Purchase orders**: Available for enterprise customers\n- **Prepaid credits**: Available for some regions and use cases\n\n### Billing Cycles\n- **Monthly billing**: Standard billing cycle\n- **Usage-based**: Pay only for what you use\n- **Minimum charges**: Some services may have minimum charges\n- **Billing alerts**: Set up alerts for usage thresholds\n\n## Cost Estimation Tools\n\n### Simple Cost Calculator\n```python\ndef estimate_monthly_cost(\n    requests_per_day: int,\n    avg_input_tokens: int,\n    avg_output_tokens: int,\n    model_name: str = \"gemini-2.5-flash\"\n) -> dict:\n    \"\"\"Estimate monthly costs based on usage patterns.\"\"\"\n    \n    # Pricing per 1M tokens\n    pricing = {\n        \"gemini-2.5-pro\": {\"input\": 2.50, \"output\": 15.00},\n        \"gemini-2.5-flash\": {\"input\": 0.30, \"output\": 2.50},\n        \"gemini-2.5-flash-lite\": {\"input\": 0.15, \"output\": 1.25}\n    }\n    \n    if model_name not in pricing:\n        raise ValueError(f\"Unknown model: {model_name}\")\n    \n    rates = pricing[model_name]\n    \n    # Calculate daily costs\n    daily_input_cost = (requests_per_day * avg_input_tokens / 1000000) * rates[\"input\"]\n    daily_output_cost = (requests_per_day * avg_output_tokens / 1000000) * rates[\"output\"]\n    daily_total = daily_input_cost + daily_output_cost\n    \n    # Calculate monthly costs (30 days)\n    monthly_total = daily_total * 30\n    \n    return {\n        \"model\": model_name,\n        \"daily_requests\": requests_per_day,\n        \"daily_cost\": round(daily_total, 4),\n        \"monthly_cost\": round(monthly_total, 2),\n        \"breakdown\": {\n            \"input_cost_daily\": round(daily_input_cost, 4),\n            \"output_cost_daily\": round(daily_output_cost, 4)\n        }\n    }\n\n# Usage examples\nscenarios = [\n    {\"name\": \"Small App\", \"requests\": 100, \"input\": 50, \"output\": 200},\n    {\"name\": \"Medium App\", \"requests\": 1000, \"input\": 100, \"output\": 400},\n    {\"name\": \"Large App\", \"requests\": 10000, \"input\": 200, \"output\": 800}\n]\n\nfor scenario in scenarios:\n    cost = estimate_monthly_cost(\n        scenario[\"requests\"], \n        scenario[\"input\"], \n        scenario[\"output\"]\n    )\n    print(f\"{scenario['name']}: ${cost['monthly_cost']}/month\")\n```\n\n## Best Practices for Cost Management\n\n### Development Phase\n1. **Use free tier**: Maximize free tier usage for development\n2. **Prototype with cheaper models**: Start with Flash-Lite for prototyping\n3. **Monitor usage closely**: Track costs from the beginning\n4. **Optimize early**: Establish cost-efficient patterns early\n\n### Production Phase\n1. **Right-size models**: Use appropriate model for each use case\n2. **Implement caching**: Cache responses where appropriate\n3. **Batch processing**: Group requests for efficiency\n4. **Set budget alerts**: Monitor and control costs actively\n5. **Regular optimization**: Continuously optimize for cost and performance\n\n### Enterprise Considerations\n1. **Volume planning**: Plan for volume discounts\n2. **Multi-model strategy**: Use different models for different tasks\n3. **Cost allocation**: Track costs by team or project\n4. **Performance monitoring**: Balance cost with performance requirements\n5. **Vendor negotiation**: Work with Google for enterprise pricing\n\n---\n\n**Last Updated:** Based on Google Gemini API documentation as of 2025\n**Pricing Reference:** https://ai.google.dev/pricing\n**Note:** Prices are subject to change. Check official pricing page for current rates.
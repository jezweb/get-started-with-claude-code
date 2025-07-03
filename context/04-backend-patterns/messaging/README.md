# Messaging Patterns

Comprehensive guide to implementing messaging patterns including message queues, pub/sub architecture, event sourcing, CQRS, and real-time communication strategies.

## 🎯 Messaging Overview

Messaging patterns enable scalable, decoupled architectures:
- **Message Queues** - Point-to-point messaging
- **Pub/Sub** - Broadcast messaging to multiple consumers
- **Event Sourcing** - Store state changes as events
- **CQRS** - Separate read and write models
- **Webhooks** - HTTP-based event notifications
- **Real-time Updates** - WebSockets, SSE, and streaming

## 📬 Message Queue Patterns

### Basic Queue Implementation

```python
# RabbitMQ implementation
import pika
import json
from typing import Callable, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import asyncio
import aio_pika

@dataclass
class Message:
    """Base message structure"""
    id: str
    type: str
    payload: Dict[str, Any]
    timestamp: datetime
    correlation_id: Optional[str] = None
    reply_to: Optional[str] = None
    headers: Optional[Dict[str, Any]] = None

class RabbitMQPublisher:
    """RabbitMQ message publisher"""
    
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
        self.connection = None
        self.channel = None
    
    async def connect(self):
        """Establish connection"""
        self.connection = await aio_pika.connect_robust(self.connection_url)
        self.channel = await self.connection.channel()
        await self.channel.set_qos(prefetch_count=10)
    
    async def publish(
        self,
        queue_name: str,
        message: Message,
        persistent: bool = True
    ):
        """Publish message to queue"""
        # Declare queue
        queue = await self.channel.declare_queue(
            queue_name,
            durable=True
        )
        
        # Prepare message
        body = json.dumps({
            "id": message.id,
            "type": message.type,
            "payload": message.payload,
            "timestamp": message.timestamp.isoformat(),
            "correlation_id": message.correlation_id,
            "reply_to": message.reply_to
        })
        
        # Publish
        await self.channel.default_exchange.publish(
            aio_pika.Message(
                body=body.encode(),
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT if persistent else aio_pika.DeliveryMode.NOT_PERSISTENT,
                correlation_id=message.correlation_id,
                reply_to=message.reply_to,
                headers=message.headers
            ),
            routing_key=queue_name
        )
    
    async def close(self):
        """Close connection"""
        if self.connection:
            await self.connection.close()

class RabbitMQConsumer:
    """RabbitMQ message consumer"""
    
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
        self.connection = None
        self.channel = None
        self.handlers: Dict[str, Callable] = {}
    
    def register_handler(self, message_type: str, handler: Callable):
        """Register message handler"""
        self.handlers[message_type] = handler
    
    async def connect(self):
        """Establish connection"""
        self.connection = await aio_pika.connect_robust(self.connection_url)
        self.channel = await self.connection.channel()
    
    async def consume(
        self,
        queue_name: str,
        auto_ack: bool = False
    ):
        """Start consuming messages"""
        # Declare queue
        queue = await self.channel.declare_queue(
            queue_name,
            durable=True
        )
        
        async for message in queue:
            try:
                # Parse message
                body = json.loads(message.body.decode())
                msg = Message(
                    id=body["id"],
                    type=body["type"],
                    payload=body["payload"],
                    timestamp=datetime.fromisoformat(body["timestamp"]),
                    correlation_id=body.get("correlation_id"),
                    reply_to=body.get("reply_to"),
                    headers=dict(message.headers) if message.headers else None
                )
                
                # Find handler
                handler = self.handlers.get(msg.type)
                if handler:
                    await handler(msg)
                
                # Acknowledge message
                if not auto_ack:
                    await message.ack()
                    
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                if not auto_ack:
                    await message.reject(requeue=True)

# Dead Letter Queue (DLQ) pattern
class MessageQueueWithDLQ:
    """Message queue with dead letter handling"""
    
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
        self.connection = None
        self.channel = None
    
    async def setup_queue_with_dlq(
        self,
        queue_name: str,
        dlq_name: Optional[str] = None,
        max_retries: int = 3,
        ttl: int = 3600000  # 1 hour in milliseconds
    ):
        """Setup queue with dead letter queue"""
        if not dlq_name:
            dlq_name = f"{queue_name}.dlq"
        
        connection = await aio_pika.connect_robust(self.connection_url)
        channel = await connection.channel()
        
        # Declare DLQ
        dlq = await channel.declare_queue(
            dlq_name,
            durable=True
        )
        
        # Declare main queue with DLQ settings
        queue = await channel.declare_queue(
            queue_name,
            durable=True,
            arguments={
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": dlq_name,
                "x-message-ttl": ttl,
                "x-max-length": 10000
            }
        )
        
        return queue, dlq
    
    async def process_with_retry(
        self,
        message: aio_pika.IncomingMessage,
        handler: Callable,
        max_retries: int = 3
    ):
        """Process message with retry logic"""
        # Get retry count from headers
        retry_count = 0
        if message.headers:
            retry_count = message.headers.get("x-retry-count", 0)
        
        try:
            # Process message
            await handler(message)
            await message.ack()
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            
            if retry_count < max_retries:
                # Requeue with incremented retry count
                await self.channel.default_exchange.publish(
                    aio_pika.Message(
                        body=message.body,
                        headers={
                            **dict(message.headers or {}),
                            "x-retry-count": retry_count + 1,
                            "x-last-error": str(e),
                            "x-failed-at": datetime.utcnow().isoformat()
                        }
                    ),
                    routing_key=message.routing_key
                )
                await message.ack()  # Remove from current queue
            else:
                # Max retries exceeded, reject to DLQ
                await message.reject(requeue=False)
```

### Priority Queues

```python
# Priority queue implementation
class PriorityQueueManager:
    """Priority-based message processing"""
    
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
    
    async def create_priority_queue(
        self,
        queue_name: str,
        max_priority: int = 10
    ):
        """Create queue with priority support"""
        connection = await aio_pika.connect_robust(self.connection_url)
        channel = await connection.channel()
        
        # Declare priority queue
        queue = await channel.declare_queue(
            queue_name,
            durable=True,
            arguments={
                "x-max-priority": max_priority
            }
        )
        
        return queue
    
    async def publish_with_priority(
        self,
        queue_name: str,
        message: Message,
        priority: int = 0
    ):
        """Publish message with priority"""
        connection = await aio_pika.connect_robust(self.connection_url)
        channel = await connection.channel()
        
        await channel.default_exchange.publish(
            aio_pika.Message(
                body=json.dumps(message.__dict__).encode(),
                priority=priority
            ),
            routing_key=queue_name
        )

# Delayed message queue
class DelayedMessageQueue:
    """Queue with message delay support"""
    
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
    
    async def setup_delayed_queue(
        self,
        queue_name: str,
        delay_exchange_name: str = None
    ):
        """Setup queue with delay support using delayed message plugin"""
        if not delay_exchange_name:
            delay_exchange_name = f"{queue_name}.delay"
        
        connection = await aio_pika.connect_robust(self.connection_url)
        channel = await connection.channel()
        
        # Declare delayed exchange (requires plugin)
        delay_exchange = await channel.declare_exchange(
            delay_exchange_name,
            type="x-delayed-message",
            arguments={
                "x-delayed-type": "direct"
            }
        )
        
        # Declare target queue
        queue = await channel.declare_queue(
            queue_name,
            durable=True
        )
        
        # Bind queue to exchange
        await queue.bind(delay_exchange, routing_key=queue_name)
        
        return delay_exchange, queue
    
    async def publish_delayed(
        self,
        exchange_name: str,
        routing_key: str,
        message: Message,
        delay_ms: int
    ):
        """Publish message with delay"""
        connection = await aio_pika.connect_robust(self.connection_url)
        channel = await connection.channel()
        
        exchange = await channel.get_exchange(exchange_name)
        
        await exchange.publish(
            aio_pika.Message(
                body=json.dumps(message.__dict__).encode(),
                headers={
                    "x-delay": delay_ms
                }
            ),
            routing_key=routing_key
        )
```

## 📡 Pub/Sub Architecture

### Event Bus Implementation

```python
# In-memory event bus
from typing import List, Set
import asyncio
from collections import defaultdict

class EventBus:
    """In-memory publish/subscribe event bus"""
    
    def __init__(self):
        self._subscribers: Dict[str, Set[Callable]] = defaultdict(set)
        self._async_subscribers: Dict[str, Set[Callable]] = defaultdict(set)
    
    def subscribe(self, event_type: str, handler: Callable):
        """Subscribe to event"""
        if asyncio.iscoroutinefunction(handler):
            self._async_subscribers[event_type].add(handler)
        else:
            self._subscribers[event_type].add(handler)
    
    def unsubscribe(self, event_type: str, handler: Callable):
        """Unsubscribe from event"""
        self._subscribers[event_type].discard(handler)
        self._async_subscribers[event_type].discard(handler)
    
    async def publish(self, event_type: str, data: Any):
        """Publish event to subscribers"""
        # Sync handlers
        for handler in self._subscribers[event_type]:
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Error in sync handler: {e}")
        
        # Async handlers
        tasks = []
        for handler in self._async_subscribers[event_type]:
            task = asyncio.create_task(self._call_async_handler(handler, data))
            tasks.append(task)
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _call_async_handler(self, handler: Callable, data: Any):
        """Call async handler with error handling"""
        try:
            await handler(data)
        except Exception as e:
            logger.error(f"Error in async handler: {e}")

# Redis Pub/Sub
class RedisPubSub:
    """Redis-based pub/sub implementation"""
    
    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.redis = None
        self.pubsub = None
        self._running = False
        self._handlers: Dict[str, List[Callable]] = defaultdict(list)
    
    async def connect(self):
        """Connect to Redis"""
        import aioredis
        self.redis = await aioredis.from_url(self.redis_url)
        self.pubsub = self.redis.pubsub()
    
    async def subscribe(self, channel: str, handler: Callable):
        """Subscribe to channel"""
        await self.pubsub.subscribe(channel)
        self._handlers[channel].append(handler)
    
    async def publish(self, channel: str, message: Any):
        """Publish message to channel"""
        if isinstance(message, dict):
            message = json.dumps(message)
        await self.redis.publish(channel, message)
    
    async def start(self):
        """Start listening for messages"""
        self._running = True
        
        async for message in self.pubsub.listen():
            if not self._running:
                break
            
            if message["type"] == "message":
                channel = message["channel"].decode()
                data = message["data"].decode()
                
                # Parse JSON if possible
                try:
                    data = json.loads(data)
                except json.JSONDecodeError:
                    pass
                
                # Call handlers
                for handler in self._handlers.get(channel, []):
                    try:
                        if asyncio.iscoroutinefunction(handler):
                            await handler(data)
                        else:
                            handler(data)
                    except Exception as e:
                        logger.error(f"Error in handler: {e}")
    
    async def stop(self):
        """Stop listening"""
        self._running = False
        await self.pubsub.unsubscribe()
        await self.redis.close()

# Topic-based pub/sub with pattern matching
class TopicPubSub:
    """Topic-based pub/sub with wildcards"""
    
    def __init__(self):
        self._subscribers: Dict[str, Set[Callable]] = defaultdict(set)
        self._pattern_subscribers: List[Tuple[str, Callable]] = []
    
    def subscribe(self, topic_pattern: str, handler: Callable):
        """Subscribe to topic pattern (supports wildcards)"""
        if "*" in topic_pattern or "#" in topic_pattern:
            # Pattern subscription
            regex_pattern = self._pattern_to_regex(topic_pattern)
            self._pattern_subscribers.append((regex_pattern, handler))
        else:
            # Exact topic subscription
            self._subscribers[topic_pattern].add(handler)
    
    def _pattern_to_regex(self, pattern: str) -> str:
        """Convert topic pattern to regex"""
        # Convert MQTT-style wildcards to regex
        # + matches one level, # matches multiple levels
        pattern = pattern.replace(".", "\\.")
        pattern = pattern.replace("+", "[^.]+")
        pattern = pattern.replace("#", ".*")
        return f"^{pattern}$"
    
    async def publish(self, topic: str, message: Any):
        """Publish to topic"""
        # Exact matches
        for handler in self._subscribers.get(topic, []):
            await self._call_handler(handler, topic, message)
        
        # Pattern matches
        for pattern, handler in self._pattern_subscribers:
            if re.match(pattern, topic):
                await self._call_handler(handler, topic, message)
    
    async def _call_handler(self, handler: Callable, topic: str, message: Any):
        """Call handler with error handling"""
        try:
            if asyncio.iscoroutinefunction(handler):
                await handler(topic, message)
            else:
                handler(topic, message)
        except Exception as e:
            logger.error(f"Error in handler for topic {topic}: {e}")
```

## 📚 Event Sourcing

### Event Store Implementation

```python
# Event sourcing with event store
from abc import ABC, abstractmethod
from typing import List, Optional, Type
import uuid

class DomainEvent(ABC):
    """Base domain event"""
    
    def __init__(self, aggregate_id: str):
        self.event_id = str(uuid.uuid4())
        self.aggregate_id = aggregate_id
        self.occurred_at = datetime.utcnow()
        self.version = 1
    
    @property
    @abstractmethod
    def event_type(self) -> str:
        pass

class EventStore(ABC):
    """Event store interface"""
    
    @abstractmethod
    async def save_events(
        self,
        aggregate_id: str,
        events: List[DomainEvent],
        expected_version: Optional[int] = None
    ):
        pass
    
    @abstractmethod
    async def get_events(
        self,
        aggregate_id: str,
        from_version: Optional[int] = None
    ) -> List[DomainEvent]:
        pass

class PostgresEventStore(EventStore):
    """PostgreSQL event store implementation"""
    
    def __init__(self, db_session):
        self.db = db_session
    
    async def save_events(
        self,
        aggregate_id: str,
        events: List[DomainEvent],
        expected_version: Optional[int] = None
    ):
        """Save events with optimistic concurrency control"""
        # Check expected version
        if expected_version is not None:
            current_version = await self._get_aggregate_version(aggregate_id)
            if current_version != expected_version:
                raise ConcurrencyException(
                    f"Expected version {expected_version}, but was {current_version}"
                )
        
        # Save events
        for event in events:
            await self.db.execute("""
                INSERT INTO events (
                    event_id, aggregate_id, event_type,
                    event_data, event_version, occurred_at
                ) VALUES (
                    :event_id, :aggregate_id, :event_type,
                    :event_data, :event_version, :occurred_at
                )
            """, {
                "event_id": event.event_id,
                "aggregate_id": event.aggregate_id,
                "event_type": event.event_type,
                "event_data": json.dumps(event.__dict__),
                "event_version": event.version,
                "occurred_at": event.occurred_at
            })
        
        await self.db.commit()
    
    async def get_events(
        self,
        aggregate_id: str,
        from_version: Optional[int] = None
    ) -> List[DomainEvent]:
        """Get events for aggregate"""
        query = """
            SELECT * FROM events
            WHERE aggregate_id = :aggregate_id
        """
        params = {"aggregate_id": aggregate_id}
        
        if from_version:
            query += " AND event_version > :from_version"
            params["from_version"] = from_version
        
        query += " ORDER BY event_version ASC"
        
        results = await self.db.execute(query, params)
        
        # Deserialize events
        events = []
        for row in results:
            event_class = self._get_event_class(row["event_type"])
            event_data = json.loads(row["event_data"])
            event = event_class(**event_data)
            events.append(event)
        
        return events
    
    async def _get_aggregate_version(self, aggregate_id: str) -> int:
        """Get current version of aggregate"""
        result = await self.db.execute("""
            SELECT MAX(event_version) as version
            FROM events
            WHERE aggregate_id = :aggregate_id
        """, {"aggregate_id": aggregate_id})
        
        row = result.first()
        return row["version"] if row["version"] else 0

# Event-sourced aggregate
class AggregateRoot(ABC):
    """Base aggregate root with event sourcing"""
    
    def __init__(self, aggregate_id: str):
        self.id = aggregate_id
        self.version = 0
        self._uncommitted_events: List[DomainEvent] = []
    
    def apply_event(self, event: DomainEvent):
        """Apply event to aggregate"""
        # Update version
        self.version = event.version
        
        # Call event handler
        handler_name = f"_handle_{event.event_type}"
        handler = getattr(self, handler_name, None)
        if handler:
            handler(event)
    
    def raise_event(self, event: DomainEvent):
        """Raise new event"""
        event.version = self.version + 1
        self._uncommitted_events.append(event)
        self.apply_event(event)
    
    def get_uncommitted_events(self) -> List[DomainEvent]:
        """Get uncommitted events"""
        return self._uncommitted_events
    
    def mark_events_as_committed(self):
        """Clear uncommitted events"""
        self._uncommitted_events.clear()

# Example: Order aggregate
class OrderCreatedEvent(DomainEvent):
    event_type = "order_created"
    
    def __init__(self, order_id: str, customer_id: str, items: List[dict]):
        super().__init__(order_id)
        self.customer_id = customer_id
        self.items = items

class OrderShippedEvent(DomainEvent):
    event_type = "order_shipped"
    
    def __init__(self, order_id: str, tracking_number: str):
        super().__init__(order_id)
        self.tracking_number = tracking_number

class Order(AggregateRoot):
    """Order aggregate"""
    
    def __init__(self, order_id: str):
        super().__init__(order_id)
        self.customer_id = None
        self.items = []
        self.status = "pending"
        self.tracking_number = None
    
    @classmethod
    def create(cls, order_id: str, customer_id: str, items: List[dict]) -> 'Order':
        """Create new order"""
        order = cls(order_id)
        order.raise_event(OrderCreatedEvent(order_id, customer_id, items))
        return order
    
    def ship(self, tracking_number: str):
        """Ship order"""
        if self.status != "pending":
            raise ValueError("Order must be pending to ship")
        
        self.raise_event(OrderShippedEvent(self.id, tracking_number))
    
    def _handle_order_created(self, event: OrderCreatedEvent):
        """Handle order created event"""
        self.customer_id = event.customer_id
        self.items = event.items
        self.status = "pending"
    
    def _handle_order_shipped(self, event: OrderShippedEvent):
        """Handle order shipped event"""
        self.tracking_number = event.tracking_number
        self.status = "shipped"

# Event sourcing repository
class EventSourcingRepository:
    """Repository for event-sourced aggregates"""
    
    def __init__(self, event_store: EventStore):
        self.event_store = event_store
    
    async def save(self, aggregate: AggregateRoot):
        """Save aggregate events"""
        events = aggregate.get_uncommitted_events()
        if events:
            await self.event_store.save_events(
                aggregate.id,
                events,
                aggregate.version - len(events)
            )
            aggregate.mark_events_as_committed()
    
    async def get(
        self,
        aggregate_class: Type[AggregateRoot],
        aggregate_id: str
    ) -> Optional[AggregateRoot]:
        """Rebuild aggregate from events"""
        events = await self.event_store.get_events(aggregate_id)
        
        if not events:
            return None
        
        # Create aggregate instance
        aggregate = aggregate_class(aggregate_id)
        
        # Apply events
        for event in events:
            aggregate.apply_event(event)
        
        return aggregate
```

## 🔄 CQRS Pattern

### Command and Query Separation

```python
# CQRS implementation
from abc import ABC, abstractmethod
from dataclasses import dataclass

# Commands
class Command(ABC):
    """Base command"""
    pass

@dataclass
class CreateOrderCommand(Command):
    customer_id: str
    items: List[dict]
    
@dataclass
class ShipOrderCommand(Command):
    order_id: str
    tracking_number: str

# Command handlers
class CommandHandler(ABC):
    """Base command handler"""
    
    @abstractmethod
    async def handle(self, command: Command):
        pass

class CreateOrderHandler(CommandHandler):
    """Handle order creation"""
    
    def __init__(self, repository: EventSourcingRepository):
        self.repository = repository
    
    async def handle(self, command: CreateOrderCommand) -> str:
        # Create order
        order_id = str(uuid.uuid4())
        order = Order.create(
            order_id,
            command.customer_id,
            command.items
        )
        
        # Save
        await self.repository.save(order)
        
        return order_id

# Command bus
class CommandBus:
    """Route commands to handlers"""
    
    def __init__(self):
        self._handlers: Dict[Type[Command], CommandHandler] = {}
    
    def register(self, command_type: Type[Command], handler: CommandHandler):
        """Register command handler"""
        self._handlers[command_type] = handler
    
    async def send(self, command: Command) -> Any:
        """Send command to handler"""
        handler = self._handlers.get(type(command))
        if not handler:
            raise ValueError(f"No handler for command {type(command)}")
        
        return await handler.handle(command)

# Query side
class Query(ABC):
    """Base query"""
    pass

@dataclass
class GetOrderByIdQuery(Query):
    order_id: str

@dataclass
class GetOrdersByCustomerQuery(Query):
    customer_id: str
    status: Optional[str] = None
    limit: int = 100

# Read models
class OrderReadModel:
    """Denormalized order read model"""
    
    def __init__(self, db_session):
        self.db = db_session
    
    async def update_from_event(self, event: DomainEvent):
        """Update read model from event"""
        if isinstance(event, OrderCreatedEvent):
            await self.db.execute("""
                INSERT INTO order_read_model (
                    order_id, customer_id, status, created_at
                ) VALUES (
                    :order_id, :customer_id, :status, :created_at
                )
            """, {
                "order_id": event.aggregate_id,
                "customer_id": event.customer_id,
                "status": "pending",
                "created_at": event.occurred_at
            })
            
            # Insert items
            for item in event.items:
                await self.db.execute("""
                    INSERT INTO order_items_read_model (
                        order_id, product_id, quantity, price
                    ) VALUES (
                        :order_id, :product_id, :quantity, :price
                    )
                """, {
                    "order_id": event.aggregate_id,
                    **item
                })
        
        elif isinstance(event, OrderShippedEvent):
            await self.db.execute("""
                UPDATE order_read_model
                SET status = 'shipped',
                    tracking_number = :tracking_number,
                    shipped_at = :shipped_at
                WHERE order_id = :order_id
            """, {
                "order_id": event.aggregate_id,
                "tracking_number": event.tracking_number,
                "shipped_at": event.occurred_at
            })

# Query handlers
class QueryHandler(ABC):
    """Base query handler"""
    
    @abstractmethod
    async def handle(self, query: Query):
        pass

class GetOrderByIdHandler(QueryHandler):
    """Get order by ID"""
    
    def __init__(self, db_session):
        self.db = db_session
    
    async def handle(self, query: GetOrderByIdQuery) -> Optional[dict]:
        result = await self.db.execute("""
            SELECT o.*, array_agg(
                json_build_object(
                    'product_id', i.product_id,
                    'quantity', i.quantity,
                    'price', i.price
                )
            ) as items
            FROM order_read_model o
            LEFT JOIN order_items_read_model i ON o.order_id = i.order_id
            WHERE o.order_id = :order_id
            GROUP BY o.order_id
        """, {"order_id": query.order_id})
        
        row = result.first()
        return dict(row) if row else None

# Event projections
class EventProjector:
    """Project events to read models"""
    
    def __init__(self):
        self._projections: List[Callable] = []
    
    def register(self, projection: Callable):
        """Register projection"""
        self._projections.append(projection)
    
    async def project(self, event: DomainEvent):
        """Project event to all registered projections"""
        tasks = []
        for projection in self._projections:
            if asyncio.iscoroutinefunction(projection):
                task = asyncio.create_task(projection(event))
                tasks.append(task)
            else:
                projection(event)
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
```

## 🔔 Webhook Patterns

### Webhook Implementation

```python
# Webhook delivery system
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

@dataclass
class WebhookEvent:
    """Webhook event payload"""
    id: str
    type: str
    data: Dict[str, Any]
    occurred_at: datetime
    attempts: int = 0
    last_attempt_at: Optional[datetime] = None
    next_retry_at: Optional[datetime] = None

class WebhookDeliveryService:
    """Webhook delivery with retries"""
    
    def __init__(self, db_session):
        self.db = db_session
        self.http_client = httpx.AsyncClient(timeout=30.0)
    
    async def register_webhook(
        self,
        url: str,
        events: List[str],
        secret: Optional[str] = None
    ) -> str:
        """Register webhook endpoint"""
        webhook_id = str(uuid.uuid4())
        
        await self.db.execute("""
            INSERT INTO webhooks (
                webhook_id, url, events, secret, is_active
            ) VALUES (
                :webhook_id, :url, :events, :secret, :is_active
            )
        """, {
            "webhook_id": webhook_id,
            "url": url,
            "events": json.dumps(events),
            "secret": secret,
            "is_active": True
        })
        
        return webhook_id
    
    async def send_webhook(
        self,
        webhook_id: str,
        event: WebhookEvent
    ):
        """Send webhook with retry logic"""
        # Get webhook config
        webhook = await self._get_webhook(webhook_id)
        if not webhook or not webhook["is_active"]:
            return
        
        # Check if event type is subscribed
        if event.type not in webhook["events"]:
            return
        
        # Prepare payload
        payload = {
            "id": event.id,
            "type": event.type,
            "data": event.data,
            "occurred_at": event.occurred_at.isoformat()
        }
        
        # Generate signature
        headers = {
            "Content-Type": "application/json",
            "X-Webhook-Id": webhook_id,
            "X-Webhook-Timestamp": str(int(datetime.utcnow().timestamp()))
        }
        
        if webhook["secret"]:
            signature = self._generate_signature(
                payload,
                webhook["secret"],
                headers["X-Webhook-Timestamp"]
            )
            headers["X-Webhook-Signature"] = signature
        
        # Send with retries
        try:
            await self._send_with_retry(
                webhook["url"],
                payload,
                headers
            )
            
            # Record successful delivery
            await self._record_delivery(
                webhook_id,
                event.id,
                "success"
            )
            
        except Exception as e:
            # Record failed delivery
            await self._record_delivery(
                webhook_id,
                event.id,
                "failed",
                str(e)
            )
            
            # Schedule retry
            await self._schedule_retry(webhook_id, event)
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=60)
    )
    async def _send_with_retry(
        self,
        url: str,
        payload: dict,
        headers: dict
    ):
        """Send HTTP request with retries"""
        response = await self.http_client.post(
            url,
            json=payload,
            headers=headers
        )
        
        # Check for success
        if response.status_code >= 400:
            raise WebhookDeliveryError(
                f"Webhook delivery failed: {response.status_code}"
            )
    
    def _generate_signature(
        self,
        payload: dict,
        secret: str,
        timestamp: str
    ) -> str:
        """Generate webhook signature"""
        message = f"{timestamp}.{json.dumps(payload, sort_keys=True)}"
        signature = hmac.new(
            secret.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()
        return f"v1={signature}"
    
    async def verify_webhook_signature(
        self,
        payload: str,
        signature: str,
        timestamp: str,
        secret: str
    ) -> bool:
        """Verify webhook signature"""
        expected_signature = self._generate_signature(
            json.loads(payload),
            secret,
            timestamp
        )
        return hmac.compare_digest(signature, expected_signature)

# Webhook event types
class WebhookEventType(Enum):
    ORDER_CREATED = "order.created"
    ORDER_SHIPPED = "order.shipped"
    PAYMENT_COMPLETED = "payment.completed"
    USER_REGISTERED = "user.registered"

# Webhook delivery queue
class WebhookQueue:
    """Queue webhook deliveries"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
        self.queue_key = "webhook_queue"
    
    async def enqueue(
        self,
        webhook_id: str,
        event: WebhookEvent
    ):
        """Add webhook to delivery queue"""
        payload = {
            "webhook_id": webhook_id,
            "event": event.__dict__,
            "enqueued_at": datetime.utcnow().isoformat()
        }
        
        await self.redis.lpush(
            self.queue_key,
            json.dumps(payload)
        )
    
    async def process_queue(
        self,
        delivery_service: WebhookDeliveryService,
        batch_size: int = 10
    ):
        """Process webhook queue"""
        while True:
            # Get batch
            batch = []
            for _ in range(batch_size):
                item = await self.redis.rpop(self.queue_key)
                if not item:
                    break
                batch.append(json.loads(item))
            
            if not batch:
                await asyncio.sleep(1)
                continue
            
            # Process batch concurrently
            tasks = []
            for item in batch:
                event_data = item["event"]
                event = WebhookEvent(**event_data)
                
                task = delivery_service.send_webhook(
                    item["webhook_id"],
                    event
                )
                tasks.append(task)
            
            await asyncio.gather(*tasks, return_exceptions=True)
```

## 🚄 Real-time Updates

### WebSocket Implementation

```python
# WebSocket server with rooms
from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, Set
import asyncio

class ConnectionManager:
    """WebSocket connection manager"""
    
    def __init__(self):
        # Active connections by client ID
        self.active_connections: Dict[str, WebSocket] = {}
        # Room memberships
        self.rooms: Dict[str, Set[str]] = defaultdict(set)
        # Client to rooms mapping
        self.client_rooms: Dict[str, Set[str]] = defaultdict(set)
    
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept WebSocket connection"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
    
    def disconnect(self, client_id: str):
        """Handle disconnection"""
        # Remove from all rooms
        for room in self.client_rooms.get(client_id, set()):
            self.rooms[room].discard(client_id)
        
        # Remove client data
        self.active_connections.pop(client_id, None)
        self.client_rooms.pop(client_id, None)
    
    async def join_room(self, client_id: str, room: str):
        """Join client to room"""
        self.rooms[room].add(client_id)
        self.client_rooms[client_id].add(room)
        
        # Notify room members
        await self.send_to_room(
            room,
            {
                "type": "user_joined",
                "user_id": client_id,
                "room": room
            },
            exclude=[client_id]
        )
    
    async def leave_room(self, client_id: str, room: str):
        """Remove client from room"""
        self.rooms[room].discard(client_id)
        self.client_rooms[client_id].discard(room)
        
        # Notify room members
        await self.send_to_room(
            room,
            {
                "type": "user_left",
                "user_id": client_id,
                "room": room
            }
        )
    
    async def send_personal_message(self, message: dict, client_id: str):
        """Send message to specific client"""
        websocket = self.active_connections.get(client_id)
        if websocket:
            await websocket.send_json(message)
    
    async def send_to_room(
        self,
        room: str,
        message: dict,
        exclude: List[str] = None
    ):
        """Send message to all clients in room"""
        exclude = exclude or []
        
        # Get room members
        members = self.rooms.get(room, set())
        
        # Send to each member
        tasks = []
        for client_id in members:
            if client_id not in exclude:
                websocket = self.active_connections.get(client_id)
                if websocket:
                    task = websocket.send_json(message)
                    tasks.append(task)
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
    
    async def broadcast(self, message: dict):
        """Broadcast to all connected clients"""
        tasks = []
        for websocket in self.active_connections.values():
            task = websocket.send_json(message)
            tasks.append(task)
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)

# WebSocket endpoint
manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    client_id: str
):
    await manager.connect(websocket, client_id)
    
    try:
        while True:
            # Receive message
            data = await websocket.receive_json()
            
            # Handle different message types
            if data["type"] == "join_room":
                await manager.join_room(client_id, data["room"])
                
            elif data["type"] == "leave_room":
                await manager.leave_room(client_id, data["room"])
                
            elif data["type"] == "room_message":
                await manager.send_to_room(
                    data["room"],
                    {
                        "type": "message",
                        "from": client_id,
                        "content": data["content"],
                        "timestamp": datetime.utcnow().isoformat()
                    }
                )
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)

# Server-Sent Events (SSE)
from fastapi.responses import StreamingResponse

class SSEManager:
    """Server-Sent Events manager"""
    
    def __init__(self):
        self.clients: Dict[str, asyncio.Queue] = {}
    
    async def subscribe(self, client_id: str) -> asyncio.Queue:
        """Subscribe client to events"""
        queue = asyncio.Queue()
        self.clients[client_id] = queue
        return queue
    
    def unsubscribe(self, client_id: str):
        """Unsubscribe client"""
        self.clients.pop(client_id, None)
    
    async def publish(self, event: dict, client_id: Optional[str] = None):
        """Publish event to clients"""
        message = f"data: {json.dumps(event)}\n\n"
        
        if client_id:
            # Send to specific client
            queue = self.clients.get(client_id)
            if queue:
                await queue.put(message)
        else:
            # Broadcast to all
            for queue in self.clients.values():
                await queue.put(message)

sse_manager = SSEManager()

@app.get("/events/stream")
async def event_stream(client_id: str):
    """SSE endpoint"""
    async def generate():
        queue = await sse_manager.subscribe(client_id)
        
        try:
            while True:
                message = await queue.get()
                yield message
        except asyncio.CancelledError:
            sse_manager.unsubscribe(client_id)
    
    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"  # Disable Nginx buffering
        }
    )
```

## 🚀 Best Practices

### 1. **Message Design**
- Use schema versioning for message formats
- Include correlation IDs for tracking
- Keep messages small and focused
- Use appropriate serialization (JSON, Protobuf)
- Include metadata (timestamps, source, etc.)

### 2. **Queue Management**
- Implement proper error handling and DLQ
- Use message deduplication where needed
- Set appropriate TTLs for messages
- Monitor queue depth and latency
- Implement backpressure mechanisms

### 3. **Event Sourcing**
- Keep events immutable
- Use meaningful event names
- Version your events
- Implement snapshots for performance
- Consider event compaction strategies

### 4. **CQRS Implementation**
- Keep commands and queries separate
- Use appropriate storage for each side
- Implement eventual consistency handling
- Monitor synchronization lag
- Provide clear APIs for both sides

### 5. **Webhook Security**
- Always use HTTPS endpoints
- Implement request signing
- Validate webhook payloads
- Implement idempotency
- Rate limit webhook deliveries

### 6. **Real-time Communication**
- Use heartbeats for connection health
- Implement reconnection logic
- Handle backpressure appropriately
- Secure WebSocket connections
- Monitor connection counts

## 📖 Resources & References

### Message Queue Systems
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Redis Pub/Sub](https://redis.io/topics/pubsub)
- [AWS SQS](https://docs.aws.amazon.com/sqs/)

### Patterns & Architecture
- "Enterprise Integration Patterns" by Hohpe & Woolf
- [Event Sourcing by Martin Fowler](https://martinfowler.com/eaaDev/EventSourcing.html)
- [CQRS Journey](https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj554200(v=pandp.10))
- [Microservices.io Messaging Patterns](https://microservices.io/patterns/communication-style/messaging.html)

### Libraries & Tools
- **Python** - aio-pika, celery, kombu, aiokafka
- **Node.js** - amqplib, bull, bee-queue
- **Monitoring** - RabbitMQ Management, Kafka Manager
- **Testing** - LocalStack, TestContainers

---

*This guide covers essential messaging patterns for building scalable, event-driven architectures. Choose patterns based on your specific requirements for consistency, performance, and complexity.*
All code generated must follow these FP principles, regardless of language. Even in impure or imperative languages (Python, C, Rust, Lua), simulate FP idioms using pure functions, effect wrappers, and separation of concerns.

---

## Core Guidelines

### 0. No Global State

Never use global variables or mutable shared state. Pass dependencies explicitly through parameters or injection. Use actors, message passing, or dependency injection patterns to manage state.

**Python**
```python
# Good - dependency injected
class UserService:
    def __init__(self, database: Database):
        self.database = database

# Bad - global state
DATABASE: Database | None = None
def get_user(id: int) -> User:
    return DATABASE.query(id)
```

**Rust**
```rust
// Good - passed as parameter
fn process(settings: &AppSettings) {
    // use settings
}

// Bad - global static
static SETTINGS: OnceLock<AppSettings> = OnceLock::new();
fn process() {
    let settings = SETTINGS.get().unwrap();
}
```

**TypeScript**
```typescript
// Good - dependency injected
class SettingsStore {
    constructor(private deps: { getSettings: () => Settings }) {}
}

// Bad - global variable
const GLOBAL_SETTINGS = new Map();
function getSetting(key: string) {
    return GLOBAL_SETTINGS.get(key);
}
```

**Actor Pattern (preferred for stateful components):**
```rust
// Good - actor holds state, receives messages
struct SettingsActor {
    settings: AppSettings,
}

impl SettingsActor {
    fn handle(&mut self, msg: SettingsCommand) {
        // update state based on message
    }
}
```

---

### 1. Pure Functions Only

All functions depend only on their input, never mutate shared state, never perform I/O.

**Python**

```python
from typing import Any

# Good
def add(a: int, b: int) -> int:
    return a + b

# Bad - hidden dependency
total: int = 0
def add_to_total(x: int) -> None:
    global total  # type: ignore
    total += x
```

**C**

```c
int add(int a, int b) {
    return a + b;
}
```

**Rust**

```rust
fn multiply(a: i32, b: i32) -> i32 {
    a * b
}
```

**Lua**

```lua
local function multiply(a, b)
  return a * b
end
```

---

### 2. Isolate Side Effects

I/O, randomness, DB access, and system calls must be in a separate layer, not mixed with logic.

**Python**

```python
from decimal import Decimal

# Good - pure logic
def format_price(price: Decimal) -> str:
    return f"${price:.2f}"

# Bad - mixed concerns
def get_and_format_price(item_id: int) -> str:
    price: Decimal = db.query(item_id)  # type: ignore[name-defined]
    return format_price(price)
```

**C**

```c
// Caller manages memory - no internal static state
void greet(const char* name, char* buffer, size_t size) {
    snprintf(buffer, size, "Hello, %s", name);
}
```

**Rust**

```rust
fn greet(name: &str) -> String {
    format!("Hello, {}", name)
}

fn main() {
    let name = std::env::args().nth(1).unwrap();
    println!("{}", greet(&name));
}
```

**Lua**

```lua
local function greet(user)
  return "Hi, " .. user.name
end

-- I/O happens at the boundary
local user = { name = "Alice" }
print(greet(user))
```

---

### 3. Functional Core, Imperative Shell

Write business logic as pure functions. Only outer layers perform effects.

**Python**

```python
from decimal import Decimal
from typing import Iterable

# Core (pure)
def compute_discount(price: Decimal, rate: float) -> Decimal:
    return price * Decimal(1 - rate)

# Shell (effects)
Item = dict[str, Any]

def fetch_items() -> Iterable[Item]:
    ...

def save_total(total: Decimal) -> None:
    ...

items: list[Item] = list(fetch_items())
subtotal: Decimal = sum(Decimal(item["price"]) for item in items)
total: Decimal = compute_discount(subtotal, 0.1)
save_total(total)
```

**C**

```c
float compute_total(float* prices, int n) {
    float sum = 0;
    for (int i = 0; i < n; i++) {
        sum += prices[i] * 0.9;
    }
    return sum;
}
```

**Rust**

```rust
fn compute_total(prices: &[f64]) -> f64 {
    prices.iter().map(|p| p * 0.9).sum()
}
```

**Lua**

```lua
local function compute_total(items)
  local sum = 0
  for _, item in ipairs(items) do
    sum = sum + (item.price * 0.9)
  end
  return sum
end
```

---

### 4. Monadic Error Handling

Use `Result`/`Option` to handle failure/optionality. Avoid exceptions for control flow.

**Python**

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E", bound=str)

@dataclass
class Ok(Generic[T]):
    value: T

@dataclass
class Err(Generic[E]):
    error: E

Result = Ok[T] | Err[E]

def fetch_user(id: int) -> Result[dict[str, Any], str]:
    try:
        user: dict[str, Any] = db.get(id)  # type: ignore[attr-defined,name-defined]
        return Ok(user)
    except Exception as e:
        return Err(str(e))

# Usage
match fetch_user(123):
    case Ok(u): print(f"Found: {u['name']}")
    case Err(e): print(f"Error: {e}")
```

**C**

```c
// Simulate Result with Tagged Union
typedef struct {
    bool is_ok;
    union {
        int value;
        const char* error;
    };
} ResultInt;

ResultInt ok(int v) { return (ResultInt){ .is_ok = true, .value = v }; }
ResultInt err(const char* e) { return (ResultInt){ .is_ok = false, .error = e }; }
```

**Rust**

```rust
fn get_user(id: i32) -> Result<User, String> {
    db::fetch_user(id).ok_or("User not found".to_string())
}
```

**Lua**

```lua
-- Lua idiomatic: return explicit table or error pair
local function get_user(id)
  local user = db.fetch_user(id)
  if user then
    return { ok = user }
  else
    return { err = "User not found" }
  end
end
```

---

### 5. Composable Concurrency

Use `async`/`Task`/`Future` wrappers. Avoid raw threading.

**Python**

```python
from typing import Iterable

async def process_batch(user_ids: Iterable[int]) -> list[int]:
    users: list[dict[str, Any]] = [await fetch_user(uid) for uid in user_ids]
    return [compute_score(u) for u in users]
```

**C**

```c
// Use callbacks or function pointers for async-style modeling
```

**Rust**

```rust
async fn process_user(id: u32) -> Result<(), Error> {
    let user = fetch_user(id).await?;
    let score = compute_score(&user);
    save_score(score).await
}
```

**Lua**

```lua
-- Lua uses coroutines for cooperative concurrency
local function fetch_user(id)
    -- Simulated async I/O
    local co = coroutine.create(function()
        -- In real code, this would be non-blocking I/O
        coroutine.yield()
    end)
    return function()
        local ok, user = coroutine.resume(co)
        if ok then
            return { id = id, name = "User" .. tostring(id) }
        end
        return nil
    end
end

local function compute_score(user)
    return user.id * 10
end

-- Process batch using coroutines
local function process_batch(user_ids)
    local results = {}
    for _, id in ipairs(user_ids) do
        local fetch = fetch_user(id)
        local user = fetch()
        if user then
            table.insert(results, compute_score(user))
        end
    end
    return results
end

-- Usage
local scores = process_batch({1, 2, 3, 4, 5})
for _, score in ipairs(scores) do
    print("Score:", score)
end
```

---

### 6. Actor Model

Encapsulate mutable state and message processing. No shared state between actors.

**Python**

```python
import asyncio
from __future__ import annotations
from abc import abstractmethod
from asyncio import Task
from dataclasses import dataclass
from typing import Generic, TypeVar, Any

MessageT = TypeVar("MessageT")

class ActorBase(Generic[MessageT]):
    def __init__(self) -> None:
        self._mailbox: list[MessageT] = []
        self._task: Task[None] | None = None

    def send(self, msg: MessageT) -> None:
        self._mailbox.append(msg)

    def start(self) -> None:
        self._task = asyncio.create_task(self._run())

    def stop(self) -> None:
        if self._task:
            self._task.cancel()
            self._task = None

    async def _run(self) -> None:
        while self._mailbox:
            msg: MessageT = self._mailbox.pop(0)
            self.handle(msg)

    @abstractmethod
    def handle(self, msg: MessageT) -> None:
        raise NotImplementedError

@dataclass
class Increment:
    amount: int = 1

@dataclass
class Decrement:
    amount: int = 1

Message = Increment | Decrement

class Counter(ActorBase[Message]):
    def __init__(self) -> None:
        super().__init__()
        self._state: int = 0

    def handle(self, msg: Message) -> None:
        match msg:
            case Increment(a): self._state += a
            case Decrement(a): self._state -= a

# Usage
async def main() -> None:
    counter: Counter = Counter()
    counter.start()
    counter.send(Increment(5))
    await asyncio.sleep(0)
    print(counter._state)  # 5
    counter.stop()

if __name__ == "__main__":
    asyncio.run(main())
```

**TypeScript**

```typescript
abstract class Actor<Msg> {
  protected mailbox: Msg[] = [];
  private running = false;

  abstract handle(msg: Msg): void;

  send(msg: Msg): void {
    this.mailbox.push(msg);
  }

  start(): void {
    if (!this.running) {
      this.running = true;
      this._run();
    }
  }

  stop(): void {
    this.running = false;
  }

  private _run(): void {
    while (this.running && this.mailbox.length > 0) {
      const msg = this.mailbox.shift()!;
      this.handle(msg);
    }
  }
}

// Concrete Counter Actor
type Increment = { type: "increment"; amount: number };
type Decrement = { type: "decrement"; amount: number };

class Counter extends Actor<Increment | Decrement> {
  private state: number = 0;

  handle(msg: Increment | Decrement): void {
    switch (msg.type) {
      case "increment":
        this.state += msg.amount;
        break;
      case "decrement":
        this.state -= msg.amount;
        break;
    }
  }
}

// Usage
const counter = new Counter();
counter.start();
counter.send({ type: "increment", amount: 5 });
console.log(counter.state);
counter.stop();
```

**Rust**

```rust
use std::collections::VecDeque;
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

trait Actor<Message> {
    fn handle(&mut self, msg: Message);
    fn start(&mut self);
    fn stop(&mut self);
}

struct Counter {
    state: i32,
    receiver: mpsc::Receiver<CounterMsg>,
    running: bool,
}

enum CounterMsg {
    Increment(i32),
    Decrement(i32),
}

impl Actor<CounterMsg> for Counter {
    fn handle(&mut self, msg: CounterMsg) {
        match msg {
            CounterMsg::Increment(amount) => self.state += amount,
            CounterMsg::Decrement(amount) => self.state -= amount,
        }
    }

    fn start(&mut self) {
        self.running = true;
        while self.running {
            if let Ok(msg) = self.receiver.recv_timeout(Duration::from_millis(10)) {
                self.handle(msg);
            }
        }
    }

    fn stop(&mut self) {
        self.running = false;
    }
}

fn main() {
    let (sender, receiver) = mpsc::channel();
    let mut counter = Counter { state: 0, receiver, running: false };

    let handle = thread::spawn(move || {
        counter.start();
    });

    sender.send(CounterMsg::Increment(5)).unwrap();
    thread::sleep(Duration::from_millis(50));
    sender.send(CounterMsg::Decrement(2)).unwrap();
    thread::sleep(Duration::from_millis(50));

    counter.stop();
    handle.join().unwrap();

    println!("Counter state: {}", counter.state);
}
```

**Lua**

```lua
local Actor = {}
Actor.__index = Actor

function Actor.new()
  local self = setmetatable({}, Actor)
  self._mailbox = {}
  self._running = false
  return self
end

function Actor:handle(msg)
  error("subclasses must implement handle(msg)")
end

function Actor:send(msg)
  table.insert(self._mailbox, msg)
end

function Actor:start()
  if not self._running then
    self._running = true
    self:_run()
  end
end

function Actor:stop()
  self._running = false
end

function Actor:_run()
  while self._running and #self._mailbox > 0 do
    local msg = table.remove(self._mailbox, 1)
    self:handle(msg)
  end
end

-- Concrete Counter Actor
local Counter = setmetatable({}, { __index = Actor })
Counter.__index = Counter

function Counter.new()
  local self = Actor.new()
  self._state = 0
  setmetatable(self, Counter)
  return self
end

function Counter:handle(msg)
  if msg.type == "increment" then
    self._state = self._state + (msg.amount or 1)
  elseif msg.type == "decrement" then
    self._state = self._state - (msg.amount or 1)
  end
end

-- Usage
local counter = Counter.new()
counter:start()
counter:send({ type = "increment", amount = 5 })
print(counter._state)
counter:stop()
```

---

## Quick Reference

**Do:**

- Write pure, deterministic functions
- Model effects explicitly (`Result`, `Option`)
- Keep side effects at boundaries
- Encapsulate concurrency with actors/wrappers

**Don't:**

- Share mutable state between components
- Mix I/O with computation
- Use `isinstance` — use pattern matching
- Use exceptions for control flow

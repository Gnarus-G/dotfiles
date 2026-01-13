All code generated must follow these FP principles, regardless of the language. Even in impure or imperative languages (like Python or C), simulate FP idioms using pure functions, effect wrappers, and separation of concerns.

---

## 📓 Core Guidelines

### 1. ✅ Pure Functions Only

All functions must:

- Depend only on their input
- Not mutate shared state
- Not perform I/O or system calls

#### Examples:

**Python**

```python
def calculate_discount(price, rate):
    return price * (1 - rate)
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

### 2. 🚫 Isolate Side Effects

All I/O, randomness, DB access, system calls, etc. must be **moved to a separate layer** or **wrapped**.

#### Examples:

**Python**

```python
def greet(user):
    return f"Hi, {user['name']}"

user = json.load(open('user.json'))
print(greet(user))
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

### 3. 🧱 Functional Core, Imperative Shell

Write business logic as a **pure functional core**. Only outer layers may perform effects.

#### Examples:

**Python**

```python
def compute_total(items):
    return sum(i['price'] * 0.9 for i in items)

items = get_items_from_api()
print(compute_total(items))
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

### 4. 🌀 Use Monads or Monadic Equivalents for Effects and Errors

Use `Option`, `Result`, or simulate `Maybe`, `Try`, etc., to handle failure/optionality. Prefer `map` and `and_then` for chaining.

#### Examples:

**Python**

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar('T')
E = TypeVar('E')

# Result as Algebraic Data Type (ADT)
@dataclass
class Result(Generic[T, E]):
    """Base Result type - never instantiate directly"""
    pass

@dataclass
class Ok(Result[T, E]):
    value: T

@dataclass
class Err(Result[T, E]):
    error: E

# Usage with pattern matching (Python 3.10+)
def get_user(uid) -> Result[dict, str]:
    try:
        return Ok(fetch_user(uid))
    except Exception as e:
        return Err(str(e))

def render_user(user):
    match user:
        case Ok(value): return f"Success: {value}"
        case Err(error): return f"Error: {error}"
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
-- Lua idiomatic: return explicit table or value, error pair
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

### 5. 🗬️ Concurrency Must Be Composable

Use pure wrappers like `async`, `Task`, `Future`, or abstracted control flow to model concurrency. Avoid raw threading APIs unless abstracted.

#### Examples:

**Python**

```python
async def process(user_id):
    user = await fetch_user(user_id)
    return compute_result(user)
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

---

### 6. 🎭 Actor Model

Actors encapsulate **mutable state** and **message processing** in a controlled manner. They solve concurrency by ensuring:

- No shared state between actors
- Messages are processed sequentially
- State mutation only happens in response to messages

#### Python: Generic Actor

```python
from __future__ import annotations
from asyncio import Task, create_task
from dataclasses import dataclass
from typing import Generic, TypeVar, Any

MessageT = TypeVar("MessageT")

class Actor(Generic[MessageT]):
    def __init__(self) -> None:
        self._mailbox: list[MessageT] = []
        self._task: Task[Any] | None = None

    def send(self, msg: MessageT) -> None:
        self._mailbox.append(msg)

    def start(self) -> None:
        self._task = create_task(self._run())

    def stop(self) -> None:
        if self._task:
            self._task.cancel()
            self._task = None

    async def _run(self) -> None:
        while True:
            msg = self._mailbox.pop(0)
            self.handle(msg)

    def handle(self, msg: MessageT) -> None:
        error("subclasses must implement handle(msg)")

# --- Concrete Counter Actor ---

@dataclass
class Increment:
    amount: int = 1

@dataclass
class Decrement:
    amount: int = 1

class Counter(Actor[Increment | Decrement]):
    _state: int = 0

    def handle(self, msg: Increment | Decrement) -> None:
        match msg:
            case Increment(amount):
                self._state += amount
            case Decrement(amount):
                self._state -= amount

# --- Usage ---

counter = Counter()
counter.start()

counter.send(Increment(5))
counter.send(Decrement(2))
counter.send(Increment(3))

import asyncio
await asyncio.sleep(0)

print(counter._state)  # Output: 6
counter.stop()
```

#### TypeScript: Generic Actor

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

// --- Concrete Counter Actor ---

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

// --- Usage ---

const counter = new Counter();
counter.start();

counter.send({ type: "increment", amount: 5 });
counter.send({ type: "decrement", amount: 2 });
counter.send({ type: "increment", amount: 3 });

console.log(counter.state); // Output: 6
counter.stop();
```

#### Lua: Generic Actor Class

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

-- --- Concrete Counter Actor ---

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

-- --- Usage ---

local counter = Counter.new()
counter:start()

counter:send({ type = "increment", amount = 5 })
counter:send({ type = "decrement", amount = 2 })
counter:send({ type = "increment", amount = 3 })

print(counter._state)  -- Output: 6
counter:stop()
```

---

### 7. 🗄️ Resource Management in Actor Systems

Actors naturally encapsulate resources. Resources are **acquired on first use** and **released when the actor stops**.

#### Core Patterns

1. **Scoped ownership**: Each actor owns its resources exclusively
2. **Lazy acquisition**: Open files, connections, or handles only when needed
3. **Deterministic cleanup**: Resources released in `stop()`

#### Python: File-Handling Actor

```python
from __future__ import annotations
from abc import ABC, abstractmethod
from asyncio import Task, create_task
from dataclasses import dataclass
from typing import Generic, TypeVar, IO
import asyncio

MessageT = TypeVar("MessageT")

class Actor(ABC, Generic[MessageT]):
    def __init__(self) -> None:
        self._mailbox: list[MessageT] = []
        self._task: Task[None] | None = None

    def send(self, msg: MessageT) -> None:
        self._mailbox.append(msg)

    def start(self) -> None:
        self._task = create_task(self._run())

    def stop(self) -> None:
        self._cleanup()
        if self._task:
            self._task.cancel()
            self._task = None

    async def _run(self) -> None:
        while True:
            msg = self._mailbox.pop(0)
            await self.handle(msg)

    @abstractmethod
    async def handle(self, msg: MessageT) -> None:
        ...

    def _cleanup(self) -> None:
        """Override in subclasses to release resources."""
        pass

# --- Concrete File Writer Actor ---

@dataclass
class WriteLine:
    line: str

class FileWriter(Actor[WriteLine]):
    def __init__(self, path: str) -> None:
        super().__init__()
        self._path = path
        self._handle: IO[str] | None = None

    async def handle(self, msg: WriteLine) -> None:
        if self._handle is None:
            self._handle = open(self._path, "a")
        self._handle.write(msg.line + "\n")

    def _cleanup(self) -> None:
        if self._handle:
            self._handle.close()
            self._handle = None

# --- Usage ---

async def main() -> None:
    writer = FileWriter("/tmp/log.txt")
    writer.start()

    writer.send(WriteLine("first line"))
    writer.send(WriteLine("second line"))

    await asyncio.sleep(0.1)  # Let writes complete
    writer.stop()

asyncio.run(main())
```

#### TypeScript: Resource Actor

```typescript
abstract class Actor<Msg> {
  protected mailbox: Msg[] = [];
  private task: ReturnType<typeof setInterval> | null = null;
  private running = false;

  abstract handle(msg: Msg): void;
  abstract cleanup(): void;

  send(msg: Msg): void {
    this.mailbox.push(msg);
  }

  start(): void {
    if (!this.running) {
      this.running = true;
      this.task = setInterval(() => this._run(), 0);
    }
  }

  stop(): void {
    this.running = false;
    if (this.task) {
      clearInterval(this.task);
      this.task = null;
    }
    this.cleanup();
  }

  private _run(): void {
    while (this.mailbox.length > 0) {
      const msg = this.mailbox.shift()!;
      this.handle(msg);
    }
  }
}

// --- Concrete File Actor ---

type WriteRequest = { type: "write"; content: string };
type CloseRequest = { type: "close" };
type FileMsg = WriteRequest | CloseRequest;

class FileActor extends Actor<FileMsg> {
  private handle: FileSystemFileHandle | null = null;
  private file: FileSystemWritableFileStream | null = null;
  private path: string;

  constructor(path: string) {
    super();
    this.path = path;
  }

  async handle(msg: FileMsg): Promise<void> {
    switch (msg.type) {
      case "write":
        if (!this.file) {
          this.handle = await navigator.storage.getFileHandle(this.path, {
            create: true,
          });
          this.file = await this.handle.createWritable();
        }
        await this.file.write(msg.content);
        break;
      case "close":
        if (this.file) {
          await this.file.close();
          this.file = null;
        }
        break;
    }
  }

  cleanup(): void {
    this.file?.close();
    this.file = null;
  }
}

// --- Usage ---

const actor = new FileActor("notes.txt");
actor.start();

actor.send({ type: "write", content: "hello" });
actor.send({ type: "write", content: "world" });

setTimeout(() => {
  actor.send({ type: "close" });
  actor.stop();
}, 100);
```

#### Lua: Resource Actor

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
    -- In a real implementation, run in a coroutine
    self:_run()
  end
end

function Actor:stop()
  self._running = false
  self:_cleanup()
end

function Actor:_run()
  while self._running and #self._mailbox > 0 do
    local msg = table.remove(self._mailbox, 1)
    self:handle(msg)
  end
end

function Actor:_cleanup()
  -- Override in subclasses
end

-- --- Concrete File Actor ---

local FileActor = setmetatable({}, { __index = Actor })
FileActor.__index = FileActor

function FileActor.new(path)
  local self = Actor.new()
  self._path = path
  self._handle = nil
  setmetatable(self, FileActor)
  return self
end

function FileActor:handle(msg)
  if msg.type == "write" then
    if not self._handle then
      self._handle = io.open(self._path, "a")
    end
    self._handle:write(msg.content)
    self._handle:write("\n")
  elseif msg.type == "close" then
    self:_cleanup()
  end
end

function FileActor:_cleanup()
  if self._handle then
    self._handle:close()
    self._handle = nil
  end
end

-- --- Usage ---

local actor = FileActor.new("/tmp/data.txt")
actor:start()

actor:send({ type = "write", content = "first" })
actor:send({ type = "write", content = "second" })

actor:send({ type = "close" })
actor:stop()
```

---

### ⚠️ Avoid:

- Shared mutable state
- Mixing I/O with computation
- Control flow without pattern matching
- `isinstance` checks — use pattern matching instead
- Implicit null/error handling
- Framework-specific side-effect helpers unless explicitly wrapped

---

## 📌 Summary

All generated code must:

- Be built from **pure, deterministic functions**
- Model effects explicitly using `Result`, `Option`, or effect descriptions
- Keep side effects at the **boundaries** (I/O, DB, network)
- Encapsulate concurrency with **effect wrappers** or **actors**
- Use a **custom actor trait** in Rust — never external actor frameworks

--

# Advanced Examples

## Python program

Of course. This is an excellent way to frame the information. Here are the functional programming guidelines structured as a "Don't / Do" guide, using the evolution of our script as the primary example. This is designed to be a clear directive for an LLM on how to produce high-quality, functional code.

---

### Guidelines for Producing High-Quality, Functional Python Code

The goal is to write code that is robust, testable, and maintainable. This is achieved by separating logic from actions and making data flow explicit.

---

### 1. Separating Logic from Actions (Side Effects)

#### **Don't: Mix logic and side effects in one function.**

A single function should not be responsible for fetching data, transforming it, and then printing it. This creates a monolithic block that is impossible to test and difficult to reuse.

```python
# DON'T DO THIS
def get_and_print_user_summary(user_id: str):
    # Side Effect: Network I/O
    response = requests.post("https://api.example.com/info", json={"user": user_id})
    if response.status_code != 200:
        # Side Effect: Console I/O
        print("Error fetching data")
        return

    # Logic: Data Transformation
    raw_data = response.json()
    name = raw_data['name'].upper()
    is_active = "Active" if raw_data['status'] == 1 else "Inactive"

    # Side Effect: Console I/O
    print(f"User Summary for {user_id}:")
    print(f"  Name: {name}")
    print(f"  Status: {is_active}")
```

#### **Do: Separate pure logic into a "Functional Core" and side effects into an "Imperative Shell."**

The core logic should only consist of pure functions that transform data. The shell handles all interaction with the outside world (network, console, etc.).

```python
# DO THIS INSTEAD

# --- Functional Core (Pure, Testable Logic) ---
def process_user_data(raw_data: dict) -> dict:
    return {
        "name": raw_data['name'].upper(),
        "status": "Active" if raw_data['status'] == 1 else "Inactive"
    }

# --- Imperative Shell (Handles Side Effects) ---
def fetch_user_data(user_id: str) -> dict:
    response = requests.post("https://api.example.com/info", json={"user": user_id})
    response.raise_for_status()
    return response.json()

def display_summary(user_id: str, summary: dict):
    print(f"User Summary for {user_id}:")
    print(f"  Name: {summary['name']}")
    print(f"  Status: {summary['status']}")

# The shell orchestrates the pure functions
def main_workflow(user_id: str):
    raw_data = fetch_user_data(user_id)
    summary_data = process_user_data(raw_data)
    display_summary(user_id, summary_data)
```

---

### 2. Handling Errors as Data

#### **Don't: Use exceptions for control flow.**

`try...except` blocks are themselves a form of side effect that breaks the linear flow of data. Overusing them for recoverable errors makes code harder to follow and compose.

```python
# DON'T DO THIS
def run_pipeline(user_id: str):
    try:
        raw_data = fetch_user_data(user_id)
        summary_data = process_user_data(raw_data)
        display_summary(user_id, summary_data)
    except Exception as e:
        print(f"An error occurred: {e}")
```

#### **Do: Use a `Result` monad to treat errors as explicit return values.**

This creates a "railway" where operations are chained together. The pipeline continues as long as things are successful and gracefully handles the first failure without crashing.

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar('T')
E = TypeVar('E')

# Nominal Result type with Ok/Err variants
@dataclass
class Result(Generic[T, E]):
    """Base Result type - never instantiate directly"""
    pass

@dataclass
class Ok(Result[T, E]):
    value: T

@dataclass
class Err(Result[T, E]):
    error: E

def fetch_user_data(user_id: str) -> Result[dict, Exception]:
    try:
        return Ok(requests.post("...", json={"user": user_id}).json())
    except Exception as e:
        return Err(e)

def process_user_data(raw_data: dict) -> Result[dict, str]:
    return Ok({
        "name": raw_data['name'].upper(),
        "status": "Active" if raw_data['status'] == 1 else "Inactive"
    })

def display_summary(user_id: str, summary: dict):
    print(f"User Summary for {user_id}:")
    print(f"  Name: {summary['name']}")
    print(f"  Status: {summary['status']}")

# Usage with pattern matching
def main_workflow(user_id: str):
    match fetch_user_data(user_id):
        case Ok(user_data):
            match process_user_data(user_data):
                case Ok(summary):
                    display_summary(user_id, summary)
                case Err(e):
                    print(f"Processing error: {e}")
        case Err(e):
            print(f"Fetch error: {e}")
```

---

### 3. Using Types for Clarity

#### **Don't: Pass generic dictionaries between functions.**

Signatures like `def process(data: dict) -> dict:` are not self-documenting. To understand the data structure, one must read the entire function implementation.

```python
# DON'T DO THIS
def process_data(raw_data: dict) -> dict:
    # What keys are in raw_data? What does the output dict contain?
    # No one knows without reading the code.
    return {"processed_name": raw_data["name"].upper()}
```

#### **Do: Use custom types (`dataclasses`) to define explicit data contracts.**

This makes function signatures self-documenting and enables static analysis tools to catch errors before runtime.

```python
# DO THIS INSTEAD
from dataclasses import dataclass

@dataclass
class RawUserData:
    name: str
    status: int

@dataclass
class ProcessedSummary:
    name: str
    status: str

def process_data(raw_data: RawUserData) -> ProcessedSummary:
    # The data contract is perfectly clear from the signature alone.
    return ProcessedSummary(
        name=raw_data.name.upper(),
        status="Active" if raw_data.status == 1 else "Inactive"
    )
```

---

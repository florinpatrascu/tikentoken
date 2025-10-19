# Tikentoken

Tikentoken is an Elixir library and CLI tool designed for experimentation and learning by tokenizing text with various Ollama models (supporting multiple modes for different tasks). It offers real tokenization when Ollama is available and falls back to a mock tokenizer when Ollama is not running.

## Features

- Tokenize text into IDs using various Ollama models
- Automatic fallback to mock tokenization when Ollama is unavailable
- Compute embeddings using various embedding models
- CLI interface for easy use
- Standalone escript executable

## Installation

### Option 1: Install from Hex (recommended)

Add `tikentoken` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tikentoken, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

### Option 2: Local Development

1. Ensure you have Elixir installed (version ~> 1.18)
2. Clone or download this repository
3. Install dependencies:

   ```bash
   mix deps.get
   ```

## Compilation

Compile the project:

```bash
mix compile
```

To build the standalone executable:

```bash
mix escript.build
```

This creates a `tikentoken` executable in the project root.

## Usage

### CLI

#### Tokenization

Tokenize text using any supported Ollama model (default: embeddinggemma):

```bash
echo "Hello world" | ./tikentoken
```

Or specify a different model:

```bash
./tikentoken --model bge-large "Hello world"
```

Output:
```
Tokens: 5 5
```

(Note: With Ollama running, you'll get actual model token IDs. Without Ollama, it falls back to mock IDs based on word lengths.)

#### Embedding

Compute embeddings using BGE-Large. Embeddings are numerical representations of text that capture semantic meaning. Each text input is converted into a list of numbers (a vector) that can be used for similarity comparison, search, or machine learning. BGE-Large provides superior semantic matching with up to 1024 dimensions - or more, if the model used allows it.

```bash
echo "Hello world" | ./tikentoken --embed --embed_dim 768
```

Output:
```
Embedding (psql vector): [0.123, 0.456, ...]  # 768-dimensional vector
```

Use smaller dimensions (256, 128) for faster processing and less storage, larger dimensions (768, 512) for more semantic detail.

#### Chat

Generate text responses using chat-capable models. This uses Ollama's text generation capabilities:

```bash
tikentoken --chat "Write a haiku about programming"
```

Output:
```
Software, code so clear
Infinite possibilities yet to unlock,
While you, the human, work day and night.
To program with ease, be mine!
```

Or with a specific model:

```bash
tikentoken --model tinyllama --chat "Explain recursion in simple terms"
```

Output:
```
Recursion is a programming technique where a function calls itself to solve a problem...
```

#### Options

- `--model <name>`: Ollama model name (default: `embeddinggemma` for tokenize/embed, `tinyllama` for chat). Supports: `embeddinggemma`, `bge-large`, `gte-large`, `nomic-embed-text`, `tinyllama`, `mistral`, etc.
- `--format <id>`: Token format (currently only `id` supported)
- `--embed`: Compute embedding using the specified model
- `--chat`: Generate chat/text response using the specified model
- `--ollama_url <url>`: Ollama API base URL (default: `http://localhost:11434`)
- `--embed_dim <int>`: Embedding dimension - vector size (varies by model). Higher = more detail but more storage (default: 768)
- `--help`: Show help

### Programmatic Usage

After adding the dependency, you can use Tikentoken in your Elixir code:

```elixir
# Tokenize text (with fallback to mock if Ollama unavailable)
{:ok, tokens} = Tikentoken.tokenize("Hello world")
# tokens: [5, 5] (mock IDs) or [105, 1919] (real Ollama IDs)

# Use a different model
{:ok, tokens} = Tikentoken.tokenize("Hello world", "bge-large")
# tokens: [5, 5] (mock) or actual BGE token IDs

# Compute embeddings (requires Ollama running)
{:ok, embedding} = Tikentoken.compute_embedding("Hello world", 768, "embeddinggemma")
# embedding: [0.123, 0.456, ...] (768-dimensional vector)

# Use BGE-Large for higher dimensional embeddings
{:ok, embedding} = Tikentoken.compute_embedding("Hello world", 1024, "bge-large")
# embedding: [0.123, 0.456, ...] (1024-dimensional vector)

# Chat with AI models (uses tinyllama by default)
{:ok, response} = Tikentoken.chat("Write a short poem about AI")
# response: "In circuits deep, where data streams flow..."

# Chat with custom options
{:ok, response} = Tikentoken.chat("Explain quantum physics", "tinyllama", %{"temperature" => 0.5})
```

## Requirements

- **Ollama**: For real tokenization, embeddings, and chat, install and run Ollama locally. Pull any supported models:
  ```bash
  ollama pull embeddinggemma  # Default for tokenization/embeddings (768 dimensions)
  ollama pull bge-large       # Up to 1024 dimensions for embeddings
  ollama pull tinyllama       # Default for chat (text generation)
  ollama pull mistral         # Alternative chat model
  ollama serve
  ```
- Without Ollama, the tool falls back to mock tokenization for development/testing.

## Testing

Run the test suite:

```bash
mix test
```

The tests work with or without Ollama running:
- **With Ollama**: Tests real tokenization
- **Without Ollama**: Tests fall back to mock tokenization automatically

All tests should pass regardless of Ollama status.

## Development

- Format code: `mix format`
- Run linter: `mix credo` (if installed)
- Generate documentation: `mix docs`

### Interactive Development

For developers who want to experiment and test the tokenizer interactively, start an IEx session with the project loaded:

```bash
iex -S mix
```

Then you can play with the tokenizer in real-time:

```elixir
# Test tokenization with default model
{:ok, tokens} = Tikentoken.tokenize("Hello world")
IO.inspect(tokens)  # See the token IDs

# Try a different model
{:ok, tokens} = Tikentoken.tokenize("Hello world", "bge-large")
IO.inspect(tokens)

# Test embeddings (requires Ollama running)
{:ok, embedding} = Tikentoken.compute_embedding("Hello world", 1024, "bge-large")
IO.inspect(length(embedding))  # Should be 1024

# Test chat (requires Ollama running with tinyllama)
{:ok, response} = Tikentoken.chat("Hello, how are you?")
IO.inspect(response)  # AI response
```

This is useful for understanding how tokenization works, testing edge cases, and developing new features without rebuilding the CLI each time.

## License

This project is licensed under the Affero GPLv3 license

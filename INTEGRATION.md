# Tikentoken Integration Guide

Tikentoken is an Elixir library and CLI tool designed for experimentation and learning by tokenizing text with various Ollama models (supporting multiple modes for different tasks). It offers real tokenization when Ollama is available and falls back to a mock tokenizer when Ollama is not running.


## Installation

### Option 1: Install from Hex (if published)

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

### Option 2: Use Local Path (for development)

If you have the tikentoken project on your local disk, add it as a path dependency:

```elixir
def deps do
  [
    {:tikentoken, path: "/path/to/your/tikentoken"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage

### As a Library

After adding the dependency, you can use Tikentoken in your Elixir code:

```elixir
# Basic tokenization
{:ok, tokens} = Tikentoken.tokenize("Hello world", "embeddinggemma", "id", %{}, "http://localhost:11434")
# tokens: [5, 5] (real IDs if Ollama available, fallback mock IDs otherwise)

# With custom options (add_bos adds Beginning of Sequence token, add_eos adds End of Sequence token)
{:ok, tokens} = Tikentoken.tokenize("Hello world", "embeddinggemma", "id", %{"add_bos" => true, "add_eos" => true}, "http://localhost:11434")

# Compute embeddings
{:ok, embedding} = Tikentoken.compute_embedding("Hello world", 768)
# embedding {:ok,
# [-0.20131716132164001, -0.0010581075912341475, 0.03184797614812851,
#  -0.002743925666436553, 0.007976147346198559, 0.010851329192519188,
#  -0.04191214591264725, 0.03663528338074684, 0.02540280669927597, ...}] (768-dimensional vector)
```

### Error Handling

All functions return: `{:ok, result}` on success, or: `{:error, reason}`, on failure:

```elixir
case Tikentoken.tokenize("Hello world", "embeddinggemma", "id", %{}, "http://localhost:11434") do
  {:ok, tokens} ->
    # Process tokens
    IO.inspect(tokens)

  {:error, reason} ->
    # Handle error (e.g., Ollama not running)
    IO.puts("Tokenization failed: #{reason}")
end
```

### In Phoenix Applications

#### Controller Example

```elixir
defmodule MyAppWeb.TokenizerController do
  use MyAppWeb, :controller

  def tokenize(conn, %{"text" => text}) do
    case Tikentoken.tokenize(text, "embeddinggemma", "id", %{}, "http://localhost:11434") do
      {:ok, tokens} ->
        json(conn, %{tokens: tokens})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
    end
  end

  def embed(conn, %{"text" => text}) do
    case Tikentoken.compute_embedding(text, 768) do
      {:ok, embedding} ->
        json(conn, %{embedding: embedding})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
    end
  end
end
```

#### Routes

```elixir
scope "/api", MyAppWeb do
  post "/tokenize", TokenizerController, :tokenize
  post "/embed", TokenizerController, :embed
end
```

### Configuration

You can configure the default Ollama URL in your `config/config.exs`:

```elixir
config :tikentoken, :ollama_url, "http://localhost:11434"
```

Then use it in your code:

```elixir
ollama_url = Application.get_env(:tikentoken, :ollama_url, "http://localhost:11434")
```

## CLI Usage

If you want to use the CLI in your project, you can run it from the dependency:

```bash
# Assuming tikentoken is in your deps
mix run -e "Tikentoken.CLI.main(System.argv())" -- --embed --model embeddinggemma "Hello world"
```

Or build the escript in your project:

```bash
mix escript.install github user/tikentoken
```

Then use:

```bash
tikentoken "Hello world"
tikentoken --embed "Hello world"
```

## Requirements

- **Elixir 1.18+**
- **Ollama** running locally with any supported model (`embeddinggemma`, `bge-large`, `gte-large`, etc.) for full functionality
- Without Ollama, the library falls back to mock tokenization

## Setup Ollama

1. Install Ollama: https://ollama.ai/
2. Pull your desired model:
   ```bash
   ollama pull embeddinggemma  # Default (768 dimensions)
   ollama pull bge-large       # Up to 1024 dimensions
   ollama pull gte-large       # Up to 1024 dimensions
   ollama pull tinyllama       # Chat/text generation
   ```
3. Start Ollama: `ollama serve`

## Testing

Add to your `test/test_helper.exs` or individual test files:

```elixir
# For integration tests with Ollama
{:ok, tokens} = Tikentoken.tokenize("test", "embeddinggemma", "id", %{}, "http://localhost:11434")

# For unit tests with mocked responses
# Use Mox or similar for HTTP mocking
```

## API Reference

### Tikentoken.tokenize/5

```elixir
tokenize(text :: String.t(), model :: String.t(), format :: String.t(), extra_options :: map(), base_url :: String.t()) ::
  {:ok, [integer()]} | {:error, String.t()}
```

Tokenizes text into numerical IDs using an Ollama model.

- `text`: The text to tokenize
- `model`: Model name (default: "embeddinggemma")
- `format`: Token format, currently only "id" is supported (default: "id")
- `extra_options`: Additional options passed to Ollama's tokenize API, such as `%{"add_bos" => true}` to include Beginning of Sequence token, or `%{"add_eos" => true}` for End of Sequence token. Refer to Ollama API documentation for the complete list of supported options.
- `base_url`: Ollama server URL (default: "http://localhost:11434")

### Tikentoken.compute_embedding/4

```elixir
compute_embedding(text :: String.t(), dim :: integer(), model :: String.t(), base_url :: String.t()) ::
  {:ok, [float()]} | {:error, String.t()}
```

Note: The function signature shows parameters in order, but defaults are applied, so you can call it as `compute_embedding("text", 768)`.

Converts text into embeddings - numerical vectors that represent semantic meaning.

- `text`: The text to embed
- `dim`: Embedding dimension - the size of the output vector (varies by model).
        Higher dimensions capture more semantic detail but require more storage.
        (default: 768)
- `model`: Ollama model name for embeddings (default: "embeddinggemma")
- `base_url`: Ollama server URL (default: "http://localhost:11434")

### Tikentoken.chat/4

```elixir
chat(prompt :: String.t(), model :: String.t(), options :: map(), base_url :: String.t()) ::
  {:ok, String.t()} | {:error, String.t()}
```

Generates text/chat responses using chat-capable Ollama models.

- `prompt`: The text prompt to send to the model
- `model`: Ollama model name for chat (default: "tinyllama"). Must support chat.
- `options`: Additional options like temperature, max_tokens, etc. (default: %{})
- `base_url`: Ollama server URL (default: "http://localhost:11434")

## Contributing

When using this as a library in your project:

1. Fork the tikentoken repository
2. Make your changes
3. Update your local path dependency or publish to Hex
4. Test integration in your application

## Troubleshooting

### Ollama Connection Issues

- Ensure Ollama is running: `ollama serve`
- Check the base URL is correct (default: `http://localhost:11434`)
- Verify the model is pulled: `ollama pull <your-model-name>`

### Fallback Behavior

When Ollama is unavailable, the tokenizer falls back to mock implementation that returns fake token IDs based on word lengths. This ensures your application continues to work in development/testing environments.

### Performance

- Tokenization via Ollama is faster and more accurate than the mock fallback
- For production use, ensure Ollama is properly configured and running
- The library includes retry logic for transient network errors

## Appendix: PostgreSQL Vector Storage

### Setting Up Vector Columns

If you plan to store embedding vectors in PostgreSQL, you'll need the [pgvector](https://github.com/pgvector/pgvector) extension:

```sql
-- Install pgvector extension (run once per database)
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table with embedding column
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    description TEXT,
    product_embedding vector(768)  -- Choose dimension based on your --embed_dim
);
```

### Supported Dimensions

Dimensions vary by model. Check your model's specifications:

- **embeddinggemma**: `vector(768)` max (via MRL)
- **bge-large**: `vector(1024)` max
- **gte-large**: `vector(1024)` max
- **nomic-embed-text**: `vector(768)` max

Always use the maximum dimension your chosen model supports for best results.

### Using larger vectors

The BGE-Large model provides **1024-dimensional embeddings** by default, offering higher semantic detail than EmbeddingGemma's 768 dimensions. This gives you:

- **Better semantic matching** for complex queries
- **Higher accuracy** for similarity searches
- **More detailed representations** for nuanced text

The BGE (BAAI General Embedding) models are trained on massive multilingual datasets and excel at capturing semantic relationships across languages.

### Example Usage

```elixir
# Generate embedding with specific model and dimensions
{:ok, embedding} = Tikentoken.compute_embedding("iPhone 99 Pro", 1024, "bge-large")

# Store in PostgreSQL (vector column sized for your model)
query = "INSERT INTO products (name, product_embedding) VALUES ($1, $2)"
Postgrex.query!(conn, query, ["iPhone 99 Pro", embedding])

# Example with different models
{:ok, embedding} = Tikentoken.compute_embedding("iPhone 99 Pro", 768, "gte-large")
```

### Performance Considerations

- **Storage**: Higher dimensions = more disk space
- **Query Speed**: Lower dimensions = faster similarity searches
- **Accuracy**: Higher dimensions = better semantic matching

Start with `vector(768)` for development, then optimize based on your performance needs.

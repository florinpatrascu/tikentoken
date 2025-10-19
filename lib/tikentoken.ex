defmodule Tikentoken do
  @moduledoc """
  Tikentoken is an Elixir library for AI-powered text processing using Ollama models.

  Provides three main capabilities:
  - **Tokenization**: Convert text to token IDs using embedding models
  - **Embeddings**: Generate vector representations for semantic similarity
  - **Chat**: Generate text responses using language models

  Supports various Ollama models including embeddinggemma, bge-large, gte-large, tinyllama, mistral, and more.
  Falls back to mock tokenization when Ollama is unavailable.

  ## Quick Start

      # Tokenize text
      {:ok, tokens} = Tikentoken.tokenize("Hello world")

      # Generate embeddings
      {:ok, embedding} = Tikentoken.compute_embedding("Hello world", 768)

      # Chat with AI
      {:ok, response} = Tikentoken.chat("Write a haiku about coding")
  """

  alias Req

  @doc """
  Tokenize text into numerical IDs using Ollama embedding models.

  Converts input text into a list of token IDs that can be used for downstream processing.
  Falls back to mock tokenization if Ollama is unavailable.

  ## Supported Models

  Works with embedding models like `embeddinggemma`, `bge-large`, `gte-large`, `nomic-embed-text`.

  ## Parameters

  - `text`: The text to tokenize
  - `model`: Ollama embedding model name (default: "embeddinggemma")
  - `format`: Token format, currently only "id" is supported (default: "id")
  - `extra_options`: Additional options passed to Ollama's tokenize API, such as `%{add_bos: true}` to include Beginning of Sequence token, or `%{add_eos: true}` for End of Sequence token. See Ollama API docs for full list.
  - `base_url`: Ollama server URL (default: "http://localhost:11434")

  ## Examples

      iex> Tikentoken.tokenize("Hello world")
      {:ok, [5, 5]}  # Mock tokens when Ollama unavailable

      iex> Tikentoken.tokenize("Hello world", "bge-large")
      {:ok, [105, 1919]}  # Real tokens when Ollama available

  """
  @spec tokenize(String.t(), String.t(), String.t(), map(), String.t()) ::
          {:ok, [integer()]} | {:error, String.t()}
  def tokenize(
        text,
        model \\ "embeddinggemma",
        format \\ "id",
        extra_options \\ %{},
        base_url \\ "http://localhost:11434"
      ) do
    case format do
      "id" ->
        tokenize_ids(text, model, extra_options, base_url)

      "piece" ->
        {:error, "Piece format not supported; use 'id' format with Ollama"}

      _ ->
        {:error, "Invalid format: use 'id'"}
    end
  end

  @doc """
  Generate embeddings (vector representations) of text using Ollama models.

  Embeddings are numerical vectors that capture the semantic meaning of text.
  They enable semantic similarity comparison, search, clustering, and other AI tasks.
  Higher dimensions generally provide better semantic understanding but require more storage.

  ## Supported Models

  Works with embedding-capable models:
  - `embeddinggemma` (up to 768 dimensions)
  - `bge-large` (up to 1024 dimensions)
  - `gte-large` (up to 1024 dimensions)
  - `nomic-embed-text` (up to 768 dimensions)

  ## Parameters

  - `text`: The text to embed
  - `dim`: Desired embedding dimension (must be supported by the model)
  - `model`: Ollama model name for embeddings (default: "embeddinggemma")
  - `base_url`: Ollama server URL (default: "http://localhost:11434")

  ## Examples

      # Default model with 768 dimensions
      iex> Tikentoken.compute_embedding("Hello world", 768)
      {:ok, [0.123, 0.456, ...]}  # 768-dimensional vector

      # BGE-Large with 1024 dimensions
      iex> Tikentoken.compute_embedding("Hello world", 1024, "bge-large")
      {:ok, [0.123, 0.456, ...]}  # 1024-dimensional vector

  """
  @spec compute_embedding(String.t(), integer(), String.t(), String.t()) ::
          {:ok, [float()]} | {:error, String.t()}
  def compute_embedding(
        text,
        dim \\ 768,
        model \\ "embeddinggemma",
        base_url \\ "http://localhost:11434"
      ) do
    compute_embedding_internal(text, model, dim, base_url)
  end

  @doc """
  Generate text responses using chat-capable Ollama language models.

  Sends a prompt to a language model and returns the generated text response.
  Useful for conversational AI, text generation, creative writing, and more.

  ## Supported Models

  Works with chat/text generation models:
  - `tinyllama` (default - lightweight and fast)
  - `mistral` (powerful 7B parameter model)
  - `llama3.2` (Meta's latest model)
  - Any other Ollama model with `/api/generate` endpoint

  ## Parameters

  - `prompt`: The text prompt to send to the model
  - `model`: Ollama language model name (default: "tinyllama")
  - `options`: Additional generation options like `temperature`, `max_tokens`, etc. (default: %{})
  - `base_url`: Ollama server URL (default: "http://localhost:11434")

  ## Examples

      # Simple chat with default model
      iex> Tikentoken.chat("Hello, how are you?")
      {:ok, "Hello! I'm doing well, thank you for asking. How can I help you today?"}

      # Creative writing with custom model and options
      iex> Tikentoken.chat("Write a haiku about coding", "mistral", %{"temperature" => 0.7})
      {:ok, "Fingers dance on keys\\nCode flows like gentle stream\\nBugs hide in shadows"}

      # Technical explanation
      iex> Tikentoken.chat("Explain recursion simply", "tinyllama")
      {:ok, "Recursion is a programming technique where a function calls itself..."}

  """
  @spec chat(String.t(), String.t(), map(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def chat(prompt, model \\ "tinyllama", options \\ %{}, base_url \\ "http://localhost:11434") do
    chat_internal(prompt, model, options, base_url)
  end

  defp compute_embedding_internal(text, model, dim, base_url) do
    url = "#{base_url}/api/embeddings"

    body = %{
      model: model,
      prompt: text,
      options: %{output_dimension: dim}
    }

    case Req.post(url, json: body, receive_timeout: 60_000, retry: :transient) do
      {:ok, %{status: 200, body: %{"embedding" => embed}}} ->
        if length(embed) != dim do
          {:error, "Unexpected dim: #{length(embed)} (expected #{dim})"}
        else
          {:ok, embed}
        end

      {:ok, %{body: %{"error" => err}}} ->
        {:error, err}

      _ ->
        {:error, "Ollama request failed (ensure server running?)"}
    end
  end

  # a simple Chat implementation, mostly used for testing while i'm alone in the iex sessions {=
  defp chat_internal(prompt, model, options, base_url) do
    url = "#{base_url}/api/generate"

    default_options = %{
      "stream" => false,
      # hmmm ...
      "temperature" => 0.7
    }

    merged_options = Map.merge(default_options, options)

    body =
      %{
        model: model,
        prompt: prompt,
        stream: merged_options["stream"]
      }
      |> Map.merge(merged_options)

    case Req.post(url, json: body, receive_timeout: 120_000, retry: :transient) do
      {:ok, %{status: 200, body: %{"response" => response}}} ->
        {:ok, response}

      {:ok, %{body: %{"error" => err}}} ->
        {:error, err}

      _ ->
        {:error, "Chat request failed (ensure model supports chat and Ollama is running?)"}
    end
  end

  defp tokenize_ids(input, model, extra_options, base_url) do
    url = "#{base_url}/api/tokenize"

    body =
      %{
        model: model,
        prompt: input
      }
      |> Map.merge(extra_options)

    case Req.post(url, json: body, receive_timeout: 30_000, retry: :transient) do
      {:ok, %{status: 200, body: %{"tokens" => tokens}}} ->
        {:ok, tokens}

      _ ->
        fallback_tokenize_ids(input)
    end
  end

  defp fallback_tokenize_ids(input) do
    tokens =
      input
      |> String.replace(~r/[[:punct:]]/, " \\0 ")
      |> String.split()
      |> Enum.filter(&(&1 != ""))

    {:ok, Enum.map(tokens, &String.length/1)}
  end
end

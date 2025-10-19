defmodule Tikentoken.CLI do
  @moduledoc """
  Command-line interface for Tikentoken.

  Provides three main operations:
  - **Tokenization**: Convert text to token IDs using various Ollama models
  - **Embeddings**: Generate vector representations of text for semantic similarity
  - **Chat**: Generate text responses using chat-capable language models

  ## Supported Operations

  - Tokenization: `--model` (defaults to embeddinggemma) for embedding models like embeddinggemma, bge-large, gte-large, nomic-embed-text
  - Embeddings: `--embed --model` for generating vector representations (supports various dimensions)
  - Chat: `--chat --model` (defaults to tinyllama) for text generation with models like tinyllama, mistral, llama3.2

  ## Usage Examples

      # Tokenize text
      tikentoken "Hello world"
      tikentoken --model bge-large "Hello world"

      # Generate embeddings
      tikentoken --embed "Hello world"
      tikentoken --model gte-large --embed --embed_dim 1024 "Hello world"

      # Chat/text generation
      tikentoken --chat "Write a haiku"
      tikentoken --model tinyllama --chat "Explain recursion"

  ## Model Defaults

  - Tokenization/Embeddings: `embeddinggemma`
  - Chat: `tinyllama`

  Falls back to mock tokenization when Ollama is unavailable.
  """

  @doc """
  Main entry point for the CLI. Parses command line arguments, determines the operation mode (tokenize, embed, or chat),
  handles input, executes the appropriate Tikentoken function, and outputs the results.

  Supports tokenization, embedding generation, and chat responses using Ollama models.

  ## Command Line Arguments

  - `--model <string>`: Ollama model name. Defaults to "embeddinggemma" for tokenize/embed, "tinyllama" for chat.
  - `--format <string>`: Token format for tokenization. Only "id" is supported. Default: "id".
  - `--extra_options <string>`: Additional options as comma-separated key:value pairs (e.g., "add_bos:true,add_eos:false"). Passed to Ollama's tokenize API. See Ollama docs for full options. Default: "".
  - `--embed`: Flag to compute embeddings instead of tokenization.
  - `--chat`: Flag to generate chat/text response instead of tokenization.
  - `--ollama_url <string>`: Ollama API base URL. Default: "http://localhost:11434".
  - `--embed_dim <integer>`: Embedding dimension/vector size. Default: 768.
  - `--help`: Show help message and exit.

  ## Input

  Input text can be provided via stdin (piped) or as trailing arguments after options.

  ## Examples

      # Tokenize with default model
      echo "Hello world" | tikentoken

      # Tokenize with specific model
      tikentoken --model bge-large "Hello world"

      # Generate embeddings
      tikentoken --embed --embed_dim 1024 "Hello world"

      # Chat with AI
      tikentoken --chat "Write a haiku"
  """
  def main(args) do
    {opts, remaining_args, _} =
      OptionParser.parse(
        args,
        strict: [
          model: :string,
          format: :string,
          extra_options: :string,
          embed: :boolean,
          chat: :boolean,
          ollama_url: :string,
          embed_dim: :integer,
          help: :boolean
        ]
      )

    if Keyword.get(opts, :help, false) do
      print_help()
      System.halt(0)
    end

    format = opts[:format] || "id"
    extra_options = parse_extra_options(opts[:extra_options] || "")
    do_embed = Keyword.get(opts, :embed, false)
    do_chat = Keyword.get(opts, :chat, false)
    model = opts[:model] || if(do_chat, do: "tinyllama", else: "embeddinggemma")
    ollama_url = opts[:ollama_url] || "http://localhost:11434"
    embed_dim = opts[:embed_dim] || 768

    input =
      remaining_args
      |> case do
        [] -> IO.read(:stdio, :eof)
        args -> Enum.join(args, " ")
      end
      |> String.trim()

    if input == "" do
      IO.puts("Error: No input provided.")
      System.halt(1)
    end

    operation =
      cond do
        do_chat -> :chat
        do_embed -> :embed
        true -> :tokenize
      end

    result =
      case operation do
        :tokenize ->
          Tikentoken.tokenize(input, model, format, extra_options, ollama_url)

        :embed ->
          Tikentoken.compute_embedding(input, embed_dim, model, ollama_url)

        :chat ->
          Tikentoken.chat(input, model, %{}, ollama_url)
      end

    case result do
      {:error, reason} ->
        operation_name =
          case operation do
            :tokenize -> "Tokenization"
            :embed -> "Embedding"
            :chat -> "Chat"
          end

        IO.puts("#{operation_name} error: #{reason}")
        System.halt(1)

      {:ok, data} ->
        case operation do
          :tokenize ->
            IO.puts("Tokens: #{Enum.join(data, " ")}")

          :embed ->
            IO.puts("Embedding (psql vector): #{format_vector(data)}")

          :chat ->
            IO.puts(data)
        end
    end
  end

  defp format_vector(vec) do
    floats = Enum.map(vec, &Float.to_string/1) |> Enum.join(",")
    "[#{floats}]"
  end

  defp parse_extra_options(options_str) do
    options_str
    |> String.split(",", trim: true)
    |> Enum.map(fn pair ->
      [key, value] = String.split(pair, ":", parts: 2)
      key = String.trim(key)
      value = String.trim(value)

      parsed_value =
        case value do
          "true" -> true
          "false" -> false
          _ -> value
        end

      {key, parsed_value}
    end)
    |> Map.new()
  end

  defp print_help do
    IO.puts("""
    Usage: tikentoken [options] [input text]

    Options:
      --model <name>          Ollama model name (default: embeddinggemma for tokenize/embed, tinyllama for chat). Supports: embeddinggemma, bge-large, gte-large, nomic-embed-text, tinyllama, mistral, etc.
      --format <id>           For tokens: "id" (IDs). Default: id (piece not supported)
      --extra_options <str>   For tokens: e.g., "add_bos:true,add_eos:true" (passed to Ollama's tokenize API; see docs for full list)
      --embed                 Compute embedding using the specified model
      --chat                  Generate chat/text response using the specified model
      --ollama_url <url>      Ollama API base URL. Default: http://localhost:11434
      --embed_dim <int>       Embedding dimension - vector size (varies by model). Higher = more detail but more storage (default: 768)
      --help                  Show this help

    Input: Pipe or args.
    Output: Tokens, embeddings, or chat responses.

    Examples:
      echo "Hello world" | tikentoken                                    # Tokenize
      tikentoken --model bge-large "Hello world"                      # Tokenize with specific model
      tikentoken --model gte-large --embed --embed_dim 1024 "Hello world"  # Embed
      tikentoken --chat "Write a haiku about coding"                  # Chat
      tikentoken --model tinyllama --chat "Explain quantum computing"   # Chat with specific model
    """)
  end
end

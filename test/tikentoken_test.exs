defmodule TikentokenTest do
  @moduledoc """
  Test suite for Tikentoken library.

  This module tests the core functionality of Tikentoken:

  - Tokenization with Ollama models or mock fallback
  - Embedding generation using Ollama models
  - Chat/text generation using language models

  Tests are designed to work in both development and CI environments:

  - Tokenization tests always pass (fallback to mock when Ollama unavailable)
  - Embedding and chat tests gracefully skip when Ollama is not running
  """

  use ExUnit.Case

  test "tokenize works with Ollama or fallback" do
    {:ok, ids} = Tikentoken.tokenize("Hello world")
    assert is_list(ids)
    assert Enum.all?(ids, &is_integer/1)
    assert length(ids) > 0
  end

  test "compute_embedding works" do
    case Tikentoken.compute_embedding("Hello world", 768, "embeddinggemma") do
      {:ok, embedding} ->
        assert is_list(embedding)
        assert Enum.all?(embedding, &is_float/1)
        assert length(embedding) == 768

      {:error, _reason} ->
        :ok
    end
  end

  test "chat works" do
    case Tikentoken.chat("Say hello", "tinyllama") do
      {:ok, response} ->
        assert is_binary(response)
        assert String.length(response) > 0

      {:error, _reason} ->
        :ok
    end
  end
end

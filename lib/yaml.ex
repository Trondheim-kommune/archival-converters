defmodule ArchivalConverters.Yaml do
    @moduledoc false

    def encode(_, indent \\ "", prefix \\ "")

    def encode({k, v}, indent, prefix) when is_bitstring(v) or is_atom(v) do
        indent <> prefix <> "#{k}: #{v}\n"
    end

    def encode({k, v}, indent, prefix) do
        indent <> prefix <> "#{k}:\n" <> encode(v, indent <> "  ")
    end

    def encode([{k, v} | tail], indent, prefix) do
        encode({k, v}, indent, prefix) <> encode(tail, indent, prefix)
    end

    def encode([item | tail], indent, _) do
        encode(item, indent, "- ") <> encode(tail, indent)
    end

    def encode([], _, _) do
        ""
    end

    def decode(string) do
        YamlElixir.read_from_string string
    end
end

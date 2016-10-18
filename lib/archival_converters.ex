defmodule ArchivalConverters do
    def main(["doc-to-pdfa", path | _]) do
        System.cmd "cscript" ["doc_to_pdfa.js" | ArchivalConverters.recursive_ls(path) |>
            Enum.filter(&ArchivalConverters.path_is_perhaps_office_file(&1))]
    end

    def main(["update-siard", path_to_siard, path_to_yaml | _]) do
        cond do
            File.dir?(path) -> recursive_ls(path)
                |> Enum.map(fn(p) -> {:path, p} end)
                |> ArchivalConverters.Siard.updateHeader path_to_yaml
            path_is_type(path, "ZIP") -> :zip.extract(path, [:memory])
                |> ArchivalConverters.Siard.updateHeader path_to_yaml
            true -> IO.puts("Not a path of a folder or siard archive")
        end
    end

    def path_is_type(path, type) do
        case File.open(path) do
            {:ok, io_dev} ->
                case IO.binread(io_dev, 64) do
                    {:error, reason} -> IO.puts("Error reading from file: #{path} #{reason}")
                    :eof -> IO.puts("Error reading from file: #{path} EOF encountered before header was read")
                    data ->
                        cond detect_filetype(data) do
                            {:ok, type} -> true
                            {:ok, _} -> false
                            {:error, _} ->
                                IO.puts("Cannot recognize filetype for: #{path}")
                                false
                        end
                end
            {:error, posix} ->
                IO.puts("Error opening file: #{path} #{posix}")
        end
        false
    end

    def path_is_perhaps_office_file(path) do
        path_is_type(path, "ZIP") or path_is_type(path, "CFBF")
    end

    def recursive_ls(path) do
        cond do
            File.regular?(path) -> [path]
            File.dir?(path) ->
                File.ls!(path) |>
                Enum.map(&Path.join(path, &1)) |>
                Enum.map(&ArchivalConverters.recursive_ls/1) |>
                Enum.concat
            true -> []
        end
    end

    @spec detect_filetype(binary) :: {atom, String.t}
    def detect_filetype("%PDF" <> _), do: {:ok, "PDF"}
    def detect_filetype(<<0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, _ :: binary>>), do: {:ok, "CFBF"}
    def detect_filetype(<<0x50, 0x4B, 0x03, 0x04, _ :: binary>>), do: {:ok, "ZIP"}
    def detect_filetype("BM" <> _), do: {:ok, "BMP"}
    def detect_filetype(<<0xFF, 0xD8, 0xFF, _ :: binary>>), do: {:ok, "JPEG"}
    def detect_filetype(<<0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20, 0x0D, 0x0A, _ :: binary>>), do: {:ok, "JPEG2000"}
    def detect_filetype(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _ :: binary>>), do: {:ok, "PNG"}
    def detect_filetype(unkown) do
        cond do
            String.valid?(unkown) -> {:ok, "UTF-8"}
            true -> <<head :: size(64), _ :: binary>> = unkown
                {:error, <<head :: size(64)>>}
        end
    end
end

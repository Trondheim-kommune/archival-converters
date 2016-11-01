defmodule ArchivalConverters.Fileutils do
    @moduledoc false

    def path_is_type(path, type) do
        case File.open(path) do
            {:ok, io_dev} ->
                header = IO.binread(io_dev, 40)
                File.close(io_dev)
                case header do
                    {:error, reason} -> IO.puts("Error reading from file: #{path} #{reason}")
                    :eof -> IO.puts("Error reading from file: #{path} EOF encountered before header"
                                    <> " was read")
                    data -> is_filetype(data, type)
                end
            {:error, posix} ->
                IO.puts("Error opening file: #{path} #{posix}")
        end
    end

    defp is_filetype(data, type) do
        case detect_filetype(data) do
            {:ok, filetype} -> filetype == type
            {:error, _} ->
                IO.puts("Cannot recognize filetype for: #{path}")
                false
        end
    end

    def path_is_perhaps_office_file(path) do
        path_is_type(path, "ZIP") or path_is_type(path, "CFBF")
    end

    def recursive_ls(path) do
        cond do
            File.regular?(path) -> [path]
            File.dir?(path) ->
                path |>
                File.ls! |>
                Enum.map(&Path.join(path, &1)) |>
                Enum.map(&recursive_ls/1) |>
                Enum.concat
            true -> []
        end
    end

    def extract_archive(archive_path, extract_path, output_path) do
        IO.puts "Extracting archive"
        System.cmd("7z", ["x", archive_path, extract_path, "-aou", "-o#{output_path}"])
        Path.absname(Path.join(output_path, extract_path))
    end

    def update_archive(archive_path, update_path, cd) do
        IO.puts "Updating archive"
        System.cmd("7z", ["u", archive_path, update_path], cd: cd)
        archive_path
    end

    @spec detect_filetype(binary) :: {atom, String.t}
    def detect_filetype(<<0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20, 0x0D, 0x0A,
        _ :: binary>>), do: {:ok, "JPEG2000"}
    def detect_filetype(<<0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, _ :: binary>>),
        do: {:ok, "CFBF"}
    def detect_filetype(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _ :: binary>>),
        do: {:ok, "PNG"}
    def detect_filetype(<<0x50, 0x4B, 0x03, 0x04, _ :: binary>>), do: {:ok, "ZIP"}
    def detect_filetype("%PDF" <> _), do: {:ok, "PDF"}
    def detect_filetype(<<0xFF, 0xD8, 0xFF, _ :: binary>>), do: {:ok, "JPEG"}
    def detect_filetype("BM" <> _), do: {:ok, "BMP"}
    def detect_filetype(unkown) do
        if String.valid?(unkown) do
            {:ok, "UTF-8"}
        end
        <<head :: size(64), _ :: binary>> = unkown
        {:error, <<head :: size(64)>>}
    end
end

defmodule ArchivalConverters do
    @moduledoc false
    alias ArchivalConverters.Fileutils
    alias ArchivalConverters.Siard

    def find_files(path) do
        path |>
            Fileutils.recursive_ls |>
            Enum.filter(&Fileutils.path_is_perhaps_office_file(&1)) |>
            Enum.filter(fn(p) -> String.ends_with?(p, "doc") end) |>
            Enum.map(fn(p) -> String.replace(p, "/", "\\") end)
    end

    def main(["doc-to-pdfa", path | _]) do
        System.cmd(Path.absname("lib\\doc_to_pdfa.js"), find_files(path))
    end

    def main(["update-siard", siard_path, yaml_path | _]) do
        Siard.update_header(siard_path, yaml_path)
    end

    def main(args) do
        IO.puts "Cannot parse input: #{args}"
    end
end

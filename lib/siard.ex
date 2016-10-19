defmodule ArchivalConverters.Siard do
    @moduledoc false

    @metadata_path "header/metadata.xml"

    def update_header(siard_path, description_path) do
        descriptions = File.read!(description_path) |> ArchivalConverters.Yaml.decode
        cond do
            File.dir?(siard_path) ->
                update_metadata({"", @metadata_path, siard_path}, descriptions)
            ArchivalConverters.Fileutils.path_is_type(siard_path, "ZIP") ->
                case System.tmp_dir() do
                    nil ->
                        IO.puts "Cannot create temp dir, check system priveleges."
                        System.halt(1)
                    temp_path ->
                        IO.puts temp_path
                        ArchivalConverters.Fileutils.extract_archive(siard_path, @metadata_path, temp_path)
                            |> update_metadata(descriptions)
                        ArchivalConverters.Fileutils.update_archive(siard_path, @metadata_path, temp_path)
                end
            true -> IO.puts("#{siard_path} is not a folder or siard archive")
        end
    end

    def update_metadata(path, descriptions) do
        IO.inspect path
        path
    end
end
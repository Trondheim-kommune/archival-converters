defmodule ArchivalConverters.Siard do
    @moduledoc false
    alias ArchivalConverters.Fileutils
    alias ArchivalConverters.Yaml

    @metadata_path "header/"
    @metadata_xml "metadata.xml"
    @metadata_xsd "metadata.xsd"

    def update_header(siard_path, description_path) do
        descriptions = description_path
            |> File.read!
            |> Yaml.decode
        cond do
            File.dir?(siard_path) ->
                update_metadata({"", @metadata_path, siard_path}, descriptions)
            Fileutils.path_is_type(siard_path, "ZIP") ->
                case System.tmp_dir() do
                    nil ->
                        IO.puts "Cannot create temp dir, check system priveleges."
                        System.halt(1)
                    temp_path ->
                        IO.puts temp_path
                        siard_path
                            |> Fileutils.extract_archive(@metadata_path,
                                temp_path)
                            |> update_metadata(descriptions)
                        Fileutils.update_archive(siard_path, @metadata_path,
                            temp_path)
                end
            true -> IO.puts("#{siard_path} is not a folder or siard archive")
        end
    end

    defp get_description(map) do
        Map.get(map, "description")
    end

    defp tables_with_updates(map) do
        Enum.filter(Map.get(map, "tables"), &get_description/1)
    end

    def update_field(%{"name" => name, "description" => description}, xml_tree) do
    end

    def update_table(%{"name" => name, "description" => description, "fields" => fields} = map,
                     xml_tree) do
        Enum.each(fields, &update_field(&1, xml_tree))
    end

    def update_schema do
    end

    def update_metadata(path, descriptions) do
        case :erlsom.compile_xsd_file(Path.join(path, @metadata_xsd)) do
          {:ok, model} ->
            case :erlsom.scan(File.read!(Path.join(path, @metadata_xml)), model) do
              {:ok, result, _} ->
                {:siardArchive, _xsd_loc, _xsd_version, _name, _meta1, _meta2, _meta3, _meta4,
                 _meta5, _something, _tool, _creation_date, _undefined1, _creation_host, _system_db,
                 _undefined2, _undefined3, {:schemasType, [], schemas}, _users, _roles,
                 _privileges} = result
                IO.puts "Writing metadata.xml"
                # File.write!(Path.join(path, @metadata_xml), :erlsom.write(result, model))
                System.halt(1)
              something ->
                IO.puts "Failed to scan #{@metadata_xml} using model #{@metadata_xsd} from: #{path}"
                System.halt(1)
            end
          something ->
            IO.puts "Failed to compile #{@metadata_xsd} file from: #{path}"
            System.halt(1)
        end
    end
end

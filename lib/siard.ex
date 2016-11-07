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

    defp update_tables_metadata(_, tables) do
        tables
    end

    defp update_views_metadata(_, views) do
        views
    end

    defp update_routines_metadata(_, routines) do
        routines
    end

    defp write_metadata_xml(metadata, model, path) do
      IO.puts "Writing metadata.xml"
      case :erlsom.write(metadata, model) do
        {:ok, xml} ->
            File.write!(path,
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
                <> to_string :erlsom_lib.prettyPrint(xml)
            )
        _ ->
            IO.puts("metadata doesn't match model after edit")
            System.halt(1)
      end
    end

    def update_metadata(schemas_update, schemas) when is_list schemas do
      Enum.reduce(schemas_update, schemas, fn(schema_update, schemas) ->
                  schema_index = Enum.find_index(schemas,
                      fn({:schemaType, [], schema_name, _, _, _, _, _, _}) ->
                          Map.get(schema_update, "name") == to_string schema_name
                      end
                  )
                  {:schemaType, [], schema_name, schema_loc, unkown_1, unkown_2, tables, views,
                   routines} = Enum.fetch!(schemas, schema_index)
                  List.replace_at(schemas, schema_index,
                      {:schemaType, [], schema_name, schema_loc, unkown_1, unkown_2,
                       update_tables_metadata(Map.get(schema_update, "tables"), tables),
                       update_views_metadata(Map.get(schema_update, "views"), views),
                       update_routines_metadata(Map.get(schema_update, "routines"), routines)}
                  )
              end)
    end

    def update_metadata(deposit_update, {:siardArchive, xsd_loc, xsd_version, name, meta1,
        meta2, meta3, meta4, meta5, something, tool, creation_date, undefined1,
        creation_host, system_db, undefined2, undefined3, {:schemasType, [], schemas},
        users, roles, privileges}) do
        {:siardArchive, xsd_loc, xsd_version, name, meta1, meta2, meta3, meta4,
         meta5, something, tool, creation_date, undefined1, creation_host, system_db,
         undefined2, undefined3, {:schemasType, [],
         update_metadata(Map.get(deposit_update, "schemas"), schemas)}, users, roles, privileges}
    end

    def update_metadata(path, deposit_description) do
        case :erlsom.compile_xsd_file(Path.join(path, @metadata_xsd)) do
          {:ok, model} ->
            update_metadata(path, model, deposit_description)
          _ ->
            IO.puts "Failed to compile #{@metadata_xsd} file from: #{path}"
            System.halt(1)
        end
    end

    def update_metadata(path, model, deposit_description) do
        case :erlsom.scan(File.read!(Path.join(path, @metadata_xml)), model) do
            {:ok, result, _} ->
                deposit_description |>
                update_metadata(result) |>
                write_metadata_xml(model, Path.join(path, @metadata_xml))
                System.halt(1)
            _ ->
                IO.puts "Failed to scan #{@metadata_xml} using model #{@metadata_xsd} from: #{path}"
                System.halt(1)
        end
    end
end

defmodule RailwayIpc.Utils do
  @moduledoc false

  def module_defined?(module) do
    # forces module to be loaded
    module.__info__(:module)
    true
  rescue
    UndefinedFunctionError -> false
  end

  def protobuf_to_json(protobuf) do
    protobuf
    |> protobuf_to_map
    |> Jason.encode!()
  end

  def to_pascal_case(string)
  def to_pascal_case(atom) when is_atom(atom), do: atom |> to_string |> to_pascal_case

  def to_pascal_case(""), do: ""
  def to_pascal_case(<<?_, t::binary>>), do: to_pascal_case(t)
  def to_pascal_case(<<h, t::binary>>), do: <<to_lower_char(h)>> <> do_to_pascal_case(t)

  defp do_to_pascal_case(<<?_, ?_, t::binary>>), do: do_to_pascal_case(<<?_, t::binary>>)

  defp do_to_pascal_case(<<?_, h, t::binary>>) when h >= ?a and h <= ?z,
    do: <<to_upper_char(h)>> <> do_to_pascal_case(t)

  defp do_to_pascal_case(<<?_, h, t::binary>>) when h >= ?0 and h <= ?9,
    do: <<h>> <> do_to_pascal_case(t)

  defp do_to_pascal_case(<<?_>>), do: <<>>
  defp do_to_pascal_case(<<?/, t::binary>>), do: <<?.>> <> to_pascal_case(t)
  defp do_to_pascal_case(<<h, t::binary>>), do: <<h>> <> do_to_pascal_case(t)
  defp do_to_pascal_case(<<>>), do: <<>>

  defp to_upper_char(char) when char >= ?a and char <= ?z, do: char - 32
  defp to_upper_char(char), do: char

  defp to_lower_char(char) when char >= ?A and char <= ?Z, do: char + 32
  defp to_lower_char(char), do: char

  defp protobuf_to_map(protobuf) do
    type = protobuf |> get_protobuf_type

    data =
      protobuf
      |> Map.from_struct()
      |> Map.new(fn
        {k, %_{} = struct} -> {to_pascal_case(k), protobuf_to_map(struct)}
        {k, v} -> {to_pascal_case(k), v}
      end)

    %{type: type, data: data}
  end

  defp get_protobuf_type(protobuf) do
    protobuf.__struct__ |> to_string |> String.replace(~r/^Elixir\./, "")
  end
end

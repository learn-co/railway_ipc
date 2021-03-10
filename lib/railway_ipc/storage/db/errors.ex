defmodule RailwayIpc.Storage.DB.Errors do
  @moduledoc """
  Helpers for formatting Ecto changeset errors.

  This code was (mostly) lifted from a blog post named
  [Prettify Ecto Error][1].

  This is an internal module, not part of the public API.

  [1]: https://thebrainfiles.wearebrain.com/prettify-ecto-errors-b85e9a7977f6

  """

  @doc """
  Formats Ecto changeset errors by converting them from keyword lists into a
  single string.

  For example, it will convert changeset errors like this:

  ```
  [
    encoded_message: {"can't be blank", [validation: :required]},
    message_type: {"can't be blank", [validation: :required]}
  ]
  ```

  Into a single string like this:

  ```
  "Encoded message can't be blank, Message type can't be blank"
  ```

  """
  def format(changeset) do
    Enum.join(pretty_errors(changeset.errors), ", ")
  end

  defp pretty_errors(errors) do
    errors
    |> Enum.map(&do_prettify/1)
  end

  defp do_prettify({field_name, message}) when is_bitstring(message) do
    human_field_name =
      field_name
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    human_field_name <> " " <> message
  end

  defp do_prettify({field_name, {message, variables}}) do
    compound_message = do_interpolate(message, variables)
    do_prettify({field_name, compound_message})
  end

  defp do_interpolate(string, [{name, value} | rest]) do
    n = Atom.to_string(name)
    msg = String.replace(string, "%{#{n}}", do_to_string(value))
    do_interpolate(msg, rest)
  end

  defp do_interpolate(string, []), do: string

  defp do_to_string(value) when is_integer(value), do: Integer.to_string(value)
  defp do_to_string(value) when is_bitstring(value), do: value
  defp do_to_string(value) when is_atom(value), do: Atom.to_string(value)
end

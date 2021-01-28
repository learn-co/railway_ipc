defmodule Test.Support.Helpers do
  @moduledoc """
  Various test helpers.

  """

  @doc """
  Repeatedly executes `fun` until it either returns `true` or
  reaches `timeout`.

  ## Example

  In a test, publish a message to a queue, then wait until it arrives in
  the queue. Fail if the message hasn't arrived after two seconds.

  ```
  wait_for_true(_2_seconds = 2000, fn ->
    assert 1 == queue_count("example_queue")
  end)
  ```

  """
  def wait_for_true(timeout, fun) when timeout > 0 do
    fun.()
  rescue
    _ ->
      Process.sleep(100)
      wait_for_true(timeout - 100, fun)
  end

  def wait_for_true(_timeout, fun), do: fun.()
end

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

  @doc """
  Given an `expr` that evaluates to an integer, execute `expr` and store the
  result. Then execute `block` which should trigger a side effect that changes
  the result of `expr`. The before and after results of `expr` are compared to
  the value of `by`, ensuring they are equal.

  ## Example

  Asserts that a database table row count was changed.

  ```
  assert_difference row_count("railway_ipc_published_messages"), by: 1 do
    :ok = Client.publish("railwayipc:test", proto, "json_protobuf")
  end
  ```

  """
  defmacro assert_difference(expr, [by: by], do: block) do
    quote do
      before = unquote(expr)
      unquote(block)
      after_ = unquote(expr)
      assert unquote(by) == after_ - before
    end
  end
end

defmodule LearnIpcEx.Test.BatchConsumer do
  use LearnIpcEx.Consumer, exchange: "experts", queue: "are_es_tee"
end

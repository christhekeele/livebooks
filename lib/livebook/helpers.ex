defmodule Livebook.Helpers do
  @moduledoc """
  Common helpers for these livebooks.

  > #### `use Livebook.Helpers` {: .info}
  >
  > When you `use Livebook.Helpers`, the following will be
  > imported into your livebook:
  >
  > - `Livebook.Module.defmodule/3`: an iterable version of `defmodule/2`
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import Livebook.Module, only: [defmodule: 3]
    end
  end
end

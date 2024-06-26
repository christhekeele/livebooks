fn ->
  # Run as: iex --dot-iex path/to/notebook.exs

  # Title: Surreal Numbers in Elixir

  System.cmd(
    "mix",
    ~w[hex.repo add christhekeele https://hex.chriskeele.com]
  )

  Mix.install(
    [
      {:ets, "~> 0.9.0"},
      {:eternal, "~> 1.2"},
      # {:livebooks, github: "christhekeele/livebooks", branch: "latest"},
      {:livebooks, "~> 0.0.1-dev", repo: "christhekeele"}
      # {:livebooks, path: "/Users/keele/Projects/personal/livebooks"},
    ],
    force: true
  )

  # ── Video Format ──

  # [Watch the ElixirConf 2022 lightning talk here!](https://www.youtube.com/watch?v=f1lNK5gDlwA&t=235s)

  # ── Representation ──

  # How do surreal numbers work? Let's build up a little intuition by representing them in Elixir.

  # First, let's bring in some `Livebooks.Helpers` that will let us iteratively build up a module to represent them.

  use Livebooks.Helpers

  # Surreal numbers are represented by a left set and a right set, where each set contains other full surreal numbers. For the purposes of this experiment, we'll just use a list to represent sets, and a tuple `{left_set, right_set}` to represent a single surreal.

  defmodule Surreal.Guards do
    defguard is_set(surreals) when is_list(surreals)
    defguard is_surreal(surreal) when is_tuple(surreal) and tuple_size(surreal) == 2
  end

  # ── Axioms ──

  # * Zero
  # * One
  # * Negation
  # * Addition
  # * Multiplication
  # * Division

  zero = {[], []}

  one = {[zero], []}

  # ── Extensions ──

  two = {[one], []}
  three = {[two], []}
  four = {[three], []}
  five = {[four], []}

  neg_one = {[], [zero]}
  neg_two = {[], [neg_one]}
  neg_three = {[], [neg_two]}

  one_half = {[zero], [one]}
  one_quarter = {[zero], [one_half]}
  three_quarters = {[one_half], [one]}
  five_eighths = {[one_half], [three_quarters]}

  # ── Module ──

  defmodule Surreal, v: 1 do
    @empty_set []
    @zero {@empty_set, @empty_set}
    @one {[@zero], @empty_set}

    IO.inspect(@zero)
    IO.inspect(@one)
  end

  # ── Set Concatenation ──

  defmodule Surreal, v: 2 do
    import Kernel, except: [<>: 2]
    import Surreal.Guards

    # Set concatenation

    def @empty_set <> surreals when is_set(surreals) do
      surreals
    end

    def surreals <> @empty_set when is_set(surreals) do
      surreals
    end

    def surreals1 <> surreals2 when is_set(surreals1) and is_set(surreals2) do
      Enum.uniq(surreals1 ++ surreals2)
    end
  end

  # ── Surreal Math ──

  defmodule Surreal, v: 3 do
    import Kernel, except: [-: 1, +: 2, -: 2, *: 2, /: 2, <>: 2]
    import Surreal.Guards

    @doc """
    Negates a surreal number.
    """
    def -@zero do
      @zero
    end

    def -surreal when is_surreal(surreal) do
      {left_set, right_set} = surreal
      {-right_set, -left_set}
    end

    # Set negation
    def -surreals when is_set(surreals) do
      Enum.map(surreals, &-/1)
    end

    @doc """
    Adds two surreal numbers.
    """
    def @zero + @zero do
      @zero
    end

    def surreal1 + surreal2 when is_surreal(surreal1) and is_surreal(surreal2) do
      {left1, right1} = surreal1
      {left2, right2} = surreal2

      left = (left1 + surreal2) <> (left2 + surreal1)
      right = (right1 + surreal2) <> (right2 + surreal1)
      {left, right}
    end

    # Set addition

    def surreals + surreal when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.+(&1, surreal)))
    end

    def surreal + surreals when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.+(surreal, &1)))
    end

    def surreals1 + surreals2 when is_set(surreals1) and is_set(surreals2) do
      Enum.uniq(Enum.flat_map(surreals1, &__MODULE__.+(&1, surreals2)))
    end

    @doc """
    Subtracts two surreal numbers.
    """
    def surreal1 - surreal2 when is_surreal(surreal1) and is_surreal(surreal2) do
      surreal1 + -surreal2
    end

    # Set subtraction

    def surreals - surreal when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.-(&1, surreal)))
    end

    def surreal - surreals when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.-(surreal, &1)))
    end

    def surreals1 - surreals2 when is_set(surreals1) and is_set(surreals2) do
      Enum.uniq(Enum.flat_map(surreals1, &__MODULE__.-(&1, surreals2)))
    end

    @doc """
    Multiplies two surreal numbers.
    """
    def @one * surreal when is_surreal(surreal), do: surreal
    def surreal * @one when is_surreal(surreal), do: surreal

    def surreal1 * surreal2 when is_surreal(surreal1) and is_surreal(surreal2) do
      {left1, right1} = surreal1
      {left2, right2} = surreal2

      left =
        (left1 * surreal2 + surreal1 * left2 - left1 * left2) <>
          (right1 * surreal2 + surreal1 * right2 - right1 * right2)

      right =
        (left1 * surreal2 + surreal1 * right2 - left1 * right2) <>
          (surreal1 * left2 + right1 * surreal2 - right1 * left2)

      {left, right}
    end

    # Set multiplication

    def surreals * surreal when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.*(&1, surreal)))
    end

    def surreal * surreals when is_set(surreals) and is_surreal(surreal) do
      Enum.uniq(Enum.map(surreals, &__MODULE__.*(surreal, &1)))
    end

    def surreals1 * surreals2 when is_set(surreals1) and is_set(surreals2) do
      Enum.uniq(Enum.flat_map(surreals1, &__MODULE__.*(&1, surreals2)))
    end
  end

  # ── Deriving numbers ──

  # import Kernel, except: [-: 1, +: 2, -: 2, *: 2, /: 2, <>: 2]
  # import Surreal

  # IO.inspect("zero + one == one")
  # (zero + one) |> IO.inspect()
  # one |> IO.inspect()

  # IO.inspect("one + one == two")
  # (one + one) |> IO.inspect()
  # two |> IO.inspect()

  # IO.inspect("zero - one == neg_one")
  # (zero - one) |> IO.inspect()
  # neg_one |> IO.inspect()

  # IO.inspect("neg_one - one == neg_two")
  # (neg_one - one) |> IO.inspect()
  # neg_two |> IO.inspect()

  # Surreal

  # ── Performing Multiplication ──

  require Logger

  defmodule Surreal, v: 4 do
    @doc """
    Converts a number to a surreal number.

    Supports integers, rational numbers, floats, and ratios of floats.
    """

    def to_surreal(numerator, denominator \\ 1)

    def to_surreal(numerator, denominator) when denominator < 0 do
      Logger.debug("to_surreal: `#{inspect(numerator)} / #{inspect(denominator)}`")
      to_surreal(-numerator, denominator)
    end

    def to_surreal(0, denominator) when is_integer(denominator) and denominator != 0, do: @zero

    def to_surreal(n, 1) when is_integer(n) and n > 0 do
      Logger.debug("to_surreal: `#{inspect(n)}`")

      Enum.reduce(1..n, @zero, fn _counter, surreal ->
        surreal + @one
      end)
    end

    def to_surreal(n, 1) when is_integer(n) and n < 0 do
      Logger.debug("to_surreal: `#{inspect(n)}`")
      -to_surreal(abs(n))
    end

    @doc """
    Converts a surreal number to a float.

    Returns `{:precise, number}` when the result is exactly that number.
    Otherwise returns and approximation as `{:approximate, number}`.
    """

    def to_number(@zero), do: 0.0

    def to_number({[@zero], []}), do: 1.0
    def to_number({[], [@zero]}), do: Kernel.-(1.0)

    def to_number({[left_surreal], []} = surreal) do
      Logger.debug("to_number: `#{inspect(surreal)}`")

      Surreal.Cache.try({:to_number, surreal}, fn ->
        Kernel.+(to_number(left_surreal), 1)
      end)
    end

    def to_number({[], [right_surreal]} = surreal) do
      Surreal.Cache.try({:to_number, surreal}, fn ->
        Kernel.-(to_number(right_surreal), 1)
      end)
    end

    def to_number({[left_surreal], [right_surreal]} = surreal) do
      Surreal.Cache.try({:to_number, surreal}, fn ->
        Kernel./(Kernel.+(to_number(left_surreal), to_number(right_surreal)), 2)
      end)
    end

    def to_number({left_surreals, right_surreals} = surreal) do
      left_numbers = Enum.uniq(Enum.map(left_surreals, &to_number/1))
      right_numbers = Enum.uniq(Enum.map(right_surreals, &to_number/1))

      if length(left_numbers) > 1 or length(right_numbers) > 1 do
        raise "Multi-surreals { #{inspect(left_numbers)} | #{inspect(right_numbers)} }:\n#{inspect(surreal)}"
      else
        Surreal.Cache.try({:to_number, surreal}, fn ->
          case {length(left_numbers), length(right_numbers)} do
            {0, 0} -> 0
            {0, 1} -> Kernel.-(List.first(right_numbers), 1)
            {1, 0} -> Kernel.+(List.first(left_numbers), 1)
            {1, 1} -> Kernel./(Kernel.+(List.first(left_numbers), List.first(right_numbers)), 2)
          end
        end)
      end
    end
  end

  Surreal.+(Surreal.to_surreal(2), Surreal.to_surreal(2)) |> IO.inspect()

  Surreal.*(Surreal.to_surreal(2), Surreal.to_surreal(2)) |> IO.inspect()

  six = Surreal.*(Surreal.to_surreal(2), Surreal.to_surreal(3))
  IO.inspect(six)
  six |> Surreal.to_number()

  nine = Surreal.*(Surreal.to_surreal(3), Surreal.to_surreal(3))
  IO.inspect(six)
  nine |> Surreal.to_number()
end

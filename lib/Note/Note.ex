defmodule Bank.Note do
  import Kernel, except: [abs: 1]

  @moduledoc """
  Defines a `Bank.Note` struct along with convenience methods for working with currencies.

  ## Example:

      iex> note = Bank.Note.new(500, :USD)
      %Bank.Note{amount: 500, currency: :USD}
      iex> note = Bank.Note.add(note, 550)
      %Bank.Note{amount: 1050, currency: :USD}
      iex> Bank.Note.to_string(note)
      "$10.50"

  ## Configuration options

  You can set defaults in your Mix configuration to make working with `Bank.Note` a little easier.

  ## Configuration:

      config :note,
        default_currency: :EUR,  # this allows you to do Bank.Note.new(100)
        separator: ".",          # change the default thousands separator for Bank.Note.to_string
        delimiter: ",",          # change the default decimal delimeter for Bank.Note.to_string
        symbol: false            # don’t display the currency symbol in Bank.Note.to_string
        symbol_on_right: false,  # position the symbol
        symbol_space: false      # add a space between symbol and number
        fractional_unit: false   # don’t display the remainder or the delimeter
  """

  @type t :: %__MODULE__{
    amount: integer,
    currency: atom
  }

  defstruct amount: 0, currency: :USD

  alias Bank.Note.Currency

  @spec new(integer) :: t
  @doc ~S"""
  Create a new `Bank.Note` struct using a default currency.
  The default currency can be set in the system Mix config.

  ## Example Config:

      config :note,
        default_currency: :USD

  ## Example:

      Bank.Note.new(123)
      %Bank.Note{amount: 123, currency: :USD}
  """
  def new(amount) do
    currency = Application.get_env(:note, :default_currency)
    if currency do
      new(amount, currency)
    else
      raise ArgumentError, "to use Bank.Note.new/1 you must set a default currency in your application config."
    end
  end

  @spec new(integer, atom | String.t) :: t
  @doc """
  Create a new `Bank.Note` struct from currency sub-units (cents)

  ## Example:

      iex> Bank.Note.new(1_000_00, :USD)
      %Bank.Note{amount: 1_000_00, currency: :USD}
  """
  def new(int, currency) when is_integer(int),
      do: %Bank.Note{amount: int, currency: Currency.to_atom(currency)}

  @spec parse(String.t | float, atom | String.t, Keyword.t) :: {:ok, t}
  @doc ~S"""
  Parse a value into a `Bank.Note` type.

  The following options are available:

    - `separator` - default `","`, sets the separator for groups of thousands.
      "1,000"
    - `delimeter` - default `"."`, sets the decimal delimeter.
      "1.23"

  ## Examples:

      iex> Bank.Note.parse("$1,234.56", :USD)
      {:ok, %Bank.Note{amount: 123456, currency: :USD}}
      iex> Bank.Note.parse("1.234,56", :EUR, separator: ".", delimeter: ",")
      {:ok, %Bank.Note{amount: 123456, currency: :EUR}}
      iex> Bank.Note.parse("1.234,56", :WRONG)
      :error
      iex> Bank.Note.parse(1_234.56, :USD)
      {:ok, %Bank.Note{amount: 123456, currency: :USD}}
      iex> Bank.Note.parse(-1_234.56, :USD)
      {:ok, %Bank.Note{amount: -123456, currency: :USD}}
  """
  def parse(value, currency \\ nil, opts \\ [])
  def parse(value, nil, opts) do
    currency = Application.get_env(:note, :default_currency)
    if currency do
      parse(value, currency, opts)
    else
      raise ArgumentError, "to use Bank.Note.new/1 you must set a default currency in your application config."
    end
  end
  def parse(str, currency, opts) when is_binary(str) do
    try do
      {_separator, delimeter} = get_parse_options(opts)
      value = str
              |> prepare_parse_string(delimeter)
              |> add_missing_leading_digit
      case Float.parse(value) do
        {float, _} -> parse(float, currency, [])
        :error -> :error
      end
    rescue
      _ -> :error
    end
  end
  def parse(float, currency, _opts) when is_float(float) do
    {:ok, new(round(float * 100), currency)}
  end

  defp prepare_parse_string(characters, delimeter, acc \\ [])
  defp prepare_parse_string([], _delimeter, acc),
       do: Enum.reverse(acc) |> Enum.join
  defp prepare_parse_string(["-" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["-" | acc])
  defp prepare_parse_string(["0" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["0" | acc])
  defp prepare_parse_string(["1" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["1" | acc])
  defp prepare_parse_string(["2" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["2" | acc])
  defp prepare_parse_string(["3" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["3" | acc])
  defp prepare_parse_string(["4" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["4" | acc])
  defp prepare_parse_string(["5" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["5" | acc])
  defp prepare_parse_string(["6" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["6" | acc])
  defp prepare_parse_string(["7" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["7" | acc])
  defp prepare_parse_string(["8" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["8" | acc])
  defp prepare_parse_string(["9" | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["9" | acc])
  defp prepare_parse_string([delimeter | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, ["." | acc])
  defp prepare_parse_string([_head | tail], delimeter, acc),
       do: prepare_parse_string(tail, delimeter, acc)

  defp prepare_parse_string(string, delimeter, _acc),
       do: prepare_parse_string(String.codepoints(string), delimeter)

  defp add_missing_leading_digit(<< "-." >> <> tail),
       do: "-0." <> tail
  defp add_missing_leading_digit(<< "." >> <> tail),
       do: "0." <> tail
  defp add_missing_leading_digit(str), do: str

  @spec parse(String.t | float, atom | String.t, Keyword.t) :: t
  @doc ~S"""
  Parse a value into a `Bank.Note` type.
  Similar to `parse/3` but returns a `%Bank.Note{}` or raises an error if parsing fails.

  ## Example:

      iex> Bank.Note.parse!("1,234.56", :USD)
      %Bank.Note{amount: 123456, currency: :USD}
      iex> Bank.Note.parse!("wrong", :USD)
      ** (ArgumentError) unable to parse "wrong"
  """
  def parse!(value, currency \\ nil, opts \\ []) do
    case parse(value, currency, opts) do
      {:ok, note} -> note
      :error -> raise ArgumentError, "unable to parse #{inspect(value)}"
    end
  end

  @spec compare(t, t) :: t
  @doc ~S"""
  Compares two `Bank.Note` structs with each other.
  They must each be of the same currency and then their amounts are compared

  ## Example:

      iex> Bank.Note.compare(Bank.Note.new(100, :USD), Bank.Note.new(100, :USD))
      0
      iex> Bank.Note.compare(Bank.Note.new(100, :USD), Bank.Note.new(101, :USD))
      -1
      iex> Bank.Note.compare(Bank.Note.new(101, :USD), Bank.Note.new(100, :USD))
      1
  """
  def compare(%Bank.Note{currency: cur} = a, %Bank.Note{currency: cur} = b) do
    case a.amount - b.amount do
      x when x >  0 -> 1
      x when x <  0 -> -1
      x when x == 0 -> 0
    end
  end
  def compare(a, b), do: fail_currencies_must_be_equal(a, b)

  @spec zero?(t) :: boolean
  @doc ~S"""
  Returns true if the amount of a `Bank.Note` struct is zero

  ## Example:

      iex> Bank.Note.zero?(Bank.Note.new(0, :USD))
      true
      iex> Bank.Note.zero?(Bank.Note.new(1, :USD))
      false
  """
  def zero?(%Bank.Note{amount: amount}) do
    amount == 0
  end

  @spec positive?(t) :: boolean
  @doc ~S"""
  Returns true if the amount of a `Bank.Note` is greater than zero

  ## Example:

      iex> Bank.Note.positive?(Bank.Note.new(0, :USD))
      false
      iex> Bank.Note.positive?(Bank.Note.new(1, :USD))
      true
      iex> Bank.Note.positive?(Bank.Note.new(-1, :USD))
      false
  """
  def positive?(%Bank.Note{amount: amount}) do
    amount > 0
  end

  @spec negative?(t) :: boolean
  @doc ~S"""
  Returns true if the amount of a `Bank.Note` is less than zero

  ## Example:

      iex> Bank.Note.negative?(Bank.Note.new(0, :USD))
      false
      iex> Bank.Note.negative?(Bank.Note.new(1, :USD))
      false
      iex> Bank.Note.negative?(Bank.Note.new(-1, :USD))
      true
  """
  def negative?(%Bank.Note{amount: amount}) do
    amount < 0
  end

  @spec equals?(t, t) :: boolean
  @doc ~S"""
  Returns true if two `Bank.Note` of the same currency have the same amount

  ## Example:

      iex> Bank.Note.equals?(Bank.Note.new(100, :USD), Bank.Note.new(100, :USD))
      true
      iex> Bank.Note.equals?(Bank.Note.new(101, :USD), Bank.Note.new(100, :USD))
      false
  """
  def equals?(%Bank.Note{amount: amount, currency: cur}, %Bank.Note{amount: amount, currency: cur}), do: true
  def equals?(%Bank.Note{currency: cur}, %Bank.Note{currency: cur}), do: false
  def equals?(a, b), do: fail_currencies_must_be_equal(a, b)

  @spec neg(t) :: t
  @doc ~S"""
  Returns a `Bank.Note` with the amount negated.

  ## Examples:

      iex> Bank.Note.new(100, :USD) |> Bank.Note.neg
      %Bank.Note{amount: -100, currency: :USD}
      iex> Bank.Note.new(-100, :USD) |> Bank.Note.neg
      %Bank.Note{amount: 100, currency: :USD}
  """
  def neg(%Bank.Note{amount: amount, currency: cur}),
      do: %Bank.Note{amount: -amount, currency: cur}

  @spec abs(t) :: t
  @doc ~S"""
  Returns a `Bank.Note` with the arithmetical absolute of the amount.

  ## Examples:

      iex> Bank.Note.new(-100, :USD) |> Bank.Note.abs
      %Bank.Note{amount: 100, currency: :USD}
      iex> Bank.Note.new(100, :USD) |> Bank.Note.abs
      %Bank.Note{amount: 100, currency: :USD}
  """
  def abs(%Bank.Note{amount: amount, currency: cur}),
      do: %Bank.Note{amount: Kernel.abs(amount), currency: cur}

  @spec add(t, t | integer | float) :: t
  @doc ~S"""
  Adds two `Bank.Note` together or an integer (cents) amount to a `Bank.Note`

  ## Example:

      iex> Bank.Note.add(Bank.Note.new(100, :USD), Bank.Note.new(50, :USD))
      %Bank.Note{amount: 150, currency: :USD}
      iex> Bank.Note.add(Bank.Note.new(100, :USD), 50)
      %Bank.Note{amount: 150, currency: :USD}
      iex> Bank.Note.add(Bank.Note.new(100, :USD), 5.55)
      %Bank.Note{amount: 655, currency: :USD}
  """
  def add(%Bank.Note{amount: a, currency: cur}, %Bank.Note{amount: b, currency: cur}),
      do: Bank.Note.new(a + b, cur)
  def add(%Bank.Note{amount: amount, currency: cur}, addend) when is_integer(addend),
      do: Bank.Note.new(amount + addend, cur)
  def add(%Bank.Note{} = m, addend) when is_float(addend),
      do: add(m, round(addend * 100))
  def add(a, b), do: fail_currencies_must_be_equal(a, b)

  @spec subtract(t, t | integer | float) :: t
  @doc ~S"""
  Subtracts one `Bank.Note` from another or an integer (cents) from a `Bank.Note`

  ## Example:

      iex> Bank.Note.subtract(Bank.Note.new(150, :USD), Bank.Note.new(50, :USD))
      %Bank.Note{amount: 100, currency: :USD}
      iex> Bank.Note.subtract(Bank.Note.new(150, :USD), 50)
      %Bank.Note{amount: 100, currency: :USD}
      iex> Bank.Note.subtract(Bank.Note.new(150, :USD), 1.25)
      %Bank.Note{amount: 25, currency: :USD}
  """
  def subtract(%Bank.Note{amount: a, currency: cur}, %Bank.Note{amount: b, currency: cur}),
      do: Bank.Note.new(a - b, cur)
  def subtract(%Bank.Note{amount: a, currency: cur}, subtractend) when is_integer(subtractend),
      do: Bank.Note.new(a - subtractend, cur)
  def subtract(%Bank.Note{} = m, subtractend) when is_float(subtractend),
      do: subtract(m, round(subtractend * 100))
  def subtract(a, b), do: fail_currencies_must_be_equal(a, b)

  @spec multiply(t, integer | float) :: t
  @doc ~S"""
  Multiplies a `Bank.Note` by an amount

  ## Example:
      iex> Bank.Note.multiply(Bank.Note.new(100, :USD), 10)
      %Bank.Note{amount: 1000, currency: :USD}
      iex> Bank.Note.multiply(Bank.Note.new(100, :USD), 1.5)
      %Bank.Note{amount: 150, currency: :USD}
  """
  def multiply(%Bank.Note{amount: amount, currency: cur}, multiplier) when is_integer(multiplier),
      do: Bank.Note.new(amount * multiplier, cur)
  def multiply(%Bank.Note{amount: amount, currency: cur}, multiplier) when is_float(multiplier),
      do: Bank.Note.new(round(amount * multiplier), cur)

  @spec divide(t, integer) :: [t]
  @doc ~S"""
  Divides up `Bank.Note` by an amount

  ## Example:
      iex> Bank.Note.divide(Bank.Note.new(100, :USD), 2)
      [%Bank.Note{amount: 50, currency: :USD}, %Bank.Note{amount: 50, currency: :USD}]
      iex> Bank.Note.divide(Bank.Note.new(101, :USD), 2)
      [%Bank.Note{amount: 51, currency: :USD}, %Bank.Note{amount: 50, currency: :USD}]
  """
  def divide(%Bank.Note{amount: amount, currency: cur}, denominator) when is_integer(denominator) do
    value = div(amount, denominator)
    rem   = rem(amount, denominator)
    do_divide(cur, value, rem, denominator, [])
  end

  defp do_divide(_currency, _value, _rem, 0, acc), do: acc |> Enum.reverse
  defp do_divide(currency, value, 0, count, acc) do
    count = decrement_abs(count)
    acc   = [new(value, currency) | acc]
    do_divide(currency, value, 0, count, acc)
  end
  defp do_divide(currency, value, rem, count, acc) do
    rem   = decrement_abs(rem)
    count = decrement_abs(count)
    acc   = [new(increment_abs(value), currency) | acc]
    do_divide(currency, value, rem, count, acc)
  end

  defp increment_abs(n) when n >= 0, do: n + 1
  defp increment_abs(n) when n < 0, do: n - 1
  defp decrement_abs(n) when n >= 0, do: n - 1
  defp decrement_abs(n) when n < 0, do: n + 1

  @spec to_string(t, Keyword.t) :: String.t
  @doc ~S"""
  Converts a `Bank.Note` struct to a string representation

  The following options are available:

    - `separator` - default `","`, sets the separator for groups of thousands.
      "1,000"
    - `delimeter` - default `"."`, sets the decimal delimeter.
      "1.23"
    - `symbol` - default `true`, sets whether to display the currency symbol or not.
    - `symbol_on_right` - default `false`, display the currency symbol on the right of the number, eg: 123.45€
    - `symbol_space` - default `false`, add a space between currency symbol and number, eg: € 123,45 or 123.45 €
    - `fractional_unit` - default `true`, show the remaining units after the delimeter

  ## Example:

      iex> Bank.Note.to_string(Bank.Note.new(123456, :GBP))
      "£1,234.56"
      iex> Bank.Note.to_string(Bank.Note.new(123456, :EUR), separator: ".", delimeter: ",")
      "€1.234,56"
      iex> Bank.Note.to_string(Bank.Note.new(123456, :EUR), symbol: false)
      "1,234.56"
      iex> Bank.Note.to_string(Bank.Note.new(123456, :EUR), symbol: false, separator: "")
      "1234.56"
      iex> Bank.Note.to_string(Bank.Note.new(123456, :EUR), fractional_unit: false)
      "€1,234"

  It can also be interpolated (It implements the String.Chars protocol)
  To control the formatting, you can use the above options in your config,
  more information is in the introduction to `Bank.Note`

  ## Example:

      iex> "Total: #{Bank.Note.new(100_00, :USD)}"
      "Total: $100.00"
  """
  def to_string(%Bank.Note{}=note, opts \\ []) do
    {separator, delimeter, symbol, symbol_on_right, symbol_space, fractional_unit} = get_display_options(note, opts)

    number = format_number(note, separator, delimeter, fractional_unit)
    sign = if negative?(note), do: "-"
    space = if symbol_space, do: " "

    parts = if symbol_on_right do
      [sign, number, space, symbol]
    else
      [symbol, space, sign, number]
    end
    parts |> Enum.join |> String.lstrip
  end

  defp format_number(%Bank.Note{amount: amount}, separator, delimeter, fractional_unit) do
    super_unit = div(Kernel.abs(amount), 100) |> Integer.to_string |> reverse_group(3) |> Enum.join(separator)
    sub_unit = rem(Kernel.abs(amount), 100) |> Integer.to_string |> String.rjust(2, ?0)
    if fractional_unit do
      [super_unit, sub_unit] |> Enum.join(delimeter)
    else
      super_unit
    end
  end

  defp get_display_options(m, opts) do
    {separator, delimeter} = get_parse_options(opts)

    default_symbol = Application.get_env(:note, :symbol, true)
    default_symbol_on_right = Application.get_env(:note, :symbol_on_right, false)
    default_symbol_space = Application.get_env(:note, :symbol_space, false)
    default_fractional_unit = Application.get_env(:note, :fractional_unit, true)

    symbol = if Keyword.get(opts, :symbol, default_symbol), do: Currency.symbol(m), else: ""
    symbol_on_right = Keyword.get(opts, :symbol_on_right, default_symbol_on_right)
    symbol_space = Keyword.get(opts, :symbol_space, default_symbol_space)
    fractional_unit = Keyword.get(opts, :fractional_unit, default_fractional_unit)

    {separator, delimeter, symbol, symbol_on_right, symbol_space, fractional_unit}
  end

  defp get_parse_options(opts) do
    default_separator = Application.get_env(:note, :separator, ",")
    separator = Keyword.get(opts, :separator, default_separator)
    default_delimeter = Application.get_env(:note, :delimeter, ".")
    delimeter = Keyword.get(opts, :delimeter, default_delimeter)
    {separator, delimeter}
  end

  defp fail_currencies_must_be_equal(a, b) do
    raise ArgumentError, message: "Currency of #{a.currency} must be the same as #{b.currency}"
  end

  defp reverse_group(str, count) when is_binary(str) do
    reverse_group(str, Kernel.abs(count), [])
  end
  defp reverse_group("", _count, list) do
    list
  end
  defp reverse_group(str, count, list) do
    {first, last} = String.split_at(str, -count)
    reverse_group(first, count, [last | list])
  end

  defimpl String.Chars do
    def to_string(%Bank.Note{} = m) do
      Bank.Note.to_string(m)
    end
  end
end
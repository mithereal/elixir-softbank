defmodule Bank.Currency do

  use Ecto.Schema

  import Ecto.Changeset

  alias Bank.Repo
  alias Bank.Currency


  @moduledoc false

  schema "bank_currencies" do
    field :name, :string
    field :value, :string
    field :symbol, :string

  end

  @params ~w(name value symbol)a
  @required_fields ~w(name value symbol)a



  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do

    struct
    |> cast(params,  @params)
    |> validate_required(@required_fields)

  end


end
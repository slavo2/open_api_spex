defmodule OpenApiSpex do
  @moduledoc """
  Provides the entry-points for defining schemas, validating and casting.
  """

  alias OpenApiSpex.{OpenApi, Operation, Reference, Schema, SchemaResolver}

  @doc """
  Adds schemas to the api spec from the modules specified in the Operations.

  Eg, if the response schema for an operation is defined with:

      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }

  Then the `UserResponse.schema()` function will be called to load the schema, and
  a `Reference` to the loaded schema will be used in the operation response.

  See `OpenApiSpex.schema` macro for a convenient syntax for defining schema modules.
  """
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end

  @doc """
  Cast params to conform to a Schema or Operation spec.
  """
  @spec cast(OpenApi.t, Schema.t | Reference.t | Operation.t, any) :: {:ok, any} | {:error, String.t}
  def cast(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.cast(schema, params, spec.components.schemas)
  end
  def cast(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.cast(schema, params, spec.components.schemas)
  end
  def cast(spec = %OpenApi{}, operation = %Operation{}, conn = %Plug.Conn{}, content_type \\ nil) do
    Operation.cast(operation, conn, content_type, spec.components.schemas)
  end

  @doc """
  Validate params against a Schema or Operation spec.
  """
  def validate(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end
  def validate(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end
  def validate(spec = %OpenApi{}, operation = %Operation{}, conn = %Plug.Conn{}, content_type \\ nil) do
    Operation.validate(operation, conn, content_type, spec.components.schemas)
  end

  @doc """
  Declares a OpenApiSpex Schema

   - defines the schema/0 callback
   - ensures the schema is linked to the module by "x-struct" extension property
   - defines a struct with keys matching the schema properties
   - defines a @type `t` for the struct
   - derives a `Poison.Encoder` for the struct

  ## Example

      require OpenApiSpex

      defmodule User do
        OpenApiSpex.schema %{
          title: "User",
          description: "A user of the app",
          type: :object,
          properties: %{
            id: %Schema{type: :integer, description: "User ID"},
            name:  %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
            email: %Schema{type: :string, description: "Email address", format: :email},
            inserted_at: %Schema{type: :string, description: "Creation timestamp", format: :'date-time'},
            updated_at: %Schema{type: :string, description: "Update timestamp", format: :'date-time'}
          },
          required: [:name, :email],
          example: %{
            "id" => 123,
            "name" => "Joe User",
            "email" => "joe@gmail.com",
            "inserted_at" => "2017-09-12T12:34:55Z",
            "updated_at" => "2017-09-13T10:11:12Z"
          }
        }
      end
  """
  defmacro schema(body) do
    quote do
      @behaviour OpenApiSpex.Schema
      @schema struct(OpenApiSpex.Schema, Map.put(unquote(body), :"x-struct",  __MODULE__))
      def schema, do: @schema
      @derive [Poison.Encoder]
      defstruct Schema.properties(@schema)
      @type t :: %__MODULE__{}
    end
  end
end

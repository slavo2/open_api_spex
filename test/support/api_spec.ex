defmodule OpenApiSpexTest.ApiSpec do
  alias OpenApiSpex.{OpenApi, Contact, License, Paths, Server, Info, Components}
  alias OpenApiSpexTest.{Router, Schemas}

  def spec() do
    %OpenApi{
      servers: [
        %Server{url: "http://example.com"},
      ],
      info: %Info{
        title: "A",
        version: "3.0",
        contact: %Contact{
          name: "joe",
          email: "Joe@gmail.com",
          url: "https://help.joe.com"
        },
        license: %License{
          name: "MIT",
          url: "http://mit.edu/license"
        }
      },
      components: %Components{
        schemas: %{
          "Pet" => Schemas.Pet.schema(),
          "Cat" => Schemas.Cat.schema(),
          "Dog" => Schemas.Dog.schema()
        }
      },
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end

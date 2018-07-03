.PHONY: debug, serve, clean

# Elixir server
serve: src/elixir/priv/static/main.js
	cd src/elixir && mix run --no-halt

# Elm debug build (history, import / export)
debug:
	cd src/elm && elm-make Main.elm --debug --output ../elixir/priv/static/main.js
	cd src/elixir && mix run --no-halt

src/elixir/priv/static/main.js: src/elm/*.elm
	cd src/elm && elm-make Main.elm --output ../elixir/priv/static/main.js

# Make-related
clean:
	-rm -f src/elixir/priv/static/main.js

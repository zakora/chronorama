.PHONY: debug, serve, pyserve, clean

# Elixir server
serve: src/elixir/priv/main.html
	cd src/elixir && mix run --no-halt

debug: src/elixir/priv/main.html
	cd src/elixir && iex -S mix

src/elixir/priv/main.html: src/elm/Main.elm
	cd src/elm && elm-make Main.elm --output ../elixir/priv/main.html

# Make-related
clean:
	-rm -f src/elixir/priv/main.html src/python/static/main.html

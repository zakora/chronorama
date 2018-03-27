.PHONY: debug, serve, pyserve

# Elixir server
serve: vizproxy/priv/main.html
	cd vizproxy && mix run --no-halt

debug: vizproxy/priv/main.html
	cd vizproxy && iex -S mix

vizproxy/priv/main.html: Main.elm
	elm-make Main.elm --output vizproxy/priv/main.html

# Python server
pyserve: main.html
	python -u serve.py

main.html: Mail.elm
	elm-make Main.elm --output main.html

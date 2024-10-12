fmt:
	echo "===> Formatting"
	stylua . --config-path=.stylua.toml

fmt-check:
	echo "===> Formatting"
	stylua --check . --config-path=.stylua.toml
lint:
	echo "===> Linting"
	luacheck . --globals vim

test:
	echo "===> Testing"
	nvim --headless -c "PlenaryBustedDirectory lua/enviread/tests"
ci:
	make fmt-check
	make lint
	make test


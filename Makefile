.PHONY: test test-file lint

test:
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run()"

test-file:
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

lint:
	luacheck lua/ plugin/ --globals vim --no-max-line-length

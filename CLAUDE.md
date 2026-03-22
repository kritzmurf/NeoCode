# NeoCode

A LeetCode **study system** for Neovim. Not another LeetCode client — NeoCode structures your practice with built-in study plans, local test execution, and progress tracking.

## What This Is

NeoCode differentiates from kawre/leetcode.nvim by focusing on the study layer:
- **Three-tier study plans**: Bundled community plans (Blind 75, NeetCode 150, Grind 75) + dynamic LeetCode plan fetching + user-defined custom plans
- **Local test runner**: Run solutions locally with instant feedback, no rate limits, works offline
- **Non-intrusive**: Works alongside existing buffers (no standalone-mode constraint)
- **Study-first navigation**: Plans drive the UI, not a raw problem list

## Architecture

- **Zero runtime dependencies**: Uses `vim.system()` for HTTP (Neovim 0.10+), native `vim.api` for UI. No nui.nvim, no plenary.nvim.
- **Cookie-based auth**: User exports `LEETCODE_SESSION` + `csrftoken` from browser into a config file
- **Local-first data**: Problem metadata cached as JSON. Works offline after initial sync.
- **Solutions as real files**: `~/.local/share/nvim/neocode/solutions/<slug>/<slug>.<ext>` — LSP and treesitter work naturally

## Project Structure

```
plugin/neocode.lua           -- auto-loaded entry point, :NeoCode command
lua/neocode/
  init.lua                   -- setup(), config merging
  config.lua                 -- default config table
  auth.lua                   -- cookie management, session validation
  commands.lua               -- :NeoCode subcommand dispatch
  keymaps.lua                -- buffer-local keymaps
  health.lua                 -- :checkhealth neocode
  utils.lua                  -- shared utilities
  storage.lua                -- file I/O, caching, directory management
  api/
    init.lua                 -- HTTP layer (graphql(), rest() via vim.system + curl)
    queries.lua              -- GraphQL query strings
    problems.lua             -- fetch problem details, code stubs, test cases
    submit.lua               -- submit to LeetCode, poll results
    user.lua                 -- user profile, stats
  ui/
    init.lua                 -- layout orchestrator (open/close workspace)
    description.lua          -- problem description buffer (rendered HTML)
    editor.lua               -- code editor buffer management
    results.lua              -- test/submission results floating window
    plan_view.lua            -- study plan browser buffer
    html.lua                 -- HTML-to-text renderer
  study/
    init.lua                 -- study plan engine (load, track, next problem)
    progress.lua             -- progress persistence (JSON)
    remote.lua               -- fetch LeetCode official study plans via GraphQL
    plans/
      blind75.lua            -- Blind 75 (bundled)
      neetcode150.lua        -- NeetCode 150 (bundled)
      grind75.lua            -- Grind 75 (bundled)
      loader.lua             -- unified plan loader (bundled + remote + custom)
  runner/
    init.lua                 -- local test runner orchestrator
    harness.lua              -- generate language-specific test harnesses
    languages/
      python.lua             -- Python test wrapper
      javascript.lua         -- JS/TS test wrapper
      cpp.lua                -- C++ test wrapper
      java.lua               -- Java test wrapper
      go.lua                 -- Go test wrapper
lua/telescope/_extensions/
  neocode.lua                -- Telescope picker (optional)
```

## Development Setup

Install the plugin locally via lazy.nvim:

```lua
-- In your lazy.nvim plugin spec (e.g., lua/patmurf/plugins/neocode.lua)
return {
  dir = "~/Documents/Projects/Lua/NeoCode",
  config = function()
    require("neocode").setup({})
  end,
  cmd = "NeoCode",
}
```

## Testing

- `:checkhealth neocode` — verify plugin health
- `:NeoCode auth` — validate LeetCode session
- Run Neovim headless to check for load errors: `nvim --headless -c "lua require('neocode')" -c "q"`

## Environment

- Neovim 0.11.6 with LuaJIT
- Python 3.14
- curl 8.19
- Plugin manager: lazy.nvim (plugins in `lua/patmurf/plugins/`, imported via `{ import = "patmurf.plugins" }`)
- User's Neovim config uses: Space as leader, jk for escape, 4-space tabs, splitright, tokyonight colorscheme

## Keymap Constraints

- `<leader>l` is taken by nvim-lint (trigger linting). NeoCode uses `<leader>lc*` prefix instead.
- `gd` is taken by LSP go-to-definition. Do NOT override `gd` in NeoCode buffers.
- `<C-h>` and `<C-l>` are free for pane navigation.
- Free leader prefixes: `<leader>lc*`, `<leader>n*`

## Conventions

- All Lua modules use the `local M = {} ... return M` pattern
- Async HTTP: `vim.system(cmd, {text=true}, function(obj) vim.schedule(function() ... end) end)`
- All user-facing notifications via `vim.notify("NeoCode: ...", vim.log.levels.INFO)`
- Buffer-local keymaps only — never set global keymaps
- User commands under `:NeoCode <subcommand>`
- Config uses `vim.tbl_deep_extend("force", defaults, user_opts)` for merging
- Storage paths via `vim.fn.stdpath("data") .. "/neocode"`
- No external dependencies — everything uses built-in Neovim APIs

## LeetCode API

- GraphQL endpoint: `POST https://leetcode.com/graphql/`
- Auth: `Cookie: LEETCODE_SESSION=...; csrftoken=...` + `X-Csrftoken: ...` headers
- Test execution: `POST /problems/{slug}/interpret_solution/`
- Submission: `POST /problems/{slug}/submit/`
- Result polling: `GET /submissions/detail/{id}/check/` with `vim.defer_fn` at 500ms intervals
- `Referer` header must match the problem URL for submit/run endpoints

## Implementation Phases

See the plan file at `.claude/plans/smooth-chasing-whisper.md` for the full phased implementation plan. Summary:

1. **Phase 1**: Skeleton, auth, bundled study plan data
2. **Phase 2**: Study plan browser + split workspace (description | editor)
3. **Phase 3**: Local test runner (Python first)
4. **Phase 4**: LeetCode submission + progress tracking
5. **Phase 5**: Telescope integration + stats dashboard
6. **Phase 6**: Dynamic LeetCode plans + polish

# NeoCode

A LeetCode **study system** for Neovim.

NeoCode isn't another LeetCode client. It's a structured practice tool that helps you work through curated problem sets, test solutions locally, and track your progress — all without leaving Neovim.

## Why NeoCode?

Plugins like [leetcode.nvim](https://github.com/kawre/leetcode.nvim) handle the LeetCode client experience well. NeoCode focuses on what they don't:

- **Built-in study plans** — Blind 75, NeetCode 150, and Grind 75 ship with the plugin. Browse by category, track completion, pick up where you left off.
- **Local test runner** — Run your solution against test cases locally. Instant feedback, no rate limits, works offline.
- **Non-intrusive** — Works alongside your existing buffers. No standalone mode required.
- **Zero dependencies** — Uses only built-in Neovim APIs (`vim.system()`, `vim.api`). No plenary, no nui.nvim.

## Requirements

- Neovim >= 0.10
- `curl` (for LeetCode API)
- `python3` (for local test runner)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "patmurf/NeoCode",
  config = function()
    require("neocode").setup({})
  end,
  cmd = "Neocode",
}
```

## Setup

### Authentication

NeoCode uses your browser cookies to authenticate with LeetCode. After logging into [leetcode.com](https://leetcode.com):

1. Open DevTools (`F12`) > Application > Cookies > `leetcode.com`
2. Copy the values for `LEETCODE_SESSION` and `csrftoken`
3. Create `~/.config/nvim/neocode_cookies`:

```
LEETCODE_SESSION=<your session value>
csrftoken=<your csrf value>
```

4. Verify with `:Neocode auth`

## Usage

### Study Plans

```vim
:Neocode plan blind75       " Browse the Blind 75
:Neocode plan neetcode150   " Browse the NeetCode 150
:Neocode plan grind75       " Browse the Grind 75
:Neocode plan list          " List available plans
```

### Problem Workflow

```vim
:Neocode open two-sum       " Open a problem (description + editor split)
:Neocode next               " Next unsolved problem in active plan
:Neocode close              " Close workspace
:Neocode lang python3       " Switch language
```

### Testing & Submission

```vim
:Neocode test               " Run locally (instant, offline)
:Neocode run                " Run on LeetCode server
:Neocode submit             " Submit to LeetCode
```

### Progress

```vim
:Neocode progress           " Study plan progress
:Neocode stats              " LeetCode stats dashboard
```

## Configuration

```lua
require("neocode").setup({
  lang = "python3",                                      -- default language
  domain = "leetcode.com",                               -- or "leetcode.cn"
  storage_dir = vim.fn.stdpath("data") .. "/neocode",    -- solution & cache storage
  cookie_path = vim.fn.stdpath("config") .. "/neocode_cookies",
  active_plan = "blind75",                               -- default study plan
  ui = {
    description_width = 0.4,                             -- fraction of screen
  },
})
```

## Keybindings

Buffer-local keymaps, only active in NeoCode windows:

| Key | Context | Action |
|---|---|---|
| `<CR>` | plan browser | Open selected problem |
| `<Tab>` | plan browser | Toggle category fold |
| `n` | plan browser | Jump to next unsolved |
| `q` | any NeoCode buffer | Close current view |
| `<C-h>` / `<C-l>` | split workspace | Move between description and editor |
| `]]` / `[[` | description | Next / previous example |
| `<leader>lct` | editor | Run local tests |
| `<leader>lcr` | editor | Run on LeetCode |
| `<leader>lcs` | editor | Submit to LeetCode |
| `<leader>lce` | editor | Edit test cases |

## Health Check

```vim
:checkhealth neocode
```

## Roadmap

- [x] Plugin skeleton and configuration
- [x] LeetCode authentication (cookie-based)
- [x] Bundled study plans (Blind 75, NeetCode 150, Grind 75)
- [x] Progress tracking
- [x] Study plan browser UI
- [x] Split workspace (description + editor)
- [x] Local test runner (Python)
- [ ] LeetCode submission + result polling
- [ ] Telescope integration
- [ ] Stats dashboard
- [ ] Dynamic LeetCode plan fetching
- [ ] Custom user-defined plans
- [ ] Additional language support for local runner

## Acknowledgments

- [kawre/leetcode.nvim](https://github.com/kawre/leetcode.nvim) — Prior art and inspiration for the LeetCode API integration patterns
- [NeetCode](https://neetcode.io) — NeetCode 150 problem list
- [Tech Interview Handbook](https://www.techinterviewhandbook.org) — Blind 75 and Grind 75 problem lists

## License

MIT

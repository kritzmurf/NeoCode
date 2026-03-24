local M = {}

function M.generate_harness(solution_path, meta, test_cases, expected_outputs)
  local solution_dir = vim.fn.fnamemodify(solution_path, ":h")
  local solution_file = vim.fn.fnamemodify(solution_path, ":t:r")
  local func_name = meta.name

  local lines = {
    "import sys, json",
    "sys.path.insert(0, " .. vim.json.encode(solution_dir) .. ")",
    "from " .. solution_file:gsub("-", "_") .. " import Solution",
    "",
    "s = Solution()",
    "tests = " .. vim.json.encode(test_cases),
    "expected = " .. vim.json.encode(expected_outputs),
    "",
    "for i, test in enumerate(tests):",
    "    args = []",
    "    for line in test.strip().split('\\n'):",
    "        val = line.strip()",
    "        try:",
    "            val = json.loads(val)",
    "        except Exception:",
    "            pass",
    "        args.append(val)",
    "    try:",
    "        result = s." .. func_name .. "(*args)",
    "        exp = None",
    "        if i < len(expected):",
    "            try:",
    "                exp = json.loads(expected[i])",
    "            except Exception:",
    "                exp = expected[i]",
    "        passed = False",
    "        if exp is not None:",
    "            if isinstance(result, list) and isinstance(exp, list):",
    "                passed = sorted(result) == sorted(exp)",
    "            else:",
    "                passed = result == exp",
    "        print(json.dumps({'test': i + 1, 'passed': passed, 'input': test.strip(), 'expected': exp, 'actual': result}))",
    "    except Exception as e:",
    "        print(json.dumps({'test': i + 1, 'passed': False, 'input': test.strip(), 'expected': None, 'actual': str(e), 'error': True}))",
  }

  local tmp = os.tmpname() .. ".py"
  local f = io.open(tmp, "w")
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()
  return tmp
end

function M.run_command(harness_path)
  return { "python3", harness_path }
end

return M

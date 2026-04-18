local M = {}

local entities = {
  ["&amp;"] = "&",
  ["&lt;"] = "<",
  ["&gt;"] = ">",
  ["&quot;"] = '"',
  ["&apos;"] = "'",
  ["&#39;"] = "'",
  ["&nbsp;"] = " ",
  ["&ndash;"] = "-",
  ["&mdash;"] = "--",
  ["&laquo;"] = "<<",
  ["&raquo;"] = ">>",
  ["&times;"] = "x",
  ["&divide;"] = "/",
  ["&le;"] = "<=",
  ["&ge;"] = ">=",
  ["&ne;"] = "!=",
  ["&hellip;"] = "...",
  ["&rarr;"] = "->",
  ["&larr;"] = "<-",
  ["&infin;"] = "inf",
}

local function decode_entities(text)
  text = text:gsub("&#(%d+);", function(n)
    return string.char(tonumber(n))
  end)
  for entity, char in pairs(entities) do
    text = text:gsub(entity, char)
  end
  return text
end

function M.to_lines(html)
  if not html or html == "" then
    return { "(No description available)" }
  end

  local lines = {}
  local current_line = ""
  local in_pre = false
  local ol_counter = 0

  local function flush()
    if current_line ~= "" then
      table.insert(lines, decode_entities(current_line))
      current_line = ""
    end
  end

  local function add_blank()
    flush()
    if #lines > 0 and lines[#lines] ~= "" then
      table.insert(lines, "")
    end
  end

  local pos = 1
  while pos <= #html do
    local tag_start = html:find("<", pos, true)

    if not tag_start then
      current_line = current_line .. html:sub(pos)
      break
    end

    if tag_start > pos then
      local text = html:sub(pos, tag_start - 1)
      if in_pre then
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
          table.insert(lines, decode_entities(line))
        end
        if #lines > 0 then
          lines[#lines] = nil
          current_line = decode_entities(text:match("[^\n]*$") or "")
        end
      else
        text = text:gsub("%s+", " ")
        current_line = current_line .. text
      end
    end

    local tag_end = html:find(">", tag_start, true)
    if not tag_end then
      break
    end

    local tag = html:sub(tag_start + 1, tag_end - 1):lower()
    local tag_name = tag:match("^/?([%w]+)")

    if tag_name == "p" or tag_name == "div" then
      add_blank()
    elseif tag_name == "br" then
      flush()
    elseif tag_name == "pre" then
      if tag:sub(1, 1) == "/" then
        flush()
        in_pre = false
        add_blank()
      else
        add_blank()
        in_pre = true
      end
    elseif tag_name == "ul" or tag_name == "ol" then
      if tag:sub(1, 1) == "/" then
        add_blank()
        ol_counter = 0
      else
        add_blank()
        if tag_name == "ol" then
          ol_counter = 0
        end
      end
    elseif tag_name == "li" then
      if tag:sub(1, 1) ~= "/" then
        flush()
        if ol_counter > 0 then
          ol_counter = ol_counter + 1
          current_line = "  " .. ol_counter .. ". "
        else
          current_line = "  - "
        end
      else
        flush()
      end
    elseif tag_name == "sup" then
      if tag:sub(1, 1) ~= "/" then
        current_line = current_line .. "^"
      end
    elseif tag_name == "sub" then
      if tag:sub(1, 1) ~= "/" then
        current_line = current_line .. "_"
      end
    end

    pos = tag_end + 1
  end

  flush()

  -- Split any lines that contain embedded newlines (e.g. from &#10; entities)
  local clean = {}
  for _, line in ipairs(lines) do
    if line:find("\n", 1, true) then
      for sub in (line .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(clean, sub)
      end
    else
      table.insert(clean, line)
    end
  end
  lines = clean

  while #lines > 0 and lines[1] == "" do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end

  return lines
end

return M

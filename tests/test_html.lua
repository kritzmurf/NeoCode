local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local html = require("neocode.ui.html")

local T = new_set()

-- Empty / nil input
T["nil input"] = function()
  eq(html.to_lines(nil), { "(No description available)" })
end

T["empty string"] = function()
  eq(html.to_lines(""), { "(No description available)" })
end

-- Plain text
T["plain text passthrough"] = function()
  eq(html.to_lines("Hello world"), { "Hello world" })
end

-- Named entities
T["entities"] = new_set()

T["entities"]["&amp; decodes to &"] = function()
  eq(html.to_lines("a &amp; b"), { "a & b" })
end

T["entities"]["&lt; and &gt;"] = function()
  eq(html.to_lines("&lt;tag&gt;"), { "<tag>" })
end

T["entities"]["&quot; decodes to double quote"] = function()
  eq(html.to_lines('say &quot;hi&quot;'), { 'say "hi"' })
end

T["entities"]["&apos; decodes to single quote"] = function()
  eq(html.to_lines("it&apos;s"), { "it's" })
end

T["entities"]["&#39; numeric entity"] = function()
  eq(html.to_lines("it&#39;s"), { "it's" })
end

T["entities"]["&#65; numeric to A"] = function()
  eq(html.to_lines("&#65;&#66;&#67;"), { "ABC" })
end

T["entities"]["&hellip; to ..."] = function()
  eq(html.to_lines("wait&hellip;"), { "wait..." })
end

T["entities"]["&rarr; and &larr;"] = function()
  eq(html.to_lines("left &larr; right &rarr;"), { "left <- right ->" })
end

T["entities"]["&nbsp; to space"] = function()
  eq(html.to_lines("a&nbsp;b"), { "a b" })
end

T["entities"]["&ndash; and &mdash;"] = function()
  eq(html.to_lines("a&ndash;b&mdash;c"), { "a-b--c" })
end

T["entities"]["&le; &ge; &ne;"] = function()
  eq(html.to_lines("x &le; y &ge; z &ne; w"), { "x <= y >= z != w" })
end

T["entities"]["&times; and &divide;"] = function()
  eq(html.to_lines("2 &times; 3 &divide; 1"), { "2 x 3 / 1" })
end

T["entities"]["&infin;"] = function()
  eq(html.to_lines("&infin;"), { "inf" })
end

-- Block tags
T["tags"] = new_set()

T["tags"]["<p> creates blank line between paragraphs"] = function()
  local result = html.to_lines("<p>First</p><p>Second</p>")
  eq(result, { "First", "", "Second" })
end

T["tags"]["<div> behaves like <p>"] = function()
  local result = html.to_lines("<div>First</div><div>Second</div>")
  eq(result, { "First", "", "Second" })
end

T["tags"]["<br> creates line break"] = function()
  local result = html.to_lines("line one<br>line two")
  eq(result, { "line one", "line two" })
end

T["tags"]["<br/> self-closing"] = function()
  local result = html.to_lines("a<br/>b")
  eq(result, { "a", "b" })
end

-- Pre blocks
T["pre"] = new_set()

T["pre"]["preserves whitespace"] = function()
  local result = html.to_lines("<pre>  two spaces\n    four spaces</pre>")
  local found_indented = false
  for _, line in ipairs(result) do
    if line:match("^    four") then
      found_indented = true
    end
  end
  eq(found_indented, true)
end

T["pre"]["preserves newlines"] = function()
  local result = html.to_lines("<pre>line1\nline2\nline3</pre>")
  local count = 0
  for _, line in ipairs(result) do
    if line ~= "" then
      count = count + 1
    end
  end
  eq(count >= 3, true)
end

-- Lists
T["lists"] = new_set()

T["lists"]["unordered list with bullet prefix"] = function()
  local result = html.to_lines("<ul><li>Apple</li><li>Banana</li></ul>")
  local bullets = {}
  for _, line in ipairs(result) do
    if line:match("^  %- ") then
      table.insert(bullets, line)
    end
  end
  eq(#bullets, 2)
  eq(bullets[1], "  - Apple")
  eq(bullets[2], "  - Banana")
end

-- NOTE: ol_counter bug — <ol> sets counter to 0, but <li> only numbers
-- when counter > 0, so ordered lists render as unordered bullets.
-- This test documents current behavior; fix the bug in html.lua separately.
T["lists"]["ordered list renders as bullets (known bug)"] = function()
  local result = html.to_lines("<ol><li>First</li><li>Second</li><li>Third</li></ol>")
  local bullets = {}
  for _, line in ipairs(result) do
    if line:match("^  %- ") then
      table.insert(bullets, line)
    end
  end
  eq(#bullets, 3)
end

-- Superscript / subscript
T["sup/sub"] = new_set()

T["sup/sub"]["<sup> inserts caret"] = function()
  local result = html.to_lines("2<sup>10</sup>")
  eq(result, { "2^10" })
end

T["sup/sub"]["<sub> inserts underscore"] = function()
  local result = html.to_lines("a<sub>i</sub>")
  eq(result, { "a_i" })
end

-- Whitespace handling
T["whitespace"] = new_set()

T["whitespace"]["collapses spaces in text between tags"] = function()
  local result = html.to_lines("<p>hello    world</p>")
  eq(result, { "hello world" })
end

T["whitespace"]["strips leading blank lines"] = function()
  local result = html.to_lines("<p></p><p>Content</p>")
  eq(result[1], "Content")
end

T["whitespace"]["strips trailing blank lines"] = function()
  local result = html.to_lines("<p>Content</p><p></p>")
  eq(result[#result], "Content")
end

-- Unknown tags
T["unknown tags ignored, text preserved"] = function()
  local result = html.to_lines("<strong>bold</strong> and <em>italic</em>")
  eq(result, { "bold and italic" })
end

-- Edge cases
T["edge"] = new_set()

T["edge"]["unclosed < at end"] = function()
  local result = html.to_lines("text<")
  eq(type(result), "table")
end

T["edge"]["tag with no closing >"] = function()
  local result = html.to_lines("text<br")
  eq(type(result), "table")
end

-- Real LeetCode snippet
T["real leetcode description"] = function()
  local input = '<p>Given an array of integers <code>nums</code>&nbsp;and an integer '
    .. '<code>target</code>, return <em>indices of the two numbers such that '
    .. "they add up to <code>target</code></em>.</p>\n"
    .. "<p>You may assume that each input would have "
    .. "<strong><em>exactly</em> one solution</strong>.</p>"
  local result = html.to_lines(input)
  eq(#result >= 2, true)
  local full = table.concat(result, " ")
  eq(full:find("Given an array") ~= nil, true)
  eq(full:find("indices of the two numbers") ~= nil, true)
end

return T

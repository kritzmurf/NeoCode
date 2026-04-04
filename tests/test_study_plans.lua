local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

local plan_files = {
  { slug = "blind75", module = "neocode.study.plans.blind75", min_problems = 65 },
  { slug = "neetcode150", module = "neocode.study.plans.neetcode150", min_problems = 140 },
  { slug = "grind75", module = "neocode.study.plans.grind75", min_problems = 65 },
}

local valid_difficulties = { Easy = true, Medium = true, Hard = true }

for _, pf in ipairs(plan_files) do
  T[pf.slug] = new_set()
  local plan = require(pf.module)

  T[pf.slug]["has name"] = function()
    eq(type(plan.name), "string")
    eq(#plan.name > 0, true)
  end

  T[pf.slug]["has slug"] = function()
    eq(type(plan.slug), "string")
    eq(plan.slug, pf.slug)
  end

  T[pf.slug]["has description"] = function()
    eq(type(plan.description), "string")
    eq(#plan.description > 0, true)
  end

  T[pf.slug]["has non-empty categories"] = function()
    eq(type(plan.categories), "table")
    eq(#plan.categories > 0, true)
  end

  T[pf.slug]["categories have names and problems"] = function()
    for i, cat in ipairs(plan.categories) do
      eq(type(cat.name), "string")
      eq(#cat.name > 0, true)
      eq(type(cat.problems), "table")
      if #cat.problems == 0 then
        error("Category " .. i .. " (" .. cat.name .. ") has no problems")
      end
    end
  end

  T[pf.slug]["problems have required fields"] = function()
    for _, cat in ipairs(plan.categories) do
      for _, p in ipairs(cat.problems) do
        eq(type(p.id), "number")
        eq(p.id > 0, true)
        eq(type(p.title), "string")
        eq(#p.title > 0, true)
        eq(type(p.slug), "string")
        eq(#p.slug > 0, true)
        eq(type(p.difficulty), "string")
        if not valid_difficulties[p.difficulty] then
          error("Invalid difficulty '" .. p.difficulty .. "' on problem " .. p.slug)
        end
      end
    end
  end

  T[pf.slug]["slugs are lowercase kebab-case"] = function()
    for _, cat in ipairs(plan.categories) do
      for _, p in ipairs(cat.problems) do
        if p.slug:match("[A-Z]") then
          error("Slug contains uppercase: " .. p.slug)
        end
        if p.slug:match("[^a-z0-9%-]") then
          error("Slug contains invalid chars: " .. p.slug)
        end
      end
    end
  end

  T[pf.slug]["meets minimum problem count"] = function()
    local total = 0
    local seen = {}
    for _, cat in ipairs(plan.categories) do
      for _, p in ipairs(cat.problems) do
        if not seen[p.slug] then
          seen[p.slug] = true
          total = total + 1
        end
      end
    end
    eq(total >= pf.min_problems, true)
  end
end

return T

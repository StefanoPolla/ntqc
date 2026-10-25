-- Publication date and last update in the title block of every web page (the author is
-- set for all pages in _quarto.yml).
-- Published: the first commit of the page on the gh-pages branch, following renames, so it
-- restarts when the notes move to a new repository (today if never published).
-- Last updated: the last commit of the page's source, of the files it includes, and of
-- the paths listed under `page-sources` in its front matter (today if any of them has
-- uncommitted changes). Both come from git; the PDF keeps the book's own date.
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August",
                 "September", "October", "November", "December" }

local function long_date(iso)  -- 2026-10-25 -> 25 October 2026
  local y, m, d = iso:match("^(%d+)-(%d+)-(%d+)$")
  if not y then return iso end
  return tonumber(d) .. " " .. MONTHS[tonumber(m)] .. " " .. y
end

local function git(args)
  local ok, out = pcall(pandoc.pipe, "git", args, "")
  if not ok then return "" end
  return (out:gsub("%s+$", ""))
end

local function sources(input, meta)
  local dir = pandoc.path.directory(input)
  local list = { pandoc.path.filename(input) }
  local f = io.open(input)
  if f then
    for inc in f:read("a"):gmatch("{{<%s*include%s+(%S+)%s*>}}") do
      table.insert(list, inc)
    end
    f:close()
  end
  for _, p in ipairs(meta["page-sources"] or {}) do
    table.insert(list, pandoc.utils.stringify(p))
  end
  return dir, list
end

local function published(dir, input)
  local page = pandoc.path.split_extension(pandoc.path.filename(input)) .. ".html"
  for _, ref in ipairs({ "origin/gh-pages", "gh-pages" }) do
    if git({ "-C", dir, "rev-parse", "--verify", "-q", ref }) ~= "" then
      local log = git({ "-C", dir, "log", "--follow", "--format=%cs", ref, "--", ":(top)" .. page })
      local first = log:match("(%S+)$")
      if first then return first end
    end
  end
  return nil
end

function Meta(meta)
  if not quarto.doc.is_format("html") then return nil end
  local input = quarto.doc.input_file
  if not input then return nil end
  local dir, list = sources(input, meta)
  local today = os.date("%Y-%m-%d")
  meta.date = long_date(published(dir, input) or today)
  local args = { "-C", dir, "status", "--porcelain", "--" }
  for _, p in ipairs(list) do table.insert(args, p) end
  if git(args) ~= "" then
    meta["date-modified"] = long_date(today)
  else
    args = { "-C", dir, "log", "-1", "--format=%cs", "--" }
    for _, p in ipairs(list) do table.insert(args, p) end
    local last = git(args)
    meta["date-modified"] = long_date(last ~= "" and last or today)
  end
  return meta
end

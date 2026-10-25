-- Tutorial table: write ::: {#tutorial-table} ::: in the text (index.qmd).
-- Built at render time from ../tutorials/tutorial-NN/ (student notebook *_qiskit.ipynb,
-- solutions *_qiskit_solutions.ipynb) and the page's `tutorial-dates` metadata, so the
-- table updates itself when a notebook is added. Each notebook gets an Open-in-Colab
-- link (base URL from _variables.yml) and a download link to the copy that
-- copy_notebooks.py puts in downloads/ (absolute site-url in the PDF). tools/release.py
-- rewrites both URLs on release.
local dates = {}

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("a")
  f:close()
  return text
end

local function colab_base(project)
  local vars = "\n" .. (read_file(project .. "/_variables.yml") or "")
  return vars:match("\ncolab:%s*(%S+)")
end

local function site_url(project)
  local yml = "\n" .. (read_file(project .. "/_quarto.yml") or "")
  return ((yml:match("\n%s*site%-url:%s*(%S+)") or ""):gsub("/$", ""))
end

-- "# Tutorial 1: circuits, simulators and sampling (Qiskit)" -> "Circuits, simulators and sampling"
local function topic(path)
  local ok, nb = pcall(pandoc.json.decode, read_file(path) or "")
  if not ok or type(nb) ~= "table" then return nil end
  for _, cell in ipairs(nb.cells or {}) do
    if cell.cell_type == "markdown" then
      local src = type(cell.source) == "table" and table.concat(cell.source) or cell.source
      local h = src:match("^#%s+([^\n]+)")
      if h then
        h = h:gsub("^Tutorial%s+%d+:%s*", ""):gsub("%s*%([%w%s]+%)%s*$", "")
        return h:sub(1, 1):upper() .. h:sub(2)
      end
    end
  end
end

local function notebooks(dir)
  local ok, entries = pcall(pandoc.system.list_directory, dir)
  local student, solutions
  if ok then
    for _, f in ipairs(entries) do
      if f:match("_qiskit_solutions%.ipynb$") then solutions = f
      elseif f:match("_qiskit%.ipynb$") then student = f end
    end
  end
  return student, solutions
end

local function cell(inlines) return { pandoc.Plain(inlines) } end
local function nbsp(s) return (s:gsub(" ", "\u{A0}")) end

local function table_div(el)
  if el.identifier ~= "tutorial-table" then return nil end
  local project = quarto.project.directory
  local base, site = colab_base(project), site_url(project)
  local tutorials = project .. "/../tutorials"
  local rows, n = {}, #dates
  for i = 1, 20 do
    if notebooks(string.format("%s/tutorial-%02d", tutorials, i)) then n = math.max(n, i) end
  end
  for i = 1, n do
    local folder = string.format("tutorial-%02d", i)
    local student, solutions = notebooks(tutorials .. "/" .. folder)
    local function link(file)
      local colab = base .. "/tutorials/" .. folder .. "/" .. file
      local download = "downloads/" .. folder .. "/" .. file
      if not quarto.doc.is_format("html") then download = site .. "/" .. download end
      return cell {
        pandoc.Link("Colab", colab), pandoc.Str("\u{A0}·"), pandoc.Space(),
        pandoc.Link("Download", download, "", pandoc.Attr("", {}, { download = file })),
      }
    end
    table.insert(rows, {
      cell { pandoc.Str("T" .. i) },
      cell { pandoc.Str(nbsp(dates[i] or "")) },
      cell { pandoc.Str(student and topic(tutorials .. "/" .. folder .. "/" .. student) or "") },
      student and link(student) or cell { pandoc.Emph(nbsp("not yet released")) },
      solutions and link(solutions) or cell { pandoc.Emph(nbsp("after the tutorial")) },
    })
  end
  local header = {}
  for _, h in ipairs { "Tutorial", "Date", "Topic", "Notebook", "Solutions" } do
    table.insert(header, cell { pandoc.Str(h) })
  end
  local simple = pandoc.SimpleTable({}, { "AlignLeft", "AlignLeft", "AlignLeft", "AlignLeft", "AlignLeft" },
    { 0, 0, 0, 0, 0 }, header, rows)
  return pandoc.utils.from_simple_table(simple)
end

return {
  { Meta = function(meta)
      for _, d in ipairs(meta["tutorial-dates"] or {}) do
        table.insert(dates, pandoc.utils.stringify(d))
      end
    end },
  { Div = table_div },
}

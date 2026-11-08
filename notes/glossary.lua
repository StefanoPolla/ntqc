-- Glossary terms: write [Pauli strings]{.gloss key="pauli-string"} in the text.
-- HTML: a hover tooltip (tippy, already bundled with Quarto) linking to the glossary.
-- PDF: the term is set in italics, and the glossary appendix lists all entries.
-- A div with id "glossary-list" is replaced by the full, sorted list.
-- An entry with `ref: def-name` (a definition box in some chapter) links to that
-- definition instead of the glossary, in HTML and PDF, keeping the tooltip; inside its
-- own definition box, the term still links to the glossary.
local glossary = {}
local ref_files = nil  -- definition id -> chapter .html, found by scanning the .qmd files

local function ref_file(ref)
  if not ref_files then
    ref_files = {}
    local dir = quarto.project.directory or "."
    for _, name in ipairs(pandoc.system.list_directory(dir)) do
      if name:match("%.qmd$") then
        local f = io.open(pandoc.path.join({ dir, name }), "r")
        if f then
          local text = f:read("a")
          f:close()
          for id in text:gmatch("{#(def%-[%w%-]+)}") do
            ref_files[id] = name:gsub("%.qmd$", ".html")
          end
        end
      end
    end
  end
  return ref_files[ref]
end

local function read_meta(meta)
  for key, entry in pairs(meta.glossary or {}) do
    glossary[key] = {
      term = pandoc.utils.stringify(entry.term),
      def = pandoc.utils.stringify(entry.def),
      ref = entry.ref and pandoc.utils.stringify(entry.ref) or nil,
    }
  end
end

local function span(el)
  if not el.classes:includes("gloss") then return nil end
  local key = el.attributes.key
  local entry = glossary[key]
  if not entry then
    io.stderr:write("glossary: unknown key " .. tostring(key) .. "\n")
    return nil
  end
  local ref = entry.ref
  if el.attributes["in-own-def"] then ref = nil end
  if quarto.doc.is_format("html") then
    local target = "glossary.html#gloss-" .. key
    if ref then
      local file = ref_file(ref)
      if not file then
        io.stderr:write("glossary: no definition " .. ref .. " for key " .. key .. "\n")
      elseif file == pandoc.path.filename(quarto.doc.input_file):gsub("%.qmd$", ".html") then
        target = "#" .. ref
      else
        target = file .. "#" .. ref
      end
    end
    local link = pandoc.Link(el.content, target)
    link.attributes["data-gloss"] = entry.def
    link.classes = { "gloss" }
    return link
  end
  if ref then return pandoc.Link({ pandoc.Emph(el.content) }, "#" .. ref) end
  return pandoc.Emph(el.content)
end

-- Mark the terms inside their own definition box, which keep the glossary link.
local function own_def(el)
  if el.identifier == "" then return nil end
  return el:walk {
    Span = function(sp)
      local entry = sp.classes:includes("gloss") and glossary[sp.attributes.key]
      if entry and entry.ref == el.identifier then
        sp.attributes["in-own-def"] = "1"
        return sp
      end
    end,
  }
end

local function list(el)
  if el.identifier ~= "glossary-list" then return nil end
  local keys = {}
  for k in pairs(glossary) do table.insert(keys, k) end
  table.sort(keys, function(a, b) return glossary[a].term:lower() < glossary[b].term:lower() end)
  local items = {}
  for _, k in ipairs(keys) do
    local term = pandoc.Span(pandoc.Str(glossary[k].term), { id = "gloss-" .. k })
    table.insert(items, { { term }, { pandoc.Plain(pandoc.Str(glossary[k].def)) } })
  end
  return pandoc.DefinitionList(items)
end

return {
  { Meta = read_meta },
  { Div = own_def },
  { Span = span, Div = list },
}

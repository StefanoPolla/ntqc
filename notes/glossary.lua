-- Glossary terms: write [Pauli strings]{.gloss key="pauli-string"} in the text.
-- HTML: a hover tooltip (tippy, already bundled with Quarto) linking to the glossary.
-- PDF: the term is set in italics, and the glossary appendix lists all entries.
-- A div with id "glossary-list" is replaced by the full, sorted list.
local glossary = {}

local function read_meta(meta)
  for key, entry in pairs(meta.glossary or {}) do
    glossary[key] = {
      term = pandoc.utils.stringify(entry.term),
      def = pandoc.utils.stringify(entry.def),
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
  if quarto.doc.is_format("html") then
    local link = pandoc.Link(el.content, "glossary.html#gloss-" .. key)
    link.attributes["data-gloss"] = entry.def
    link.classes = { "gloss" }
    return link
  end
  return pandoc.Emph(el.content)
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
  { Span = span, Div = list },
}

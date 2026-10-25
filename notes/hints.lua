-- Hints in exercises: write ::: {.hint} ... ::: (indented inside a list item for a hint
-- to one part). On the web the hint is hidden behind a "Hint" button (<details>); in
-- the PDF it is printed after the text, starting with "Hint:".
local function hint(el)
  if not el.classes:includes("hint") then return nil end
  if quarto.doc.is_format("html") then
    local out = pandoc.Blocks { pandoc.RawBlock("html", '<details class="hint"><summary>Hint</summary>') }
    out:extend(el.content)
    out:insert(pandoc.RawBlock("html", "</details>"))
    return out
  end
  local blocks = pandoc.Blocks(el.content)
  if blocks[1] and (blocks[1].t == "Para" or blocks[1].t == "Plain") then
    blocks[1].content:insert(1, pandoc.Emph { pandoc.Str("Hint:") })
    blocks[1].content:insert(2, pandoc.Space())
  end
  return blocks
end

return { { Div = hint } }

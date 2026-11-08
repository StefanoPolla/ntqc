-- Worked examples in the text: write ::: {.example} ... ::: around the paragraph(s).
-- Unnumbered and without a title, lighter than a definition box: the first paragraph
-- starts with an italic "Example." and a thin bar on the left marks where the example
-- ends (web: styles.css; PDF: the ntqcexample environment of preamble.tex).
local function example(el)
  if not el.classes:includes("example") then return nil end
  local blocks = pandoc.Blocks(el.content)
  if blocks[1] and (blocks[1].t == "Para" or blocks[1].t == "Plain") then
    blocks[1].content:insert(1, pandoc.Emph { pandoc.Str("Example.") })
    blocks[1].content:insert(2, pandoc.Space())
  end
  if quarto.doc.is_format("latex") then
    local out = pandoc.Blocks { pandoc.RawBlock("latex", "\\begin{ntqcexample}") }
    out:extend(blocks)
    out:insert(pandoc.RawBlock("latex", "\\end{ntqcexample}"))
    return out
  end
  el.content = blocks
  return el
end

return { { Div = example } }

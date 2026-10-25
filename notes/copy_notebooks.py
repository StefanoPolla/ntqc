"""Pre-render step: copy the tutorial notebooks into downloads/, so that the site can
offer them as direct downloads (tutorials.lua links to them). downloads/ is git-ignored
and rebuilt on every render; _quarto.yml publishes it as a resource."""
import shutil
from pathlib import Path

notes = Path(__file__).resolve().parent
target = notes / "downloads"
shutil.rmtree(target, ignore_errors=True)
for nb in sorted((notes.parent / "tutorials").glob("tutorial-*/*.ipynb")):
    dest = target / nb.parent.name / nb.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(nb, dest)

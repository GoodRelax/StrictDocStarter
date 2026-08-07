"""Re-take every screenshot in samples/md-basic-ja/07-browser-guide.md.

The guide teaches which button to press, so its pictures go stale the moment
StrictDoc moves one. Re-running this puts the arrows back where they belong,
because every target comes from the DOM - getBoundingClientRect on a real
element - rather than from pixel coordinates someone wrote down once.

Two rules the pictures follow:

  * Marks are shocking pink with a white halo. StrictDoc has a dark header, a
    white body and grey form fields, and a single flat colour disappears
    against one of them.
  * Most shots are cropped to the region that matters. StrictDoc displays an
    image at about 520 CSS px, so a whole 1264 px window shrinks to 41 per cent
    and the text inside it stops being readable. Whole-page views (the
    traceability matrix, the tree map) stay uncropped: there the layout is the
    subject, not the words.

Run it against a THROWAWAY copy of the project. The walk creates a document,
adds a requirement and edits a statement, and StrictDoc writes all of that to
disk. Point it at samples/md-basic-ja itself and you will have to revert.

    cp -r samples/md-basic-ja /tmp/shoot
    strictdoc server /tmp/shoot --output-path /tmp/shoot/output/strictdoc --port 5130
    python tools/capture-manual-ja.py http://127.0.0.1:5130 /tmp/shots

The Japanese the walk types lives in capture-manual-ja.txt, not in here, so
this file stays English ASCII the way NFR-010 asks.

Requires selenium and Pillow, neither of which the launcher needs. Install them
only when you are re-taking the pictures.
"""

import pathlib
import sys
import time

from PIL import Image, ImageDraw, ImageFont
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By

SCALE = 2
WINDOW = (1280, 900)
SETTLE = 2.0
GAP = 8
PAD = 34
ARROW = 110

PINK = (252, 15, 192, 255)
HALO = (255, 255, 255, 255)
SHAFT = 9
HALO_GROW = 5
HEAD_LENGTH = 34
HEAD_HALF_WIDTH = 20
BADGE_RADIUS = 19

OFFSETS = {"left": (-1, 0), "right": (1, 0), "up": (0, -1), "down": (0, 1)}

PHRASES = pathlib.Path(__file__).with_suffix(".txt")


def load_phrases():
    """key = value lines, with \\n written as a two-character escape."""
    values = {}
    for line in PHRASES.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().replace("\\n", "\n")
    missing = {
        "sentence", "new_uid", "new_title", "new_statement",
        "document_title", "document_path",
    } - set(values)
    if missing:
        raise SystemExit("{0} lacks {1}".format(PHRASES.name, sorted(missing)))
    return values


# --------------------------------------------------------------- drawing


def load_font(size):
    for name in ("DejaVuSans-Bold.ttf", "arialbd.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def arrow_points(tip, source, length):
    dx, dy = OFFSETS[source]
    head = HEAD_LENGTH * SCALE
    half = HEAD_HALF_WIDTH * SCALE
    tail = (tip[0] + dx * length, tip[1] + dy * length)
    base = (tip[0] + dx * head, tip[1] + dy * head)
    px, py = -dy, dx
    return tail, [
        tip,
        (base[0] + px * half, base[1] + py * half),
        (base[0] - px * half, base[1] - py * half),
    ]


def fit_length(tip, source, length, size, labelled):
    """Keep the tail, and its badge, inside the image."""
    width, height = size
    room = {
        "left": tip[0], "right": width - tip[0],
        "up": tip[1], "down": height - tip[1],
    }[source]
    margin = (BADGE_RADIUS * 2 + 6) * SCALE if labelled else 6 * SCALE
    return max((HEAD_LENGTH + 12) * SCALE, min(length, int(room) - margin))


def draw_one(draw, tip, source, length, colour, shaft, grow):
    tail, corners = arrow_points(tip, source, length)
    base = (tip[0] + OFFSETS[source][0] * HEAD_LENGTH * SCALE,
            tip[1] + OFFSETS[source][1] * HEAD_LENGTH * SCALE)
    draw.line([tail, base], fill=colour, width=shaft)
    if grow:
        cx = sum(p[0] for p in corners) / 3.0
        cy = sum(p[1] for p in corners) / 3.0
        scale = 1.0 + grow / float(HEAD_LENGTH * SCALE)
        corners = [(cx + (x - cx) * scale, cy + (y - cy) * scale) for x, y in corners]
    draw.polygon(corners, fill=colour)


def render(source_png, target_png, arrows):
    image = Image.open(source_png).convert("RGBA")
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    font = load_font((BADGE_RADIUS + 4) * SCALE)

    plans = []
    for arrow in arrows:
        plans.append(dict(arrow, length=fit_length(
            arrow["tip"], arrow["source"], ARROW * SCALE, image.size,
            bool(arrow.get("label")),
        )))

    # Every halo first, so a later mark's halo cannot eat an earlier mark.
    for plan in plans:
        draw_one(draw, plan["tip"], plan["source"], plan["length"], HALO,
                 (SHAFT + HALO_GROW * 2) * SCALE, HALO_GROW * SCALE)
    for plan in plans:
        draw_one(draw, plan["tip"], plan["source"], plan["length"], PINK,
                 SHAFT * SCALE, 0)
        if plan.get("label"):
            tail = arrow_points(plan["tip"], plan["source"], plan["length"])[0]
            dx, dy = OFFSETS[plan["source"]]
            radius = BADGE_RADIUS * SCALE
            centre = (tail[0] + dx * radius, tail[1] + dy * radius)
            draw.ellipse(
                [centre[0] - radius, centre[1] - radius,
                 centre[0] + radius, centre[1] + radius],
                fill=PINK, outline=HALO, width=4 * SCALE,
            )
            draw.text(centre, plan["label"], font=font, fill=HALO, anchor="mm")

    Image.alpha_composite(image, overlay).convert("RGB").save(target_png)
    return plans


# --------------------------------------------------------------- walking


class Shooter(object):
    def __init__(self, driver, out_dir):
        self.driver = driver
        self.out = out_dir
        self.taken = []

    def rect(self, element, tight=False):
        box = self.driver.execute_script(
            "const e = arguments[0];"
            "const r = arguments[1]"
            "  ? (() => { const g = document.createRange(); g.selectNodeContents(e);"
            "             return g.getBoundingClientRect(); })()"
            "  : e.getBoundingClientRect();"
            "return [r.x, r.y, r.width, r.height];",
            element, bool(tight),
        )
        return [v * SCALE for v in box]

    def tip(self, box, source):
        x, y, w, h = box
        gap = GAP * SCALE
        if source == "right":
            return (int(x + w + gap), int(y + h / 2))
        if source == "left":
            return (int(x - gap), int(y + h / 2))
        if source == "down":
            return (int(x + w / 2), int(y + h + gap))
        return (int(x + w / 2), int(y - gap))

    def into_view(self, element, block="center"):
        self.driver.execute_script(
            "arguments[0].scrollIntoView({block: arguments[1], behavior: 'instant'});",
            element, block,
        )
        time.sleep(0.4)

    def shoot(self, name, marks, crop=True, extra=()):
        raw = self.out / ("raw-" + name + ".png")
        self.driver.save_screenshot(str(raw))

        arrows, boxes = [], []
        for element, source, label, tight in marks:
            box = self.rect(element, tight)
            boxes.append(box)
            arrows.append({"tip": self.tip(box, source), "source": source, "label": label})
        for element in extra:
            boxes.append(self.rect(element))

        marked = self.out / (name + ".png")
        plans = render(raw, marked, arrows)
        if crop and boxes:
            self._crop(marked, plans, boxes)
        raw.unlink()
        self.taken.append(name)
        print("  {0:34} {1:4d} KB".format(name + ".png", marked.stat().st_size // 1024))

    def _crop(self, path, plans, boxes):
        image = Image.open(path)
        left = min(b[0] for b in boxes)
        top = min(b[1] for b in boxes)
        right = max(b[0] + b[2] for b in boxes)
        bottom = max(b[1] + b[3] for b in boxes)
        for plan in plans:
            reach = plan["length"] + BADGE_RADIUS * 2 * SCALE
            x, y = plan["tip"]
            dx, dy = OFFSETS[plan["source"]]
            left, right = min(left, x + dx * reach), max(right, x + dx * reach)
            top, bottom = min(top, y + dy * reach), max(bottom, y + dy * reach)
        image.crop((
            max(0, int(left) - PAD), max(0, int(top) - PAD),
            min(image.width, int(right) + PAD), min(image.height, int(bottom) + PAD),
        )).save(path, optimize=True)


def innermost_with(driver, text):
    return driver.execute_script(
        "const t = arguments[0]; let best = null;"
        "for (const e of document.querySelectorAll('sdoc-node *')) {"
        "  if (!e.textContent.includes(t)) continue;"
        "  if (Array.from(e.children).some(c => c.textContent.includes(t))) continue;"
        "  best = e;"
        "} return best;",
        text,
    )


def leaf_text(driver, root):
    return driver.execute_script(
        "for (const e of arguments[0].querySelectorAll('*')) {"
        "  if (e.children.length) continue;"
        "  if (!(e.textContent || '').trim()) continue;"
        "  const g = document.createRange(); g.selectNodeContents(e);"
        "  if (g.getBoundingClientRect().width < 4) continue;"
        "  return e;"
        "} return null;",
        root,
    )


def node_of(driver, uid):
    anchor = driver.find_element(By.CSS_SELECTOR, '[id="{0}"]'.format(uid))
    return driver.execute_script('return arguments[0].closest("sdoc-node")', anchor)


def hover(driver, node):
    ActionChains(driver).move_to_element(node).perform()
    time.sleep(0.7)


def type_into(driver, field, text):
    """Append to a StrictDoc contenteditable, and say whether the mirror kept up.

    The visible field and the posted value are two different elements. A shot
    that showed new text while the form still held the old one would be a lie
    the manual then teaches, so this reports which of the two happened.
    """
    return driver.execute_script(
        "const e = arguments[0], add = arguments[1];"
        "e.textContent = e.textContent + add;"
        "e.dispatchEvent(new Event('input', {bubbles: true}));"
        "const hidden = document.getElementsByName(e.id)[0];"
        "if (!hidden) { return 'no hidden field'; }"
        "if (hidden.value.endsWith(add)) { return 'mirrored by StrictDoc'; }"
        "hidden.value = e.textContent; return 'forced by this script';",
        field, text,
    )


def find(driver, css):
    return driver.find_element(By.CSS_SELECTOR, css)


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__.strip().splitlines()[0])
    base = sys.argv[1].rstrip("/")
    out = pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    say = load_phrases()

    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--window-size={0},{1}".format(*WINDOW))
    options.add_argument("--hide-scrollbars")
    options.add_argument("--force-device-scale-factor={0}".format(SCALE))
    options.add_argument("--lang=ja-JP")
    driver = webdriver.Chrome(options=options)
    s = Shooter(driver, out)
    doc = base + "/md-basic-ja/04-lower.html"

    try:
        # 00 the map of the screen, kept whole so the reader can place things
        driver.get(doc)
        time.sleep(SETTLE)
        node = node_of(driver, "SW-001")
        s.into_view(node)
        hover(driver, node)
        s.shoot("browser-00-map", [
            (find(driver, '[data-testid="header-placeholder"]'), "down", "1", False),
            (find(driver, '[data-testid="aside-project-tree"]'), "right", "2", False),
            (find(driver, '[data-testid="toc-list"]'), "left", "3", False),
            (node.find_element(By.CSS_SELECTOR, '[data-testid="node-edit-action"]'), "left", "4", False),
        ], crop=False)

        # 05 the four buttons a node grows on hover
        hover(driver, node)
        s.shoot("browser-05-node-buttons", [
            (node.find_element(By.CSS_SELECTOR, '[data-testid="node-edit-action"]'), "right", "1", False),
            (node.find_element(By.CSS_SELECTOR, '[data-testid="node-delete-action"]'), "right", "2", False),
            (node.find_element(By.CSS_SELECTOR, '[data-testid="node-clone-action"]'), "right", "3", False),
            (node.find_element(By.CSS_SELECTOR, '[data-testid="node-menu-handler"]'), "right", "4", False),
        ], extra=[node])

        # 03 the add-node menu. Entries are icon-only, so the menu frames them.
        node.find_element(By.CSS_SELECTOR, '[data-testid="node-menu-handler"]').click()
        time.sleep(1.2)
        below = node.find_element(By.CSS_SELECTOR, '[data-testid="node-add-requirement-below-action"]')
        s.into_view(below)
        menu = driver.execute_script('return arguments[0].closest("menu")', below)
        s.shoot("browser-03-add-node-menu", [(below, "right", "1", False)], extra=[menu])

        # 04 the form a new requirement opens with
        below.click()
        time.sleep(SETTLE)
        uid = find(driver, '[data-testid="form-field-UID"]')
        title = find(driver, '[data-testid="form-field-TITLE"]')
        statement = find(driver, '[data-testid="form-field-STATEMENT"]')
        save = find(driver, '[data-testid="form-submit-action"]')
        s.into_view(uid, "start")
        type_into(driver, uid, say["new_uid"])
        type_into(driver, title, say["new_title"])
        type_into(driver, statement, say["new_statement"])
        time.sleep(0.5)
        s.shoot("browser-04-new-req-form", [
            (uid, "right", "1", False), (title, "right", "2", False),
            (statement, "right", "3", False), (save, "left", "4", False),
        ])
        find(driver, '[data-testid="form-cancel-action"]').click()
        time.sleep(SETTLE)

        # 06 / 07 editing an existing requirement, and the result
        driver.get(doc)
        time.sleep(SETTLE)
        node = node_of(driver, "SW-001")
        s.into_view(node)
        hover(driver, node)
        node.find_element(By.CSS_SELECTOR, '[data-testid="node-edit-action"]').click()
        time.sleep(SETTLE)
        statement = find(driver, '[data-testid="form-field-STATEMENT"]')
        save = find(driver, '[data-testid="form-submit-action"]')
        s.into_view(statement)
        print("  STATEMENT sync: {0}".format(type_into(driver, statement, say["sentence"])))
        time.sleep(0.5)
        s.shoot("browser-06-edit-form",
                [(statement, "right", "1", False), (save, "left", "2", False)])
        save.click()
        time.sleep(SETTLE + 1)
        added = innermost_with(driver, say["sentence"].strip())
        if added is None:
            raise SystemExit("the saved node does not show the sentence")
        s.into_view(added)
        s.shoot("browser-07-saved", [(added, "right", "1", True)],
                extra=[node_of(driver, "SW-001")])

        # 08 / 09 relations
        driver.get(doc)
        time.sleep(SETTLE)
        node = node_of(driver, "SW-002")
        s.into_view(node)
        hover(driver, node)
        node.find_element(By.CSS_SELECTOR, '[data-testid="node-edit-action"]').click()
        time.sleep(SETTLE)
        tab = find(driver, '[data-testid="form-tab-Relations"]')
        tab.click()
        time.sleep(1.2)
        s.into_view(tab, "start")
        s.shoot("browser-08-relations-tab", [
            (tab, "up", "1", False),
            (find(driver, '[data-testid="form-field-relation-uid"]'), "right", "2", False),
            (find(driver, '[data-testid="select-relation-typerole"]'), "right", "3", False),
            (find(driver, '[data-testid="form-action-add-relation"]'), "left", "4", True),
        ])
        find(driver, '[data-testid="form-cancel-action"]').click()
        time.sleep(SETTLE)
        node = node_of(driver, "SW-002")
        s.into_view(node)
        s.shoot("browser-09-relation-shown",
                [(innermost_with(driver, "SYS-002"), "right", "1", True)], extra=[node])

        # 10 / 11 a table as markup, then as a table
        driver.get(base + "/md-basic-ja/02-guide-for-human.html")
        time.sleep(SETTLE)
        table = find(driver, "sdoc-node table")
        s.into_view(table)
        s.shoot("browser-11-table-rendered", [(table, "right", "1", False)])
        table_node = driver.execute_script('return arguments[0].closest("sdoc-node")', table)
        hover(driver, table_node)
        table_node.find_element(By.CSS_SELECTOR, '[data-testid="node-edit-action"]').click()
        time.sleep(SETTLE)
        field = find(driver, '[data-testid="form-field-STATEMENT"], [data-testid="form-field-CONTENT"]')
        s.into_view(field)
        s.shoot("browser-10-table-markup", [(field, "right", "1", False)])
        find(driver, '[data-testid="form-cancel-action"]').click()
        time.sleep(SETTLE)

        # 12 a Mermaid figure. The figure is the subject, so it carries no arrow.
        driver.get(doc)
        time.sleep(SETTLE + 1.5)
        figure = find(driver, "sdoc-node pre.mermaid, sdoc-node .mermaid")
        s.into_view(figure)
        s.shoot("browser-12-mermaid", [], extra=[figure])

        # 13 the view switcher, folded away behind the word Document
        link = find(driver, 'a[href*="-TABLE.html"]')
        holder = driver.execute_script('return arguments[0].closest("div")', link)
        driver.execute_script("arguments[0].firstElementChild.click();", holder)
        time.sleep(1.2)
        if link.is_displayed():
            s.shoot("browser-13-views", [(link, "right", "1", True)],
                    extra=[driver.execute_script('return arguments[0].closest("menu")', link)])
        else:
            print("  SKIP browser-13-views: the switcher did not open")

        # 14 - 18 whole pages, kept whole because the layout is the point
        for name, path in (
            ("browser-14-table-view", "/md-basic-ja/04-lower-TABLE.html"),
            ("browser-15-trace-view", "/md-basic-ja/04-lower-TRACE.html"),
            ("browser-16-matrix", "/traceability_matrix.html"),
            ("browser-17-tree-map", "/tree_map.html"),
            ("browser-18-statistics", "/project_statistics.html"),
        ):
            driver.get(base + path)
            time.sleep(SETTLE + 0.8)
            s.shoot(name, [], crop=False)

        # 19 / 20 the document's own menu, and the grammar editor
        driver.get(doc)
        time.sleep(SETTLE)
        find(driver, '[data-testid="header-action-menu-handler"]').click()
        time.sleep(1.0)
        entries = [a for a in driver.find_elements(By.CSS_SELECTOR, "a[href*='/actions/document/']")
                   if a.is_displayed()]
        if entries:
            holder = driver.execute_script('return arguments[0].closest("menu, ul")', entries[0])
            # This menu hangs off the top right corner, so the arrow comes from
            # the left. From the right it would run out of image.
            s.shoot("browser-19-document-actions", [(entries[0], "left", "1", True)], extra=[holder])
        grammar = [a for a in entries if "edit_grammar" in a.get_attribute("href")]
        if grammar:
            grammar[0].click()
            time.sleep(SETTLE + 0.5)
            s.shoot("browser-20-grammar", [], crop=False)

        # 21 / 22 making a new document
        driver.get(base + "/")
        time.sleep(SETTLE)
        find(driver, '[data-testid="header-action-menu-handler"]').click()
        time.sleep(1.0)
        add = find(driver, '[data-testid="tree-add-document-action"]')
        s.shoot("browser-21-new-document-menu", [(add, "left", "1", True)],
                extra=[driver.execute_script('return arguments[0].closest("menu, ul")', add)])
        add.click()
        time.sleep(SETTLE)
        title = find(driver, '[data-testid="form-field-document_title"]')
        path_field = find(driver, '[data-testid="form-field-document_path"]')
        save = find(driver, '[data-testid="form-submit-action"]')
        type_into(driver, title, say["document_title"])
        type_into(driver, path_field, say["document_path"])
        time.sleep(0.5)
        s.shoot("browser-22-new-document-form", [
            (title, "right", "1", False), (path_field, "right", "2", False),
            (save, "left", "3", False),
        ])

        print("  {0} shot(s) in {1}".format(len(s.taken), out.as_posix()))
        print("  Cap anything wider than 1600 px before copying it into _assets/.")
    finally:
        driver.quit()


if __name__ == "__main__":
    main()

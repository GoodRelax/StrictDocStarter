# StrictDoc project configuration for the bundled "sovd-automotive" sample.
#
# IMPORTANT: this file MUST live in the folder passed to
# `strictdoc server <path>` / `strictdoc export <path>` -- i.e. the
# `project_path` in server.config.json. StrictDoc reads the config in the input
# folder ITSELF and does NOT look in parent folders (verified on strictdoc
# 0.27.1). That is why the config lives here, next to the .sdoc files, and not
# in the StrictDocStarter tool root.
#
# Shape follows the official `strictdoc new` output (create_config() returning a
# ProjectConfig with a project_features toggle list). MATHJAX and MERMAID are
# NOT listed: this sample targets strictdoc 0.27 and newer, where both are on by
# default and listing them prints a DEPRECATION warning. The RST raw-html
# <pre class="mermaid"> diagrams, the Markdown ```mermaid fences and the
# .. math:: blocks used across these documents render without any toggle.
# include_doc_paths / include_source_paths are intentionally omitted: this
# sample keeps its .sdoc files flat in this folder (no docs/ or src/
# subfolders), so the default "scan everything under the project" behaviour is
# what we want.
#
# Docs: https://strictdoc.readthedocs.io/en/stable/stable/docs/strictdoc_01_user_guide.html
#       (sections "Selecting features", "Mermaid diagramming and charting tool")
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="SOVD Automotive (StrictDocStarter sample)",
        # Appearance. StrictDoc has no dark mode of its own, so StrictDocStarter
        # supplies one as an extra stylesheet. strictdoc-theme.css next to this file
        # is regenerated every time the project is opened, following the color_mode
        # setting in server.config.json -- use change-color-mode.bat to change it.
        # The committed copy is the "auto" variant, so a plain `strictdoc export`
        # works too. The path must stay relative: strictdoc asserts on absolute ones.
        custom_css_path="strictdoc-theme.css",
        project_features=[
            # Stable features (these four are strictdoc's defaults). None of them
            # puts an icon in the left toolbar: the first three only add entries
            # to a document's VIEWS dropdown, and SEARCH's icon requires a
            # running server (nav.jinja.html and is_activated_search() both
            # check is_running_on_server), so `strictdoc export` never shows it.
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "SEARCH",
            # Experimental screens. These three ARE the left toolbar.
            # Requirement x design/test coverage matrix screen. Surfaces which
            # requirements are implemented/verified and their test results
            # across the V-model (Implements/Satisfies/Verifies/ResultOf).
            "TRACEABILITY_MATRIX_SCREEN",
            # Document / requirement / relation counts for the whole project.
            "PROJECT_STATISTICS_SCREEN",
            # Plotly tree map of the document tree, coloured by coverage
            # (red = uncovered, green = covered). It bundles plotly.js, which is
            # what makes the output folder grow by a few MB.
            "TREE_MAP_SCREEN",
            # Two features that also have toolbar icons but are left out on
            # purpose. REQUIREMENT_TO_SOURCE_TRACEABILITY: this sample ships no
            # source files and sets no include_source_paths, so its Source
            # coverage screen would be empty. DIFF: server-only, and it compares
            # Git revisions of the server process's working directory rather
            # than of the served folder.
        ],
    )

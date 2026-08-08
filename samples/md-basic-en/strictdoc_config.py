# StrictDoc project configuration for the bundled "md-basic-ja" sample.
#
# This is a byte-for-byte copy of samples/sd-basic-ja/strictdoc_config.py apart
# from project_title. It is duplicated rather than shared because StrictDoc
# reads the config in the input folder ITSELF and does NOT look in parent
# folders, so each project folder needs its own copy.
#
# Nothing here is Markdown-specific: StrictDoc discovers .md and .sdoc files
# with the same project scan, and every feature listed below works identically
# for both. Markdown support is still marked experimental upstream (first
# released in 0.19.0, 2026-03-15).
#
# MATHJAX and MERMAID are NOT listed. Both are enabled by default from 0.27 on,
# and listing them prints a DEPRECATION warning.
#
# The three "SCREEN" features at the end are what put icons in the left
# toolbar. TABLE / TRACEABILITY / DEEP_TRACEABILITY do not: they only add
# entries to a document's VIEWS dropdown. SEARCH has an icon, but only while a
# server is running -- nav.jinja.html and is_activated_search() both require
# is_running_on_server -- so a static export shows four icons and
# launch-strictdoc.bat shows five.
#
# Four features that strictdoc's own docs site enables are deliberately left
# out here, each for a measured reason:
#
#   DIFF        Server-only, and its screen resolves the two Git revisions in
#               the server process's CURRENT WORKING DIRECTORY rather than in
#               the served folder. Under launch-strictdoc.bat that is the
#               StrictDocStarter root, so the icon would diff the wrong
#               repository (measured on 0.27.1: a StrictDocStarter revision
#               resolves, everything else returns HTTP 422).
#   HTML2PDF    Costs about +3 s of export time on every run and needs a
#               chromedriver install to produce an actual PDF. A starter sample
#               should not ship a menu entry that errors on a clean machine.
#   NESTOR      Dormant in 0.27.1: ProjectFeature.NESTOR has zero references in
#               the source, and /__nestor answers 200 with or without the flag.
#   REQUIREMENT_TO_SOURCE_TRACEABILITY
#               Adds a "source coverage" icon, but this sample ships no source
#               files and no include_source_paths, so the screen would be
#               empty. No bundled sample enables it.
#
# TREE_MAP_SCREEN is the one feature here with a real size cost: it bundles a
# plotting library into the output folder. On this sample that is small; on a
# large project expect a few MB.
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="Markdown basics, English (StrictDocStarter sample)",
        # No exclude_doc_paths here on purpose. 00-ai-guide.md and
        # 01-ai-queries.md are written for an AI rather than for a human
        # reader, and an earlier revision hid them from the document tree.
        # They are now ordinary documents, because a visitor browsing this
        # sample in StrictDoc should be able to see that AI-facing documents
        # exist and read them in place. The cost is that every heading in
        # them carries "**Type**: SECTION", which is what stops StrictDoc
        # reading the text under a heading as an implicit requirement.
        #
        # If a future revision does need to hide a document, name it as a
        # file. Excluding a folder ("_assets/**") would also stop the assets
        # being copied, and the export still reports success while the images
        # 404. StrictDoc feeds exclude_doc_paths to both the document finder
        # and the asset-directory finder (core/file_system/document_finder.py).
        # Appearance. StrictDoc has no dark mode of its own, so StrictDocStarter
        # supplies one as an extra stylesheet. strictdoc-theme.css next to this file
        # is regenerated every time the project is opened, following the color_mode
        # setting in server.config.json -- use change-color-mode.bat to change it.
        # The committed copy is the "auto" variant, so a plain `strictdoc export`
        # works too. The path must stay relative: strictdoc asserts on absolute ones.
        custom_css_path="strictdoc-theme.css",
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "SEARCH",
            "PROJECT_STATISTICS_SCREEN",
            "TRACEABILITY_MATRIX_SCREEN",
            "TREE_MAP_SCREEN",
        ],
    )

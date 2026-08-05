# StrictDoc project configuration for the bundled "sd-basic-ja" sample.
#
# IMPORTANT: this file MUST live in the folder passed to
# `strictdoc server <path>` / `strictdoc export <path>` -- StrictDoc reads the
# config in the input folder ITSELF and does NOT look in parent folders. That is
# also why md-basic-ja carries its own copy of this file instead of sharing one.
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
#               empty. See samples/sdoc-patterns for a project that uses it.
#
# TREE_MAP_SCREEN is the one feature here with a real size cost: it bundles a
# plotting library into the output folder. On this sample that is small; on a
# large project expect a few MB.
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="SDoc basics, Japanese (StrictDocStarter sample)",
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

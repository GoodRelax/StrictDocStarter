# StrictDoc project configuration for the bundled "sdoc-patterns" sample.
#
# IMPORTANT: this file MUST live in the folder passed to
# `strictdoc server <path>` / `strictdoc export <path>` -- StrictDoc reads the
# config in the input folder ITSELF and does NOT look in parent folders.
#
# MATHJAX and MERMAID are NOT listed, because this sample targets strictdoc
# 0.27.1, where both are enabled by default and listing them prints a
# DEPRECATION warning.
#
# On strictdoc 0.23.1 the parse, the traceability graph and the JSON export are
# identical, but Mermaid and MathJax are NOT loaded into the HTML: the diagram
# in 03-figures.sdoc shows as raw text and the formula does not render. To view
# this sample on 0.23.1, add "MATHJAX" and "MERMAID" to project_features below.
# (Both behaviours verified by running each version. The release that flipped
# the default was not determined.)
#
# REQUIREMENT_TO_SOURCE_TRACEABILITY + include_source_paths are what make
# `RELATIONS: TYPE: File` render as a link. Without both, a File relation is
# parsed and exported to JSON but silently produces no link in the HTML.
from strictdoc.core.project_config import ProjectConfig


def create_config() -> ProjectConfig:
    return ProjectConfig(
        project_title="SDoc authoring patterns (StrictDocStarter sample)",
        project_features=[
            "TABLE_SCREEN",
            "TRACEABILITY_SCREEN",
            "DEEP_TRACEABILITY_SCREEN",
            "SEARCH",
            "REQUIREMENT_TO_SOURCE_TRACEABILITY",
        ],
        include_source_paths=["_assets/**"],
    )

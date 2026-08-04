# StrictDoc project configuration for the bundled "sdoc-patterns" sample.
#
# IMPORTANT: this file MUST live in the folder passed to
# `strictdoc server <path>` / `strictdoc export <path>` -- StrictDoc reads the
# config in the input folder ITSELF and does NOT look in parent folders.
#
# MATHJAX and MERMAID are NOT listed, because this sample targets strictdoc
# 0.27 and newer, where both are enabled by default and listing them prints a
# DEPRECATION warning.
#
# REQUIREMENT_TO_SOURCE_TRACEABILITY + include_source_paths are what make
# `RELATIONS: TYPE: File` render as a link. Without both, a File relation is
# parsed and exported to JSON but silently produces no link in the HTML.
#
# exclude_doc_paths keeps queries/README.md out of the document tree. StrictDoc
# treats EVERY .md under the project as a document, wherever it sits -- a plain
# README dropped into a subfolder becomes a document with its own table and
# traceability screens unless it is excluded here.
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
        exclude_doc_paths=["queries/**"],
    )

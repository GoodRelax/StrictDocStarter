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
# StrictDoc parses EVERY .md under the project as a document, wherever it sits --
# including inside _assets. Being an asset directory grants no exemption:
# document_finder.py runs two independent scans over the same root, one looking
# for directories named "_assets" and one looking for files with document
# extensions, and the second ignores only the output directory. (Measured, and
# read in the 0.27.1 source.)
# For _assets/*.md that is what we want: each of those files is one diagram plus
# the prose that explains it, and being a document is what makes the ```mermaid
# fence render. They are NOT excluded.
#
# The flip side is that every .md has to be readable as a StrictDoc document
# (an H1 first, UTF-8). One that is not fails the WHOLE export, so a note or a
# vendored copy that cannot be reshaped has to be named here. queries/README.md
# is excluded for the milder reason that it documents the filters rather than
# the product.
#
# Exclude by file, never by folder. "_assets/**" would take the directory out
# of the scan entirely: "Find asset directories" stops seeing it and
# pipeline.png / pipeline.svg are never copied, so every <img> in the built
# HTML 404s while the export still reports success. "_assets/*.md" keeps the
# folder an asset directory. (Both behaviours verified on 0.27.1.)
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

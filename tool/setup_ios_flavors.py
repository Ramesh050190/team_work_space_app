#!/usr/bin/env python3
"""Adds Debug/Release/Profile-{dev,stage,prod} configs + schemes for iOS flavors."""

from __future__ import annotations

import pathlib
import re
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
PBX = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
SCHEMES = ROOT / "ios" / "Runner.xcodeproj" / "xcshareddata" / "xcschemes"

FLAVORS = ("dev", "stage", "prod")
MODES = ("Debug", "Release", "Profile")

BUNDLE = {
    "dev": "com.teamworkspace.teamWorkspace.dev",
    "stage": "com.teamworkspace.teamWorkspace.stage",
    "prod": "com.teamworkspace.teamWorkspace",
}
DISPLAY = {
    "dev": "TW Dev",
    "stage": "TW Stage",
    "prod": "Team Workspace",
}


def new_id() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    text = PBX.read_text()

    if "Debug-dev" in text:
        print("iOS flavors already present in project.pbxproj")
        _write_schemes()
        return

    file_refs: dict[str, str] = {}
    file_ref_lines: list[str] = []
    for mode in MODES:
        for flavor in FLAVORS:
            name = f"{mode}-{flavor}.xcconfig"
            rid = new_id()
            file_refs[name] = rid
            file_ref_lines.append(
                f'\t\t{rid} /* {name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.xcconfig; name = {name}; path = Flutter/{name}; sourceTree = "<group>"; }};'
            )

    marker = "9740EEB21CF90195004384FC /* Debug.xcconfig */"
    idx = text.find(marker)
    if idx < 0:
        raise SystemExit("Could not find Debug.xcconfig file reference")
    line_end = text.find("\n", idx)
    text = text[: line_end + 1] + "\n".join(file_ref_lines) + "\n" + text[line_end + 1 :]

    group_marker = "\t\t\t\t9740EEB21CF90195004384FC /* Debug.xcconfig */,\n"
    group_insert = group_marker + "".join(
        f"\t\t\t\t{file_refs[f'{mode}-{flavor}.xcconfig']} /* {mode}-{flavor}.xcconfig */,\n"
        for mode in MODES
        for flavor in FLAVORS
    )
    if group_marker not in text:
        raise SystemExit("Could not find Flutter group Debug.xcconfig entry")
    text = text.replace(group_marker, group_insert, 1)

    def extract_config(config_id: str) -> str:
        pattern = rf"\t\t{config_id} /\* .*? \*/ = \{{.*?\n\t\t\}};"
        match = re.search(pattern, text, flags=re.S)
        if not match:
            raise SystemExit(f"Missing config {config_id}")
        return match.group(0)

    project_templates = {
        "Debug": extract_config("97C147031CF9000F007C117D"),
        "Release": extract_config("97C147041CF9000F007C117D"),
        "Profile": extract_config("249021D3217E4FDB00AE95B9"),
    }
    runner_templates = {
        "Debug": extract_config("97C147061CF9000F007C117D"),
        "Release": extract_config("97C147071CF9000F007C117D"),
        "Profile": extract_config("249021D4217E4FDB00AE95B9"),
    }
    tests_templates = {
        "Debug": extract_config("331C8088294A63A400263BE5"),
        "Release": extract_config("331C8089294A63A400263BE5"),
        "Profile": extract_config("331C808A294A63A400263BE5"),
    }

    new_blocks: list[str] = []
    project_extra: list[str] = []
    runner_extra: list[str] = []
    tests_extra: list[str] = []

    for mode in MODES:
        for flavor in FLAVORS:
            name = f"{mode}-{flavor}"

            pid = new_id()
            block = project_templates[mode]
            block = re.sub(r"^\t\t[A-F0-9]{24}", f"\t\t{pid}", block, count=1)
            block = re.sub(r"name = [^;]+;", f"name = \"{name}\";", block)
            new_blocks.append(block)
            project_extra.append(f"\t\t\t\t{pid} /* {name} */,\n")

            rid = new_id()
            xc = f"{mode}-{flavor}.xcconfig"
            block = runner_templates[mode]
            block = re.sub(r"^\t\t[A-F0-9]{24}", f"\t\t{rid}", block, count=1)
            block = re.sub(
                r"baseConfigurationReference = [A-F0-9]{24} /\* .*? \*/;",
                f"baseConfigurationReference = {file_refs[xc]} /* {xc} */;",
                block,
            )
            block = re.sub(
                r"PRODUCT_BUNDLE_IDENTIFIER = [^;]+;",
                f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE[flavor]};",
                block,
            )
            if "DISPLAY_NAME" not in block:
                block = block.replace(
                    "buildSettings = {",
                    f"buildSettings = {{\n\t\t\t\tDISPLAY_NAME = \"{DISPLAY[flavor]}\";",
                    1,
                )
            block = re.sub(r"name = [^;]+;", f"name = \"{name}\";", block)
            new_blocks.append(block)
            runner_extra.append(f"\t\t\t\t{rid} /* {name} */,\n")

            tid = new_id()
            block = tests_templates[mode]
            block = re.sub(r"^\t\t[A-F0-9]{24}", f"\t\t{tid}", block, count=1)
            block = re.sub(r"name = [^;]+;", f"name = \"{name}\";", block)
            new_blocks.append(block)
            tests_extra.append(f"\t\t\t\t{tid} /* {name} */,\n")

    insert_at = text.find("/* End XCBuildConfiguration section */")
    text = text[:insert_at] + "\n".join(new_blocks) + "\n" + text[insert_at:]

    def append_list(list_id: str, extras: list[str]) -> None:
        nonlocal text
        pattern = (
            rf"({list_id} /\* .*? \*/ = \{{\n"
            rf"\t\t\tisa = XCConfigurationList;\n"
            rf"\t\t\tbuildConfigurations = \(\n"
            rf")(.*?)(\t\t\t\);\n\t\t\tdefaultConfigurationIsVisible = 0;)"
        )
        match = re.search(pattern, text, flags=re.S)
        if not match:
            raise SystemExit(f"Could not update configuration list {list_id}")
        text = (
            text[: match.end(2)]
            + "".join(extras)
            + text[match.end(2) :]
        )

    append_list("97C146E91CF9000F007C117D", project_extra)
    append_list("97C147051CF9000F007C117D", runner_extra)
    append_list("331C8087294A63A400263BE5", tests_extra)

    PBX.write_text(text)
    print(f"Updated {PBX}")
    _write_schemes()


def _write_schemes() -> None:
    SCHEMES.mkdir(parents=True, exist_ok=True)
    template = (SCHEMES / "Runner.xcscheme").read_text()
    for flavor in FLAVORS:
        content = template
        # Order matters: replace longer tokens first is N/A; quote-aware replace.
        for mode in ("Debug", "Release", "Profile"):
            content = content.replace(
                f'buildConfiguration = "{mode}"',
                f'buildConfiguration = "{mode}-{flavor}"',
            )
        out = SCHEMES / f"{flavor}.xcscheme"
        out.write_text(content)
        print(f"Wrote {out.name}")


if __name__ == "__main__":
    main()

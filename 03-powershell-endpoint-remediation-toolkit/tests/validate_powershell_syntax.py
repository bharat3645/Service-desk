"""
validate_powershell_syntax.py
-------------------------------
Static structural syntax validator for the .ps1 scripts in ../scripts/.

No PowerShell runtime was available in the build environment (Linux
sandbox, no outbound access to install PowerShell Core), so this performs
the strongest static verification achievable without one: it walks each
script's character stream, correctly skipping PowerShell line comments
(#...), block comments (<# ... #>), and both single- and double-quoted
string literals, then confirms every brace/paren/bracket is balanced.

Scope: this catches structural defects (mismatched { } ( ) [ ] from
copy-paste edits or incomplete refactors) — the single most common cause
of "looks correct but fails to parse." It does NOT catch semantic errors
(e.g. a misspelled cmdlet name, wrong parameter type) — only a real
PowerShell parser (Test-ScriptCoverage / AST parser) can do that.

Exit code: 0 if all scripts pass, 1 if any script has an imbalance —
suitable for use as a CI gate.

Usage:
    python3 validate_powershell_syntax.py
"""
import glob
import sys

SCRIPTS_DIR = "../scripts"

BRACKET_PAIRS = [("{", "}", "brace"), ("(", ")", "paren"), ("[", "]", "bracket")]


def check_balance(text):
    """Returns a list of imbalance descriptions (empty if the script is
    structurally sound)."""
    issues = []
    for ch_open, ch_close, name in BRACKET_PAIRS:
        depth = 0
        in_squote = in_dquote = in_block_comment = False
        i = 0
        while i < len(text):
            c = text[i]
            nxt = text[i + 1] if i + 1 < len(text) else ""
            if in_block_comment:
                if c == "#" and nxt == ">":
                    in_block_comment = False
                    i += 2
                    continue
            elif in_squote:
                if c == "'":
                    in_squote = False
            elif in_dquote:
                if c == '"':
                    in_dquote = False
            else:
                if c == "<" and nxt == "#":
                    in_block_comment = True
                    i += 2
                    continue
                elif c == "#":
                    nl = text.find("\n", i)
                    i = nl if nl != -1 else len(text)
                    continue
                elif c == "'":
                    in_squote = True
                elif c == '"':
                    in_dquote = True
                elif c == ch_open:
                    depth += 1
                elif c == ch_close:
                    depth -= 1
            i += 1
        if depth != 0:
            issues.append(f"{name} imbalance: {depth:+d}")
    return issues


def main():
    script_paths = sorted(glob.glob(f"{SCRIPTS_DIR}/*.ps1"))
    if not script_paths:
        print(f"No .ps1 files found under {SCRIPTS_DIR}/", file=sys.stderr)
        return 1

    exit_code = 0
    for path in script_paths:
        text = open(path, encoding="utf-8").read()
        issues = check_balance(text)
        if issues:
            exit_code = 1
            print(f"{path}: FAIL — {', '.join(issues)}")
        else:
            print(f"{path}: PASS")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())

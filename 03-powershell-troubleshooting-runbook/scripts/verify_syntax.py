"""
verify_syntax.py
-----------------
Structural syntax verifier for the .ps1 scripts in this folder.

No PowerShell runtime was available in the build environment, so this
performs the strongest static check possible without one: it walks each
script character-by-character, correctly skipping PowerShell comments
(# line comments and <# ... #> block comments) and string literals
('...' and "..."), and confirms every brace/paren/bracket is balanced.

This will NOT catch semantic errors (e.g. a misspelled cmdlet name) —
only a real PowerShell parser can do that. It does catch the single most
common source of "script looks fine but fails instantly": mismatched
{ } ( ) [ ] from copy-paste edits.

Usage: python3 verify_syntax.py
"""
import glob

def check(path):
    text = open(path, encoding="utf-8").read()
    issues = []
    for ch_open, ch_close, name in [("{", "}", "brace"), ("(", ")", "paren"), ("[", "]", "bracket")]:
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
            issues.append(f"{name} imbalance: {depth}")
    return issues

if __name__ == "__main__":
    for f in sorted(glob.glob("*.ps1")):
        issues = check(f)
        status = "OK" if not issues else "ISSUES: " + ", ".join(issues)
        print(f"{f}: {status}")

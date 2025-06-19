#!/usr/bin/env python3
import sys

def main():
    skipping = False
    for line in sys.stdin:
        # If we hit the MediaWiki opening fence, start skipping
        if not skipping and line.rstrip("\n") == "```{=mediawiki}":
            skipping = True
            continue
        # If we’re skipping and hit a plain closing fence, stop skipping
        if skipping and line.rstrip("\n") == "```":
            skipping = False
            continue
        # Otherwise, if we’re not in the skip-region, print the line
        if not skipping:
            sys.stdout.write(line)

if __name__ == "__main__":
    main()

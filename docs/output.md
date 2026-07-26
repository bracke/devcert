# Output

Commands report semantic results to the output layer. Human output is rendered
through localized messages. Styled terminal output uses `terminal_styles`;
plain output bypasses styling; JSON output bypasses terminal styling entirely.

`--plain` and `--color=never` force unstyled human text. With `--color=auto`,
the `NO_COLOR` environment variable also forces plain output. Meaning must not
depend on color.

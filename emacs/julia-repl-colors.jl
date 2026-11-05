# Julia 1.13+ provides native REPL highlighting; no OhMyREPL dependency.
# Loaded only by Emacs' julia-repl, leaving other Julia entry points alone.
# ANSI names intentionally follow the Emacs/Ghostty slot swaps: blue -> green,
# green -> red, red -> blue.  Using ANSI colours lets theme switching choose
# light/dark shades, rather than hard-coding truecolour in the Julia process.
if VERSION >= v"1.13"
    import JuliaSyntaxHighlighting
    import StyledStrings
    for (name, colour) in (
        :julia_keyword => :blue,
        :julia_funcall => :blue,
        :julia_funcdef => :blue,
        :julia_builtin => :blue,
        :julia_type => :magenta,
        :julia_macro => :magenta,
        :julia_symbol => :magenta,
        :julia_string => :green,
        :julia_string_delim => :green,
        :julia_char => :green,
        :julia_char_delim => :green,
        :julia_cmd => :green,
        :julia_regex => :green,
        :julia_number => :red,
        :julia_bool => :red,
        :julia_singleton_identifier => :red,
        :julia_comment => :bright_black,
    )
        StyledStrings.loadface!(name => StyledStrings.Face(foreground=colour))
    end
end

# EmacsVterm needs Base.active_repl, so load it in atreplinit rather than
# while --load is being evaluated.  The shared Julia environment supplies
# this UI dependency without adding it to each project's Project.toml.
atreplinit() do repl
    if get(ENV, "INSIDE_EMACS", "") == "vterm"
        if Base.find_package("EmacsVterm") !== nothing
            @eval using EmacsVterm
        else
            @warn "Install EmacsVterm in the shared Julia environment for Emacs documentation buffers"
        end
    end
end

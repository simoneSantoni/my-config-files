"""
COLORS FOR YARU THEMES
----------------------
Contains color definitions for Ubuntu Yaru-inspired themes.
Based on yaru.nvim by Simone Santoni.

Yaru Palette:
    bg:             #2C001E (dark eggplant)
    bg_alt:         #3B1028
    fg:             #F6F5F4
    fg_dim:         #D5CFCA
    comment:        #B7A7B4
    orange:         #E95420 (Ubuntu orange)
    aubergine:      #772953
    aubergine_dark: #5E2750
    gold:           #F99B15
    green:          #26A269
    teal:           #19B6EE
    red:            #C7162B
    border:         #4A1D33
    selection:      #3D1E2F
"""
from enum import Enum

from zulipterminal.config.color import color_properties


# fmt: off
# NOTE: The 24bit color codes use 256 color which can be
# enhanced to be truly 24bit.
# NOTE: The 256code format uses h0-255 for the full 256 color range.

class YaruColor(Enum):
    # color           =  16code          256code    24code

    # Backgrounds
    BG               = 'black           h5         #2C001E'
    BG_ALT           = 'black           h53        #3B1028'
    SELECTION        = 'dark_magenta    h53        #3D1E2F'
    BORDER           = 'dark_magenta    h89        #4A1D33'

    # Foregrounds
    FG               = 'white           h255       #F6F5F4'
    FG_DIM           = 'light_gray      h251       #D5CFCA'
    COMMENT          = 'light_gray      h249       #B7A7B4'

    # Accent colors
    ORANGE           = 'brown           h202       #E95420'
    GOLD             = 'yellow          h214       #F99B15'
    GREEN            = 'dark_green      h35        #26A269'
    TEAL             = 'light_cyan      h39        #19B6EE'
    RED              = 'dark_red        h160       #C7162B'
    AUBERGINE        = 'dark_magenta    h89        #772953'
    AUBERGINE_DARK   = 'dark_magenta    h53        #5E2750'
    AUBERGINE_LIGHT  = 'light_magenta   h132       #924567'

# fmt: on


DefaultBoldColor = color_properties(YaruColor, "BOLD")

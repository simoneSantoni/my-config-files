"""
UBUNTU YARU DARK
----------------
Ubuntu Yaru-inspired dark theme for Zulip Terminal.
Based on yaru.nvim by Simone Santoni.

Features the distinctive Ubuntu eggplant background with
aubergine accent colors.

For further details on themefiles look at the theme contribution guide.
"""

from pygments.styles.monokai import MonokaiStyle

from zulipterminal.config.color import Background
from zulipterminal.themes.colors_yaru import DefaultBoldColor as Color


# fmt: off

STYLES = {
    # style_name       :  foreground                   background
    None               : (Color.FG,                    Background.COLOR),
    'selected'         : (Color.FG,                    Color.AUBERGINE_LIGHT),
    'msg_selected'     : (Color.FG,                    Color.AUBERGINE_LIGHT),
    'header'           : (Color.FG,                    Color.AUBERGINE),
    'general_narrow'   : (Color.BG,                    Color.ORANGE),
    'general_bar'      : (Color.FG,                    Background.COLOR),
    'msg_sender'       : (Color.GOLD__BOLD,            Background.COLOR),
    'unread'           : (Color.TEAL,                  Background.COLOR),
    'user_active'      : (Color.GREEN,                 Background.COLOR),
    'user_idle'        : (Color.GOLD,                  Background.COLOR),
    'user_offline'     : (Color.FG_DIM,                Background.COLOR),
    'user_inactive'    : (Color.COMMENT,               Background.COLOR),
    'user_bot'         : (Color.AUBERGINE,             Background.COLOR),
    'title'            : (Color.FG__BOLD,              Background.COLOR),
    'column_title'     : (Color.FG__BOLD,              Background.COLOR),
    'time'             : (Color.TEAL,                  Background.COLOR),
    'bar'              : (Color.FG_DIM,                Color.AUBERGINE),
    'msg_emoji'        : (Color.GOLD,                  Background.COLOR),
    'reaction'         : (Color.GOLD__BOLD,            Background.COLOR),
    'reaction_mine'    : (Color.BG,                    Color.GOLD),
    'msg_heading'      : (Color.FG__BOLD,              Color.AUBERGINE),
    'msg_math'         : (Color.FG_DIM,                Color.SELECTION),
    'msg_mention'      : (Color.ORANGE__BOLD,          Background.COLOR),
    'msg_link'         : (Color.TEAL,                  Background.COLOR),
    'msg_link_index'   : (Color.TEAL__BOLD,            Background.COLOR),
    'msg_quote'        : (Color.COMMENT,               Background.COLOR),
    'msg_bold'         : (Color.FG__BOLD,              Background.COLOR),
    'msg_time'         : (Color.BG,                    Color.FG),
    'footer'           : (Color.BG,                    Color.FG_DIM),
    'footer_contrast'  : (Color.FG,                    Background.COLOR),
    'starred'          : (Color.RED__BOLD,             Background.COLOR),
    'unread_count'     : (Color.ORANGE,                Background.COLOR),
    'starred_count'    : (Color.COMMENT,               Background.COLOR),
    'table_head'       : (Color.FG__BOLD,              Background.COLOR),
    'filter_results'   : (Color.BG,                    Color.GREEN),
    'edit_topic'       : (Color.FG,                    Color.SELECTION),
    'edit_tag'         : (Color.FG,                    Color.SELECTION),
    'edit_author'      : (Color.GOLD,                  Background.COLOR),
    'edit_time'        : (Color.TEAL,                  Background.COLOR),
    'current_user'     : (Color.ORANGE,                Background.COLOR),
    'muted'            : (Color.COMMENT,               Background.COLOR),
    'popup_border'     : (Color.AUBERGINE,             Background.COLOR),
    'popup_category'   : (Color.TEAL__BOLD,            Background.COLOR),
    'popup_contrast'   : (Color.FG,                    Color.SELECTION),
    'popup_important'  : (Color.RED__BOLD,             Background.COLOR),
    'widget_disabled'  : (Color.COMMENT,               Background.COLOR),
    'area:help'        : (Color.BG,                    Color.GREEN),
    'area:msg'         : (Color.BG,                    Color.GOLD),
    'area:stream'      : (Color.BG,                    Color.TEAL),
    'area:error'       : (Color.FG,                    Color.RED),
    'area:user'        : (Color.BG,                    Color.ORANGE),
    'search_error'     : (Color.RED,                   Background.COLOR),
    'task:success'     : (Color.BG,                    Color.GREEN),
    'task:error'       : (Color.FG,                    Color.RED),
    'task:warning'     : (Color.BG,                    Color.GOLD),
    'ui_code'          : (Color.BG,                    Color.FG),
}

META = {
    'background': Color.BG,
    'pygments': {
        'styles'    : MonokaiStyle().styles,
        'background': 'h52',  # #2C001E approximation
        'overrides' : {
            'c'   : '#B7A7B4, italics',    # comments
            'cp'  : '#E95420',              # preprocessor (orange)
            'cpf' : '#B7A7B4',              # comments
            'ge'  : '#F6F5F4, italics',     # emphasis
            'gh'  : '#F6F5F4, bold',        # heading
            'gu'  : '#F6F5F4, underline',   # subheading
            'gp'  : '#19B6EE, bold',        # prompt (teal)
            'gs'  : '#F6F5F4, bold',        # strong
            'err' : '#C7162B',              # error (red)
            'n'   : '#D5CFCA',              # name (fg_dim)
            'p'   : '#D5CFCA',              # punctuation
            'w'   : '#D5CFCA',              # whitespace
            'k'   : '#E95420',              # keyword (orange)
            'kn'  : '#E95420, italics',     # keyword namespace
            's'   : '#26A269',              # string (green)
            'nf'  : '#F99B15',              # function name (gold)
            'nc'  : '#F99B15',              # class name (gold)
        }
    }
}
# fmt: on

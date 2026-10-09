#!/usr/bin/env python3
"""Patch the Besot Haiku (3.1) aurorae theme:
- active titlebar: gray (same palette as the inactive one)
- active buttons: base colour = KDE accent (ColorScheme-ButtonFocus) + white/black
  overlays that reproduce the original yellow shading.
Usage: patch-besot-haiku.py [THEME_DIR]
  (default ~/.local/share/aurorae/themes/besothaiku). Unpatched *.svg files are
  first saved as *.svg.orig; the patch is always rebuilt from those, so re-running
  is safe and a theme upgrade just refreshes the .orig snapshots.
"""
import colorsys, copy, glob, os, re, shutil, sys
from lxml import etree

SVG = '{http://www.w3.org/2000/svg}'
XL = '{http://www.w3.org/1999/xlink}href'
ACCENT_CLASS = 'ColorScheme-ButtonFocus'
BASE_L = 0.5  # lightness of the theme's reference yellow #ffcb00

DECO_MAP = {  # active titlebar yellow -> inactive gray equivalents
    'ffefb4': 'f2f2f2', 'ffcb00': 'd4d4d4', 'fff2c2': 'f6f6f6', 'ffea9c': 'f6f6f6',
    'ecbc00': 'd6d6d6', 'ad9c6a': 'a3a3a3', 'a39364': '7d7d7d',
}


def is_yellow(hexc):
    r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return s > 0.25 and 0.08 < h < 0.2 and 0.05 < l < 0.99 or (l > 0.84 and s > 0.5 and 0.08 < h < 0.2)


def overlay(hexc):
    """(white_opacity, black_opacity) to put on top of the accent colour."""
    r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))
    l = colorsys.rgb_to_hls(r, g, b)[1]
    if l >= BASE_L:
        return round((l - BASE_L) / (1 - BASE_L), 3), 0.0
    return 0.0, round((BASE_L - l) / BASE_L, 3)


def set_style(e, key, val):
    s = e.get('style', '')
    if re.search(rf'(^|;){key}:', s):
        s = re.sub(rf'(^|;){key}:[^;]*', rf'\g<1>{key}:{val}', s)
    else:
        s = f'{s};{key}:{val}' if s else f'{key}:{val}'
    e.set('style', s)


def patch_decoration(src, dst):
    txt = open(src).read()
    for a, b in DECO_MAP.items():
        txt = re.sub(f'#{a}', f'#{b}', txt, flags=re.I)
    open(dst, 'w').write(txt)


def patch_button(src, dst):
    tree = etree.parse(src)
    root = tree.getroot()
    ids = {e.get('id'): e for e in root.iter() if e.get('id')}
    defs = root.find(f'{SVG}defs')
    counter = [0]

    def new_id(p):
        counter[0] += 1
        return f'{p}-accent{counter[0]}'

    def stops_of(g):
        while g is not None and not g.findall(f'{SVG}stop'):
            h = g.get(XL)
            g = ids.get(h[1:]) if h else None
        return g.findall(f'{SVG}stop') if g is not None else []

    def stop_color(s):
        m = re.search(r'stop-color:#([0-9a-fA-F]{6})', s.get('style', '')) or \
            re.search(r'#([0-9a-fA-F]{6})', s.get('stop-color', '') or '')
        return m.group(1).lower() if m else None

    def overlay_gradient(grad, which):
        """Clone gradient geometry, with white or black stops."""
        ng = copy.deepcopy(grad)
        for c in list(ng):
            ng.remove(c)
        ng.set('id', new_id(grad.get('id')))
        if XL in ng.attrib:
            del ng.attrib[XL]
        ng.attrib.pop('{http://www.inkscape.org/namespaces/inkscape}collect', None)
        for s in stops_of(grad):
            w, b = overlay(stop_color(s))
            ns = etree.SubElement(ng, f'{SVG}stop')
            ns.set('offset', s.get('offset', '0'))
            ns.set('id', new_id('stop'))
            col, op = ('#ffffff', w) if which == 'w' else ('#000000', b)
            ns.set('style', f'stop-color:{col};stop-opacity:{op}')
        # need explicit geometry attributes from the referenced (non-href) gradient chain
        defs.append(ng)
        return ng.get('id')

    changed = 0
    for g in list(root.iter(f'{SVG}g')):
        gid = g.get('id', '')
        if not gid.endswith('-center') or 'inactive' in gid:
            continue
        for e in list(g.iter()):
            if e.tag == f'{SVG}g':
                continue
            m = re.search(r'fill:([^;]*)', e.get('style', ''))
            if not m:
                continue
            fill = m.group(1).strip()
            overlays = []  # list of (fill, fill-opacity)
            if fill.startswith('#') and len(fill) == 7 and is_yellow(fill[1:]):
                w, b = overlay(fill[1:].lower())
                if w:
                    overlays.append(('#ffffff', w))
                if b:
                    overlays.append(('#000000', b))
            elif fill.startswith('url(#'):
                grad = ids.get(fill[5:-1])
                cols = [stop_color(s) for s in stops_of(grad)]
                if not cols or None in cols or not any(is_yellow(c) for c in cols) \
                        or not all(is_yellow(c) or c == "ffffff" for c in cols):
                    continue
                ovs = [overlay(c) for c in cols]
                if any(w for w, _ in ovs):
                    overlays.append((f'url(#{overlay_gradient(grad, "w")})', 1))
                if any(b for _, b in ovs):
                    overlays.append((f'url(#{overlay_gradient(grad, "b")})', 1))
            else:
                continue
            base_op = re.search(r'fill-opacity:([^;]*)', e.get('style', ''))
            base_op = float(base_op.group(1)) if base_op else 1.0
            # base: accent colour
            set_style(e, 'fill', 'currentColor')
            e.set('class', ACCENT_CLASS)
            idx = e.getparent().index(e)
            for i, (f, op) in enumerate(overlays):
                o = copy.deepcopy(e)
                o.attrib.pop('class', None)
                o.set('id', new_id(e.get('id', 'el')))
                set_style(o, 'fill', f)
                set_style(o, 'fill-opacity', str(round(op * base_op, 3)))
                e.getparent().insert(idx + 1 + i, o)
            changed += 1
    tree.write(dst, xml_declaration=True, encoding='UTF-8', standalone=False)
    return changed


def is_patched(path):
    txt = open(path).read()
    if os.path.basename(path) == 'decoration.svg':
        return not re.search('#(ffcb00|ffefb4|fff2c2)', txt, re.I)
    return '-accent' in txt


def main(theme):
    for svg in sorted(glob.glob(os.path.join(theme, '*.svg'))):
        orig = svg + '.orig'
        if not is_patched(svg):
            shutil.copy2(svg, orig)  # fresh (or upgraded) theme file
        elif not os.path.exists(orig):
            sys.exit(f'{svg} is already patched but {orig} is missing; reinstall the theme')
    for orig in sorted(glob.glob(os.path.join(theme, '*.svg.orig'))):
        dst = orig[:-len('.orig')]
        if os.path.basename(dst) == 'decoration.svg':
            patch_decoration(orig, dst)
            print('decoration.svg: titlebar recoloured gray')
        else:
            print(f'{os.path.basename(dst)}: {patch_button(orig, dst)} elements -> accent')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else
         os.path.expanduser('~/.local/share/aurorae/themes/besothaiku'))

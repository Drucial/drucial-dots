{
  "background": "{{ background }}",
  "foreground": "{{ foreground }}",
  "selection": "{{ selection_background }}",
  "cursor": "{{ cursor }}",
  "ansi": [
    "{{ color0 }}", "{{ color1 }}", "{{ color2 }}", "{{ color3 }}", "{{ color4 }}", "{{ color5 }}", "{{ color6 }}", "{{ color7 }}",
    "{{ color8 }}", "{{ color9 }}", "{{ color10 }}", "{{ color11 }}", "{{ color12 }}", "{{ color13 }}", "{{ color14 }}", "{{ color15 }}"
  ],
  "colors": {
    "canvas": "{{ mix dark_background foreground 3% }}",
    "chrome": "{{ mix darker_background foreground 3% }}",
    "surface": "{{ background }}",
    "raised": "{{ mix background foreground 8% }}",
    "hover": "{{ foreground }}0f",
    "selected": "{{ foreground }}1a",
    "border": "{{ foreground }}20",
    "input": "{{ foreground }}30",
    "muted": "{{ mix foreground darker_background 32% }}",
    "dim": "{{ mix foreground darker_background 48% }}",
    "accent": "{{ accent }}",
    "accent_foreground": "{{ darker_background }}"
  }
}

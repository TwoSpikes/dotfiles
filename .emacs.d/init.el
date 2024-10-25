(when (display-graphic-p)
  (tool-bar-mode 0)
  (scroll-bar-mode 0))
(menu-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)

(rc/require-theme 'gruber-darker)

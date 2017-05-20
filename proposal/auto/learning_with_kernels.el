(TeX-add-style-hook
 "learning_with_kernels"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("inputenc" "latin1")))
   (TeX-run-style-hooks
    "paper-layout"
    "abstract"
    "introduction"
    "hard_margin_svm"
    "kernel_svm"
    "conclusion"
    "inputenc"
    "mathtools"
    "amssymb"
    "amsmath"
    "amsbsy"
    "mathrsfs"
    "color"
    "pgfplots"
    "tikz"
    "relsize"
    "graphicx")
   (LaTeX-add-bibliographies
    "IEEEabrv"
    "references"))
 :latex)


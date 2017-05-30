(TeX-add-style-hook
 "learning_with_kernels"
 (lambda ()
   (TeX-add-symbols
    '("BIBforeignlanguage" 2)
    '("bibinfo" 2)
    '("url" 1)
    "newblock"
    "BIBentrySTDinterwordspacing"
    "BIBentryALTinterwordstretchfactor"
    "BIBentryALTinterwordspacing"
    "relax"
    "BIBdecl")
   (LaTeX-add-bibitems
    "Vapnik:1995:NSL:211359"
    "Schoelkopf95extractingsupport"
    "Decoste2002"
    "lauer:hal"))
 :latex)


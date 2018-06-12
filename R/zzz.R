.onLoad <- function(libname = find.package("inspectEHR"), pkgname = "inspectEHR") {

  env <- parent.env(environment())
    utils::data("qref", package = "inspectEHR")
    utils::data("categorical_hic", package = "inspectEHR")
    utils::data("preserved_classes", package = "inspectEHR")

}

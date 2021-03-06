context("extract")


library("EML")
dat <- data.frame(river = factor(c("SAC",  
                                   "SAC",   
                                   "AM")),
                  spp   = c("Oncorhynchus tshawytscha",  
                            "Oncorhynchus tshawytscha", 
                            "Oncorhynchus kisutch"),
                  stg   = ordered(c("smolt", 
                                    "parr", 
                                    "smolt"), 
                                  levels=c("parr", 
                                           "smolt")), # => parr < smolt
                  ct    = c(293L,    
                            410L,    
                            210L),
                  day   = as.Date(c("2013-09-01", 
                                    "2013-09-1", 
                                    "2013-09-02")),
                  stringsAsFactors = FALSE)
col.defs <- c("River site used for collection",
              "Species scientific name",
              "Life Stage", 
              "count of live fish in traps",
              "day traps were sampled (usually in morning thereof)")

unit.defs <- list(
  c(SAC = "The Sacramento River",     # Factor 
    AM = "The American River"),
 "Scientific name",                   # Character string 
  c(parr = "third life stage",        # Ordered factor 
    smolt = "fourth life stage"),
  c(unit = "number", 
    precision = 1, 
    bounds = c(0, Inf)),              # Integer
  c(format = "YYYY-MM-DD",            # Date
    precision = 1))


S4obj <- eml(dat, col.defs = col.defs, unit.defs = unit.defs, 
             title = "title", creator = "Carl Boettiger <cboettig@gmail.com>")


test_that("we can extract the data unaltered (using method for object 'physical')", {
  out_dat <- eml_get(S4obj, "data.frame") 

  expect_equal(dat[["river"]], out_dat[["river"]])

#  expect_equal(dat, out_dat) ## FIXME not quite, classes differ 
 # expect_identical(dat, out_dat) ## FIXME should be identical, but isn't because integers are cast as eml:ratio which is cast as numeric.  Need to add mechanism for integers EML::detect_class
})


test_that("we can extract from alternative paths", {
  ## Create a subdirectory to make sure we can read when data is not in the working directory
  dir.create("tmp", showWarnings=FALSE)

  ## Let's get the example dataset from the DataONE REST API just for fun
  require(httr)
  id <- "knb-lter-hfr.205.4" # Interestingly, met@packageID ends with `.7`, not `.4` ...
  base <- "https://cn.dataone.org/cn/v1"
  url <- paste(base, "object", id, sep="/")
  dl <- capture.output(GET(url))
  file <- content(GET(url))

  ## Write the file out again just so we can test our reading local paths
  require(XML)
  saveXML(file, "tmp/hf205.xml")

  ## Here's the actual test
  met <- eml_read("tmp/hf205.xml")
  ## FIXME capture.output does not supress messages about download...
  capture.output(dat <- eml_get(met, "data.frame")) # Includes call to extract that must download the CSV file from the address given in the EML
  expect_is(dat, "data.frame")

  ## Cleanup
  unlink("tmp/hf205.xml")
  unlink("tmp/hf205-01-TPexp1.csv")
  unlink("tmp")
  system("rm *.csv")
})



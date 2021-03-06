context("Publish to KNB")


library(EML)
eml_reset_config()
dat = data.set(river = factor(c("SAC",  "SAC",   "AM")),
               spp   = c("Oncorhynchus tshawytscha",  "Oncorhynchus tshawytscha", "Oncorhynchus kisutch"),
               stg   = ordered(c("smolt", "parr", "smolt"), levels=c("parr", "smolt")), # levels indicates increasing level, eg. parr < smolt
               ct    = c(293L,    410L,    210L),
               day   = as.Date(c("2013-09-01", "2013-09-1", "2013-09-02")),
               stringsAsFactors = FALSE, 
               col.defs = c("River site used for collection",
                            "Species scientific name",
                            "Life Stage", 
                            "count of live fish in traps",
                            "day traps were sampled (usually in morning thereof)"),
               unit.defs = list(c(SAC = "The Sacramento River",                         # Factor 
                                  AM = "The American River"),
                                "Scientific name",                                      # Character string (levels not defined)
                                c(parr = "third life stage",                            # Ordered factor 
                                  smolt = "fourth life stage"),
                                c(unit = "number", precision = 1, bounds = c(0, Inf)),  # Integer
                                c(format = "YYYY-MM-DD", precision = 1)))               # Date


eml_write(dat, contact = "Carl Boettiger <cboettig@ropensci.org>", file = "test.xml")



test_that("We can publish data to the KNB", {
  nodeid = "urn:node:mnDemo5" # A Development server for testing
  pid <- EML:::eml_knb("test.xml", 
                 mn_nodeid = nodeid,                   
                 cli = D1Client("DEV", nodeid)) # Use dev mode client

  # check that we can access the data with the dataone client
  Sys.sleep(60*4)
  require(dataone)
  csv <- getD1Object(cli, pid[["csv"]])
  expect_is(asDataFrame(csv), "data.frame")

          })



unlink("test.xml")
unlink("test.csv")


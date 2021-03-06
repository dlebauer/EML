#' eml constructor function 
#' @param dat a data.frame object or path to csv 
#' @param title for the metadata.  Also used as the csv filename.   
#' @param creator a ListOfcreator object, character string, or person object.  
#'  Otherwise loaded from value set by eml_config.  
#' @param contact a contact object, character string, or person object.  
#'  Otherwise loaded from value set by eml_config.  
#' @param coverage a coverage object, such as created by the eml_coverage constructor function. (optional)
#' @param citation a citation object (optional, an EML file can have either 
#' a dataset OR citation OR software OR protocol as its top-level object) 
#' @param software a software object (optional) 
#' @param protocol a protocol object (optional) 
#' @param methods a method object or plain text string, documenting additional methods 
#' @param custom_units a list of custom units. Leave as NULL and these will be automatically
#'  detected from the EMLConfig after a user declares any custom units using
#' \code{\link{eml_define_unit}}.  Advanced users can alternatively just give a list
#' of custom_unit definitions here.  See \code{\link{eml_define_unit}} for details.  
#' @param custom_types custom unit types, from \code{\link{eml_define_unitType}}
#' @param ... additional slots passed to the dataset constructor `new("dataset", ...)`
#' @param additionalMetadata an additionalMetadata object
#' @param col.defs Natural language definitions of each column. Should be a character
#' vector of length equal to each column, defined in the same order as the columns are given.   
#' @param unit.defs A list of length equal to the number of columns defining the units for each column. See examples.  
#' @param col.classes column classes, primarily for use if dat is 
#' a path to a csv rather than a native R object. Optional otherwise.    
#' @import methods
#' @include party_classes.R
#' @include eml_classes.R
#' @export 
eml <- function(dat = NULL,
                title = "EML_metadata",
                creator = NULL, 
                contact = NULL, 
                coverage = eml_coverage(scientific_names = NULL,
                                        dates = NULL,
                                        geographic_description = NULL,
                                        NSEWbox = NULL),
                methods = new("methods"),
                col.defs = NULL,
                unit.defs = NULL,
                col.classes = NULL,
                custom_units =  NULL,
                custom_types = NULL,
                ..., # reserved for the dataset level? 
                additionalMetadata = new("ListOfadditionalMetadata"),
                citation = NULL,
                software = NULL,
                protocol = NULL
                )
{
  ## obtain uuids 
  uid <- eml_id()


  ref_id <- eml_id() # list(id="42") ## Links custom units to attribute defs 
  if(length(custom_units) > 0){
    xml_unitList <- 
      serialize_custom_units(custom_units = custom_units, 
                             id = ref_id[["id"]], 
                             custom_types = custom_types)

    if(!isEmpty(additionalMetadata@.Data))
      additionalMetadata <- new("ListOfadditionalMetadata", 
                                c(additionalMetadata@.Data, xml_unitList))
    else
      additionalMetadata <- new("ListOfadditionalMetadata", 
                                c(xml_unitList))
  }

  ## Initialize
  eml <- new("eml",
             packageId = uid[["id"]], 
             system = uid[["system"]],
             scope = uid[["scope"]], 
             additionalMetadata = additionalMetadata)



  if(!isEmpty(dat)){
    eml@dataset <- 
      eml_dataset(dat = dat, 
                  title = title,
                  creator = creator, 
                  contact = contact,
                  coverage = coverage, 
                  methods = methods,
                  col.defs = col.defs,
                  unit.defs = unit.defs, 
                  col.classes = col.classes,
                  ref_id = ref_id, ...)

  } else if(!isEmpty(citation)){
  ## EML file that just documents a CITATION only
      if(isS4(citation))
      eml@citation <- citation
    else if(is(citation, "BibEntry")){ # handle RefManageR citations
      class(citation) <- "bibentry"
      eml@citation <- bibentryToCitation(citation)
    } else if(is(citation, "bibentry"))
      eml@citation <- bibentryToCitation(citation)
    else
      warning("Citation format not recognized")


  } else if(!isEmpty(software)){
    eml@software <- software

  } else if(!isEmpty(protocol)){
    eml@protocol <- protocol
  }

  eml 
}



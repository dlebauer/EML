#' Define a custom unit
#' 
#' create a custom unit
#' @param id The id of the unit, given in camelCase with `Per` signifying division, Squared for second power, etc.  
#' @param name The name of the unit, by default the same as the id.   
#' @param unitType The type of the unit. 
#' @param parentSI the parent SI unit from the Standard Units list
#' @param multiplierToSI The multiplicative factor to convert the given unit into the parent unit
#' @param constantToSI An additive constant needed for the conversion, such as farenheight to celsius
#' @param abbreviation Optional abbreviation
#' @param description a plain text description of the unit
#' @details Defines a custom unit whose id is used in the unit definition metadata. See https://github.com/ropensci/EML/issues/12 
#' @return The unit definition (invisibly), as a list object.  A list of these returned objects
#' can be passed to the \code{\link{eml}} function directly to define additional units, bypassing
#' the config mechanism used by default.  
#' @export eml_define_unit
#' @examples
#'  eml_define_unit(id = "metersSquaredPerHectare",
#'                  parentSI = "dimensionless",
#'                  unitType = "dimensionless",
#'                  multiplierToSI = "0.0001",
#'                  description = "Square meters per hectare")
#' 
eml_define_unit <- function(id,
                            unitType = NULL,
                            parentSI = NULL, 
                            multiplierToSI = NULL, 
                            name = id, 
                            constantToSI = NULL,
                            abbreviation = NULL,
                            description = NULL){

  ## FIXME Check that unitType is in the library.  
  ## Otherwise, add it with eml_define_unitType

  ## FIXME check that unit isn't already defined

  # FIXME if is nomeric, convert multiplier to a character 
  # without, e.g.,  0.0001 becoming "1e-4"
   
    if(interactive()){
      if(is.null(unitType))
        unitType <- readline(paste("unitType for", id, "not found. Please specify the unitType"))
      if(is.null(multiplierToSI))
        multiplierToSI <- readline(paste("multiplierToSI for", id, "not defined. Please specify the unit conversion factor to the parent SI unit\n"))
      if(is.null(parentSI))
        parentSI <- readline(paste("parentSI for", id, "not defined. Please specify the parent unit in the SI system\n"))
    }

    # FIXME Make sure id is camelcase first or convert it to such
    if(is.null(description))
      description <- camelCase_to_human(id)


    unit.def <- new("stmml_unit", 
                    id = id, 
                    multiplierToSI = multiplierToSI, 
                    name = name, 
                    parentSI = parentSI, 
                    unitType = unitType,
                    description = description)

}



camelCase_to_human <- function(x){
  x <- gsub('([a-z]+)([A-Z][a-z]+)', '\\1 \\2', x)
  x <- gsub('([a-z]+)([A-Z][a-z]+)', '\\1 \\2', x)
}




serialize_custom_units <- 
function(custom_units, 
         id, 
         custom_types=NULL){
  new_types <- 
    lapply(custom_types,
           function(type_def){
             children <- lapply(type_def@dimensions, function(d){

                ## Get non-empty slots
                attrs <- sapply(slotNames(d), function(x) slot(d,x))
                attrs <- attrs[sapply(attrs, length) > 0] 

                newXMLNode("dimension", 
                           attrs = attrs)
              })
            newXMLNode("unitType", 
                       attrs = c(id = type_def@id, 
                                 name = type_def@name),
                       .children = children)
           })
  new_units <- 
    lapply(custom_units, 
           function(unit.def){
             who <- slotNames(unit.def) 
             is_attr <- who[who != "description"]
             attrs <- sapply(is_attr, function(x) slot(unit.def, x))
             attrs <- attrs[sapply(attrs, length) > 0]
             newXMLNode("unit", attrs = attrs, 
                        newXMLNode("description", 
                                   unit.def@description))
           })
  unitList <- newXMLNode("unitList", 
                         .children = c(new_types, new_units))
  new("additionalMetadata",
      describes = id,
      metadata = new("metadata", 
                     unitList))
}
          

# https://knb.ecoinformatics.org/#external//emlparser/docs/eml-2.1.1/eml-unitTypeDefinitions.html#StandardUnitDictionary
# FIXME perform fuzzy matching
is_standard_unit <- function(unit){
  f <- system.file("units", "standard_unit_list.csv", package="EML")
  std_units <- read.csv(f)
  ## check for matches against other columns
  unit %in% std_units[["EML_Name"]]
}

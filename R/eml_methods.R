## Additional METHODS for the eml class ## 


# When printing to screen, use YAML
#' @import yaml 
#' @include eml_yaml.R
setMethod("show", signature("eml"), function(object) show_yaml(object))

setMethod("coverage", signature("eml"),
          function(coverage){
          coverage(coverage@dataset@coverage)
          })


setGeneric("keywords", function(object) standardGeneric("keywords"))
setMethod("keywords", signature("eml"),
          function(object){
            out <- unname(lapply(object@dataset@keywordSet, keywords))
            thes <- sapply(object@dataset@keywordSet, 
                           function(x) x@keywordThesaurus)
            names(out) <- thes
            out
})
setMethod("keywords", signature("keywordSet"), 
          function(object){
           unname(sapply(object@keyword, slot, "keyword"))
})



## FIXME Don't use `@`s to access elements. In particular,
## this isn't even correct since the current format assumes only 
## 1 dataset per eml and one dataTable per dataset.  
## Simple accessor methods should be written instead.  


## accessor methods.  Note that having the same name as an existing function is no problem.  
setGeneric("unit.defs", function(object) standardGeneric("unit.defs"))
setMethod("unit.defs", signature("eml"), function(object){
          metadata <- extract(object@dataset@dataTable[[1]]@attributeList)
          lapply(metadata, function(x) x[[3]])
})


## Make sure this returns a character type! warn if not.  
setGeneric("col.defs", function(object) standardGeneric("col.defs"))
setMethod("col.defs", signature("eml"), function(object){
          metadata <- extract(object@dataset@dataTable[[1]]@attributeList)
          sapply(metadata, function(x) x[[2]])
})


setGeneric("contact", function(object) standardGeneric("contact"))
setMethod("contact", signature("eml"), function(object) as(object@dataset@contact, "person"))

setGeneric("creator", function(object) standardGeneric("creator"))
setMethod("creator", signature("eml"), function(object)
  as(object@dataset@creator, "person"))

#  paste(format(as(object@dataset@creator, "person"), 
#               include=c("given", "family"), 
#               braces = list(family=c("", ""))), collapse=", "))




## FIXME Consider extracting additional fields:  url, key, possibly month, note, etc
#  publisher should possibly be 'journal' (e.g. so it prints by default?) 
setGeneric("citation_info", function(object) standardGeneric("citation_info")) # can overload 'citation' if we didn't set a generic
setMethod("citation_info", signature("eml"), function(object){
              bibentry(bibtype="Manual",
                       title = object@dataset@title,
                       author = creator(object),
                       year = object@dataset@pubDate,
                       publisher = object@dataset@publisher@organizationName)
})


setGeneric("attributeList", function(object) standardGeneric("attributeList"))
setMethod("attributeList", signature("eml"), function(object){
          extract(object@dataset@dataTable[[1]]@attributeList)
})


# FIXME consider downloading to csv_filepath instead of loading immediately into R
setGeneric("get_data.frame", function(object) standardGeneric("get_data.frame"))
setMethod("get_data.frame", signature("eml"), function(object){
          df = extract(object@dataset@dataTable[[1]]@physical)    
})



setGeneric("get_data.set", function(object) standardGeneric("get_data.set"))
setMethod("get_data.set", signature("eml"), function(object){
          df = extract(object@dataset@dataTable[[1]]@physical)    
          data.set(df, 
                   col.defs=col.defs(object), 
                   unit.defs=unit.defs(object))
})


setGeneric("col.classes", function(object) standardGeneric("col.classes"))
setMethod("col.classes", signature("eml"),
          function(object)
            lapply(object@dataset@dataTable, col.classes)) 

setMethod("col.classes", signature("dataTable"),
          function(object)
            get_col.classes(object@attributeList@attribute))




contact_creator <- function(contact = get("defaultContact", envir=EMLConfig), 
                            creator = get("defaultCreator", envir=EMLConfig)){

   ## Get a contact first 
  if(is.null(contact) || length(contact) == 0 || isEmpty(contact)){ # IF no contact given... 
   ## If no creator given either...
    if(is.null(creator) || length(creator) == 0 || isEmpty(creator)){
      if(interactive()){
        contact <- person_wizard("contact")  ## USE THE WIZARD!
      } else { 
        stop("no creator or contact given.")
      }
    ## Else, use the first creator...
    } else {
      if(is(creator, "ListOfcreator"))
        contact <- as(creator[[1]], "contact")
      else 
        contact <- as(creator, "contact")
    }
  } # 
  

  ## Handle cas of contact given as alternative format, e.g. character and person coercions 
  contact <- as(contact, "contact")
  
  ## We now have a contact... If we don't have a creator, use this: 
  if(is.null(creator) || length(creator) == 0 || isEmpty(creator) ){
    creator <- as(contact, "creator")
  }

   if(!is(creator, "ListOfcreator")){
    creator <- c(as(creator, "creator")) # ListOf
  }

  list(contact = contact, creator = creator)
}


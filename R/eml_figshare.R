#' Upload EML to figshare
#' 
#' Modifies the EML file to reflect the figshare
#' @param title of the figshare dataset, 
#' @param description of the dataset,
#' @param categories a category or list of categories, selected from the figshare list: 
#' @param tags at least one tag, any terms are permitted. Tags not required
#' @param links provided in the list on links of the figshare page. optional.
#' @param visibility one of "draft", "public", or "private". 
#' @return the figshare id
#' @details figshare requires authentication. See rfigshare 
#' [tutorial]() for help on configuring this.  
#' Arguments for figshare are optional, if not provided reml will attempt to
#' extract appropriate values from the EML.  If no values are found for 
#' essential metadata (title, description, category), then figshare object
#' will be still be created as a draft but cannot be published.  
#' @import rfigshare
#' @export
#' @examples 
#' \dontrun{
#'    id = eml_figshare("my_eml_data.xml", description="Example EML file from reml", categories = "Ecology", tags = "EML")
#' }
eml_figshare <- function(file, title = NULL, description = NULL, 
                         categories = NULL, tags = NULL, links = NULL, 
                         visibility = NULL){
  doc <- xmlParse(file) 
  root <- xmlRoot(doc)
  if(is.null(title))
    title <- xpathSApply(doc, "//dataTable/entityName", xmlValue)
  if(is.null(description))
    description <- xpathSApply(doc, "//dataTable/entityDescription", xmlValue)
  if(is.null(categories))
    categories <-  xpathSApply(doc, "//dataset/additionalMetadata[@id = 'figshare']/metadata[keywordThesaurus = 'Figshare Categories']", xmlValue) 
  if(is.null(tags))
    tags <-  xpathSApply(doc, "//dataset/additionalMetadata[@id = 'figshare']/metadata[keywordThesaurus = 'Figshare Tags']", xmlValue) 
  if(is.null(links))
    links <-  xpathSApply(doc, "//dataset/additionalMetadata[@id = 'figshare']/metadata/additionalLinks/url", xmlValue) 
  ## If that still doesn't get anything, we're in for an error... 


  id <- fs_create(title=title, description=description, "fileset")
  fs_add_tags(id, tags)
  fs_add_categories(id, categories)


  csv <- xpathSApply(doc, "//dataTable/physical/objectName", xmlValue)

  ## Upload data file
  fs_upload(id, csv)

  ## Extract URL for file (constructed from metadata since can't access download_url until public)
  ## Still, don't think this link will work until file is public.
  ## download_urls should be supported by figshare for private docs eventually... see [47](https://github.com/ropensci/rfigshare/issues/47)
  details <- fs_details(id, mine=TRUE)
  csv_id <- details$files[[1]]$id
  csv_name <- details$files[[1]]$name
  csv_url <- paste("http://files.figshare.com", csv_id, csv_name, sep="/")

  ## Add figshare download URL to EML
  newXMLNode("url", csv_url, attrs = list("function"="download"), parent = 
    newXMLNode("online", parent = 
      newXMLNode("distribution", parent = physical)))
  

  ## Add figshare metadata to EML
  metadata = newXMLNode("metadata", parent = 
    newXMLNode("additionalMetadata", attrs=list(id = 'figshare'), parent=
               root[["dataset"]]))

  ## Tags 
  figshare_tags = newXMLNode("keywordSet", parent = metadata)
  newXMLNode("keywordThesaurus", "figshare Tags", parent = figshare_tags)
  sapply(tags, function(tag) newXMLNode("keyword", tag, parent = figshare_tags))

  ## Categories
  figshare_categories = newXMLNode("keywordSet", parent = metadata)
  newXMLNode("keywordThesaurus", "figshare Categories", parent = figshare_categories)
  sapply(categories, function(categ) newXMLNode("keyword", categ, parent = figshare_categories))

  ## Does the thesuarus specified have to be from reserved keywords?

  ## Additional Links
  if(length(links) > 0){
    additionalLinks = newXMLNode("additionalLinks", parent = metadata)
    sapply(links, function(link) newXMLNode("url", link, parent = additionalLinks))
  }
  ## Write updated EML file (overwrites existing file unless flagged not to)
  saveXML(doc, file)

  ## Upload updated EML file
  fs_upload(id, file)

  if(visibility == "private")
    fs_make_private(id)

  else if(visibility == "public"){
    fs_make_public(id)
  ## If public, add the DOI and other citation information to the EML
  }
  id
}
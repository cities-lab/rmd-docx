## Author: behrica
## Contributor: lmwang
##' url{https://github.com/davidgohel/ReporteRs/issues/68}

##' Creates a docx file with the FlexTable objecta and a caption
##'
##' @param ft The FlexTable to add to the doxc file
##' @param docxFile Path of the docx file to create
##' @param caption The caption text to put above the table
##' @export
makeDocxWithFt <- function(ft, docxFile, caption) {
  docx=officer::read_docx() %>%
    officer::body_add_par(value=caption, style = "table title") %>% 
    officer::shortcuts$slip_in_tableref(depth = 2) %>%
    flextable::body_add_flextable(ft) %>%
    print(target = docxFile) %>% 
    invisible()
}

##' Replaces table in a give docx file with corresponding FlexTable docx files.
##' They are matched by caption.
##'
##' @param inputDocxFile The base docx file to modify
##' @param flexTableDocxFiles List of FlexTable docx files as replacements
##' @param outputDocxFile The output docx file
##' @export
patchFlexTables <- function(inputDocxFile, tableDocx_path, outputDocxFile) {
  require(dplyr)
  require(glue)
  flexTableDocxFiles <- list.files(tableDocx_path, pattern = ".docx", full.names = T)
  tableNodes_new <- flexTableDocxFiles %>%
    purrr::map(function(docx) {
      tableNode <- unz(docx,"word/document.xml") %>%
        readr::read_file() %>%
        xml2::read_xml() %>%
        xml2::xml_find_first("//w:tbl")

      table_num <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(docx))
      print(glue("Found {table_num} in {docx}."))
      list(table_num=table_num, tableNode=tableNode)
    })
  
  
  xml=unz(inputDocxFile,"word/document.xml") %>%
    readr::read_file() %>%
    xml2::read_xml()

  xml2::xml_find_all(xml, "//w:tbl") %>%
    purrr::walk(function(tableNode) {
      tblPr_node <- tableNode %>%
        xml2::xml_find_first("//w:tblPr")
      
      currCaptionText <- tblPr_node %>%
        xml2::xml_find_first(".//w:tblCaption") %>%
        xml2::xml_attr("val")
      
      if (is.na(currCaptionText))
        return()
      
      table_num <- stringr::str_extract(currCaptionText, "^Table [\\d\\.]*[\\d]")
      
      #table_num <- sub(pattern = "(^Table [[:digit:\\.]]*).*$",
      #                 replacement="\\1",
      #                 currCaptionText)

      match <- purrr::detect(tableNodes_new, ~ .x$table_num == table_num)
      print(match)
      if (!is.null(match))
        print(glue("{table_num} in orignal docx matched:\n {match$tableNode %>% as.character()}"))
      
      # 
      # 
      # 
      # captionNode=xml2::xml_new_root("xml",
      #                          xmlns ="http://default",
      #                          "xmlns:w"="http://schemas.openxmlformats.org/wordprocessingml/2006/main") %>%
      #   xml2::xml_add_child("w:tblCaption","w:val"=currCaptionText)
      # 
      # match$tableNode %>%
      #   xml2::xml_find_first(".//w:tblPr") %>%
      #   xml2::xml_add_child(captionNode)
      xml2::xml_replace(match$tableNode %>%
                          xml2::xml_find_first(".//w:tblPr"),
                        tblPr_node)
      
      
      #browser()
      #print(match$tableNode)
      xml2::xml_replace(tableNode, .value=match$tableNode)
      #print(tableNode)
    })
  enhancedDir = tempfile("dir")
  R.utils::mkdirs(enhancedDir)
  unzip(inputDocxFile,exdir=enhancedDir)
  xml2::write_xml(xml,paste0(enhancedDir,"/word/document.xml"))
  outputTempFile <- tempfile(fileext = ".docx")
  
  wd <- getwd()
  setwd(enhancedDir)
  tryCatch({
    zip(outputTempFile,list.files(".","*",full.names = T,recursive = T,all.files = T))
  },finally=setwd(wd))
  
  result <- file.copy(outputTempFile,outputDocxFile,overwrite = T)
  
}

#patchFlexTables("./_book/_main.docx",
#               list.files("./output",pattern = ".docx",full.names = T),
#              "./_book/_main_enhanced1.docx"
#             )
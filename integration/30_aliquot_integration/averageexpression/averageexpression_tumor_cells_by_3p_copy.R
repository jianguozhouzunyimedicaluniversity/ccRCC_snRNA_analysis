#!/usr/bin/env Rscript

## library
packages = c(
  "ggplot2",
  "Seurat",
  "dplyr",
  "plyr",
  "data.table"
)

for (pkg_name_tmp in packages) {
  if (!(pkg_name_tmp %in% installed.packages()[,1])) {
    print(paste0("No ", pkg_name_tmp, " Installed!"))
  } else {
    print(paste0("", pkg_name_tmp, " Installed!"))
  }
  library(package = pkg_name_tmp, character.only = T, quietly = T)
}
cat("Finish loading libraries!\n")
cat("###########################################\n")

## get the path to the seurat object
args = commandArgs(trailingOnly=TRUE)

## argument: directory to the output
path_output_dir <- args[1]
cat(paste0("Path to the output directory: ", path_output_dir, "\n"))
cat("###########################################\n")

## argument 2: filename for the output file
path_output_filename <- args[2]
cat(paste0("Filename for the output: ", path_output_filename, "\n"))
cat("###########################################\n")
path_output <- paste0(path_output_dir, path_output_filename)

## argument : path to seurat object
path_srat <- args[3]
cat(paste0("Path to the seurat object: ", path_srat, "\n"))
cat("###########################################\n")

## input srat
cat(paste0("Start reading the seurat object: ", "\n"))
srat <- readRDS(path_srat)
print("Finish reading the seurat object!\n")
cat("###########################################\n")

## add info to the meta data
metadata_tmp <- srat@meta.data
metadata_tmp$integrated_barcode <- rownames(metadata_tmp)
metadata_tmp$barcode <- str_split_fixed(metadata_tmp$integrated_barcode, pattern = "_", n = 2)[,1]
metadata_tmp <- merge(metadata_tmp, barcode2cnv_df, by = c("orig.ident", "barcode"), by.x = T)

## change identification for the cells to be aliquot id
Idents(srat) <- "orig.ident"

## run average expression
aliquot.averages <- AverageExpression(srat, add.ident = "3p")
print("Finish running AverageExpression!\n")
cat("###########################################\n")

## write output
write.table(aliquot.averages, file = path_output, quote = F, sep = "\t", row.names = T)
cat("Finished saving the output\n")
cat("###########################################\n")

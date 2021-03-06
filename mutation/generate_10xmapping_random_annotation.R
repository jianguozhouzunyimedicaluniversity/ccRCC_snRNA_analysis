# Yige Wu @WashU Oct 2019
## for generating the barcode annotation files (assigned to one random group) for 10Xmapping
## only use barcodes of after QC barcodes so that 10Xmapping won't run forever

# set up libraries and output directory -----------------------------------
## set working directory
baseD = "~/Box/"
setwd(baseD)
source("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/ccRCC_snRNA_analysis/ccRCC_snRNA_shared.R")
## set run id
version_tmp <- 1
run_id <- paste0(format(Sys.Date(), "%Y%m%d") , ".v", version_tmp)
## set output directory
dir_out <- paste0(makeOutDir(), run_id, "/")
dir.create(dir_out)


# input dependencies ------------------------------------------------------
## input seurat object master list
seurat_summary <- fread(input = "./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/summary/ccRCC_snRNA_Downstream_Processing - Seurat_Preprocessing.20200207.v1.tsv", data.table = F)
seurat_summary2process <- seurat_summary %>%
  filter(Cellranger_reference_type == "pre-mRNA") %>%
  filter(Proceed_for_downstream == "Yes") %>%
  mutate(Path_seurat_object = paste0("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/outputs/", Aliquot, FACS, 
                                     "/pf", `pre-filter.low.nCount`, "_fmin", low.nFeautre, "_fmax", high.nFeautre, "_cmin", low.nCount, "_cmax", high.nCount, "_mito_max", high.percent.mito, 
                                     "/", Aliquot, FACS, "_processed.rds"))
seurat_summary2process$Path_seurat_object

# input seurat object -----------------------------------------------------
for (i in 1:nrow(seurat_summary2process)) {
  snRNA_aliquot_id_tmp <- seurat_summary2process$Aliquot[i]
  facs_tmp <- seurat_summary2process$FACS[i]
  path_seurat_obj_tmp <- seurat_summary2process$Path_seurat_object[i]
  seurat_obj_tmp <- readRDS(file = path_seurat_obj_tmp)
  anno_tab_tmp <- seurat_obj_tmp@meta.data
  anno_tab_tmp$barcode <- rownames(anno_tab_tmp)
  anno_tab_tmp <- anno_tab_tmp %>%
    select(barcode) %>%
    mutate(random_group = "0")
  write.table(x = anno_tab_tmp, file = paste0(dir_out, snRNA_aliquot_id_tmp, facs_tmp, "_AfterQC_Barcodes.tsv"), quote = F, row.names = F, sep = "\t", col.names = F)
}



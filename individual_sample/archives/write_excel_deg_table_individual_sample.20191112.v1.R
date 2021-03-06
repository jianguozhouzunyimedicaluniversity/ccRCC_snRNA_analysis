# Yige Wu @WashU Nov 2019
## for generating the DEG excel tables for individual samples

# set working directory ---------------------------------------------------
baseD = "~/Box/"
setwd(baseD)
source("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/ccRCC_snRNA_analysis/ccRCC_snRNA_shared.R")


# set run id --------------------------------------------------------------
version_tmp <- 1
run_id <- paste0(format(Sys.Date(), "%Y%m%d") , ".v", version_tmp)


# set output directory ----------------------------------------------------------
dir_out <- paste0(makeOutDir(), run_id, "/")
dir.create(dir_out)


# set aliquot ids to be processed -----------------------------------------
snRNA_aliquot_ids <- c("CPT0019130004", "CPT0001260013", "CPT0086350004", "CPT0010110013", "CPT0001180011", "CPT0025890002", "CPT0075140002", "CPT0020120013", "CPT0001220012", "CPT0014450005")

# input seurat processing summary ------------------------------------------------
seurat_summary <- fread(input = "./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/summary/ccRCC_snRNA_Downstream_Processing - Seurat_Preprocessing.20191021.v1.tsv", data.table = F)
seurat_summary2process <- seurat_summary %>%
  filter(Cellranger_reference_type == "pre-mRNA") %>%
  filter(Proceed_for_downstream == "Yes") %>%
  filter(Aliquot %in% snRNA_aliquot_ids) %>%
  mutate(Path_seurat_object = paste0("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/outputs/", Aliquot, FACS, 
                                     "/pf", `pre-filter.low.nCount`, "_fmin", low.nFeautre, "_fmax", high.nFeautre, "_cmin", low.nCount, "_cmax", high.nCount, "_mito_max", high.percent.mito, 
                                     "/", Aliquot, FACS, "_processed.rds")) %>%
  mutate(Paht_deg_table = paste0("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/outputs/", Aliquot, FACS, 
                                 "/pf", `pre-filter.low.nCount`, "_fmin", low.nFeautre, "_fmax", high.nFeautre, "_cmin", low.nCount, "_cmax", high.nCount, "_mito_max", high.percent.mito, 
                                 "/", Aliquot, FACS, ".DEGs.Pos.txt"))
seurat_summary2process$Path_seurat_object

# input cluster2celltype table --------------------------------------------
cluster2celltype_tab <- fread(input = "./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/Cell_Type_Assignment/ccRCC_snRNA_Downstream_Processing - Individual.AllCluster2Cell_Type.20191106.v1.tsv", data.table = F)

# plot dotplot by sample --------------------------------------------------
snRNA_aliquot_id_tmp <- "CPT0001220012"
for (snRNA_aliquot_id_tmp in snRNA_aliquot_ids) {
  ## input DEG
  deg_tab_path <- seurat_summary2process$Paht_deg_table[seurat_summary2process$Aliquot == snRNA_aliquot_id_tmp]
  deg_tab_path
  deg_tab <- fread(input = deg_tab_path, data.table = F)
  
  ## get cluster 2 cell type table
  cluster2celltype_tab_tmp <- cluster2celltype_tab %>%
    filter(Aliquot == snRNA_aliquot_id_tmp)
  
  list_DEGs_by_cluster <- list()
  # list_DEGs_by_cluster[["README"]] <- cluster2celltype_tab_tmp
  for (i in unique(deg_tab$cluster)) {
    df2write <- deg_tab %>%
      filter(cluster == i) %>%
      filter(p_val_adj < 0.05) %>%
      arrange(desc(avg_logFC)) %>%
      select(gene, avg_logFC, p_val_adj, pct.1, pct.2, p_val, cluster)
    list_DEGs_by_cluster[[as.character(i)]] <- df2write
  }
  file2write <- paste0(dir_out, snRNA_aliquot_id_tmp, ".AllCluster.DEGs.Pos.", run_id, ".xlsx")
  write.xlsx(list_DEGs_by_cluster, file = file2write)
}



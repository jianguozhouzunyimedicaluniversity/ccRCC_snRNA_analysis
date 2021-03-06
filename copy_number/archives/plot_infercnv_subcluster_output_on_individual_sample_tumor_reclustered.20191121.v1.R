# Yige Wu @WashU Oct 2019

# set working directory ---------------------------------------------------
baseD = "~/Box/"
setwd(baseD)
source("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/ccRCC_snRNA_analysis/ccRCC_snRNA_shared.R")

# set parameters ----------------------------------------------------------
version_tmp <- 1
run_id <- paste0(format(Sys.Date(), "%Y%m%d") , ".v", version_tmp)


# set output directory ----------------------------------------------------
dir_out <- paste0(makeOutDir(), run_id, "/")
dir.create(dir_out)


# set infercnv input id and directory --------------------------------------------
integration_id <- "20191021.v1"
dir_infercnv_output <- "./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/InferCNV/outputs/"


# set aliquot id ----------------------------------------------------------
snRNA_aliquot_ids <- c("CPT0019130004", "CPT0001260013", "CPT0086350004", "CPT0010110013", "CPT0001180011", "CPT0025890002", "CPT0075140002", "CPT0020120013", "CPT0001220012", "CPT0014450005")

# set recluster_tumor_id --------------------------------------------------
recluster_tumor_id <- "20191119.v1"

# input seurat processing summary ------------------------------------------------
seurat_summary <- fread(input = "./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/snRNA_Processed_Data/scRNA_auto/summary/ccRCC_snRNA_Downstream_Processing - Seurat_Preprocessing.20191021.v1.tsv", data.table = F)
seurat_summary2process <- seurat_summary %>%
  filter(Cellranger_reference_type == "pre-mRNA") %>%
  filter(Proceed_for_downstream == "Yes") %>%
  filter(Aliquot %in% snRNA_aliquot_ids) %>%
  mutate(Path_seurat_object = paste0("./Ding_Lab/Projects_Current/RCC/ccRCC_snRNA/Resources/Analysis_Results/individual_cluster/recluster_tumor/", recluster_tumor_id, "/", Aliquot, FACS, 
                                     "/", Aliquot, FACS, ".Malignant_Reclustered.", recluster_tumor_id, ".RDS"))
seurat_summary2process$Path_seurat_object


# set genes to plot -------------------------------------------------------
genes2plot <- ccrcc_cna_genes_df$gene_symbol

# plot by each aliquot ----------------------------------------------------
snRNA_aliquot_id_tmp <- "CPT0001220012"

for (snRNA_aliquot_id_tmp in snRNA_aliquot_ids) {
  dir_out_tmp <- paste0(dir_out, snRNA_aliquot_id_tmp, "/")
  dir.create(dir_out_tmp)
  
  # input individually processed seurat object ---------------------------------------------
  seurat_obj_path <- seurat_summary2process$Path_seurat_object[seurat_summary2process$Aliquot == snRNA_aliquot_id_tmp]
  seurat_obj_path
  seurat_object <- readRDS(file = seurat_obj_path)
  
  # get umap coordinates ----------------------------------------------------
  umap_tab <- FetchData(seurat_object, vars = c("orig.ident", "ident", "UMAP_1", "UMAP_2"))
  umap_tab$barcode <- rownames(umap_tab)
  
  p <- DimPlot(seurat_object, reduction = "umap", label = T, label.size	= 5, repel = T)
  label_data <- p$layers[[2]]$data

  # input infercnv observations ---------------------------------------------
  tumor_cnv_state_mat <- fread(input = paste0(dir_infercnv_output, "integration.", integration_id, "/", snRNA_aliquot_id_tmp, "/infercnv.14_HMM_predHMMi6.rand_trees.hmm_mode-subclusters.Pnorm_0.5.repr_intensities.observations.txt"), data.table = F)
  ref_cnv_state_mat <- fread(input = paste0(dir_infercnv_output, "integration.", integration_id, "/", snRNA_aliquot_id_tmp, "/infercnv.14_HMM_predHMMi6.rand_trees.hmm_mode-subclusters.Pnorm_0.5.repr_intensities.references.txt"), data.table = F)
  dim(tumor_cnv_state_mat)
  dim(ref_cnv_state_mat)
  
  cnv_state_df <- rbind(melt(tumor_cnv_state_mat, id.vars = c("V1")), melt(ref_cnv_state_mat, id.vars = c("V1")))
  
  for (gene_tmp in genes2plot) {
    if (gene_tmp %in% cnv_state_df$V1) {
      infercnv_observe_gene_tab <- cnv_state_df %>%
        rename(gene_symbol = V1) %>%
        filter(gene_symbol == gene_tmp) %>%
        mutate(barcode = str_split_fixed(string = variable, pattern = "_", n = 2)[,1]) %>%
        rename(copy_state = value) %>%
        select(gene_symbol, barcode, copy_state)
      

      tab2p <- umap_tab
      tab2p <- merge(tab2p, infercnv_observe_gene_tab, by = c("barcode"), all.x = T)
      tab2p$cnv_cat <- map_infercnv_state2category(copy_state = tab2p$copy_state)
      tab2p$cnv_cat %>% table()
      
      tab2p <- tab2p %>%
        arrange(desc(cnv_cat))
      
      
      # plot a UMAP plot for copy number metric ---------------------------------
      p <- ggplot() +
        geom_point(data = tab2p, mapping = aes(UMAP_1, UMAP_2, color=cnv_cat), alpha = 1, size = 0.3) +
        scale_color_manual(values = copy_number_colors) +
        ggtitle(paste0(snRNA_aliquot_id_tmp, "_", gene_tmp, "_Copy_Number_Status"))
      p <- p + geom_text_repel(data = label_data, mapping = aes(UMAP_1, UMAP_2, label = ident))
      p <- p + theme_bw() +
        theme(panel.border = element_blank(), panel.grid.major = element_blank(),
              panel.grid.minor = element_blank())
      p <- p + ggplot2::theme(axis.line=element_blank(),axis.text.x=element_blank(),
                              axis.text.y=element_blank(),axis.ticks=element_blank(),
                              axis.title.x=element_blank(),
                              axis.title.y=element_blank())
      file2write <- paste(dir_out_tmp, snRNA_aliquot_id_tmp,".Individual_Clustered.", gene_tmp, ".FeaturePlot_CNA.ClusterID.", run_id, ".png", sep="")
      png(file2write, width = 1100, height = 800, res = 150)
      print(p)
      dev.off()
      
    } else {
      print(paste0(gene_tmp, " not in the infercnv result!"))
    }
  }
}


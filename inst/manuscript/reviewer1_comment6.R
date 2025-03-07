# library(pbapply)
# load('TREM2/Results/GSE130626.RData')
# WT <- GSE130626$WT
# sum(WT['Trem2', ] != 0)
# set.seed(1)
# allDR <- pblapply(1:100, function(X){
#   sGenes <- unique(c('Trem2', sample(rownames(WT), 1000)))
#   tWT <- WT[sGenes, sGenes]
#   tKO <- tWT
#   tKO['Trem2',] <- 0
#
#   DR <- scTenifoldKnk:::dRegulation(scTenifoldNet::manifoldAlignment(tWT, tKO, d = 2),1)
#   return(DR)
# })
# drGenes <- lapply(allDR, function(X){X$gene[X$p.adj < 0.05]})
# allGenes <- lapply(allDR, function(X){X$gene})
# allGenes <- table(unlist(allGenes))
# drGenes <- table(unlist(drGenes))
# sGenes <- intersect(names(allGenes), names(drGenes))
# O <- data.frame(n.tested=(drGenes[sGenes]/allGenes[sGenes]), n = allGenes[sGenes])
# O <- O[order(O$n.tested.Freq, decreasing = TRUE),]
# writeLines(as.vector(O$n.tested.Var1)[O$n.tested.Freq > 0.8])


library(Matrix)
library(scTenifoldKnk)
library(parallel)
library(pbapply)

# TREM2
cl <- makeCluster(getOption("cl.cores", 10))
ignore <- clusterEvalQ(cl, expr = library(scTenifoldKnk))
ignore <- clusterEvalQ(cl, expr = library(Matrix))

pbsapply(X = 1:100, cl = cl, FUN =  function(X){
  CM <- read.csv('GSE130626_umi_counts.csv.gz')
  MD <- read.csv('GSE130626_cell_info.csv.gz', stringsAsFactors = FALSE)
  GD <- read.csv('GSE130626_gene_info.csv.gz', stringsAsFactors = FALSE)

  CM <- CM[!is.na(GD$symbol),]
  GD <- GD[!is.na(GD$symbol),]

  rownames(CM) <- make.unique(GD$symbol)

  MD <- MD[((MD$treatment %in% 'cuprizone') & (MD$trem2_genotype %in% c('WT'))),]
  CM <- CM[,MD$cell_id]
  CM <- Matrix(as.matrix(CM))
  set.seed(X)
  selCells <- sample(colnames(CM), size = round(0.75 * ncol(CM)))
  tCM <- CM[,selCells]
  tCM <- tCM[rowMeans(tCM != 0) > 0.1,,drop = FALSE]
  O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
  save(O, file = paste0('Trem2_r',X,'.RData'))
})

# set.seed(2)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r2.RData')

# set.seed(3)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r3.RData')

# set.seed(4)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r4.RData')

# set.seed(5)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r5.RData')

# set.seed(6)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r6.RData')

# set.seed(7)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r7.RData')

# set.seed(8)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r8.RData')

# set.seed(9)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r9.RData')

# set.seed(10)
# tCM <- CM[,sample(colnames(CM), size = 0.75 * ncol(CM))]
# tCM <- tCM[rowMeans(tCM != 0) > 0.1,]
# O <- scTenifoldKnk::scTenifoldKnk(tCM, gKO = 'Trem2')
# save(O, file = 'Trem2r10.RData')

drGenes <- lapply(1:5, function(X){
  load(paste0('reviewer1_comment6/Trem2r',X,'.RData'))
  O$diffRegulation$gene[O$diffRegulation$p.adj < 0.05]
})
names(drGenes) <- paste0('R',1:5)
png('reviewer1_comment6a.png', width = 2500, height = 1500, res = 300)
upset(fromList(drGenes))
dev.off()

drGenes <- sort(table(unlist(drGenes)), decreasing = TRUE)/5
length(drGenes)
# 246 at least once identified diferentially regulated genes after Trem2 knockout
drGenes <- names(drGenes[drGenes > 0.8])
length(drGenes)
# 34 genes identified to be diferentially regulated genes after Trem2 knockout above 80% of the time Ank, Anxa5, Aplp2, Apoe, Axl, Bola2, Capg, Ccl6, Cd52, Cd63, Cd72, Cd9, Cst7, Cstb, Ctsb, Cxcl14, Cxcl16, Cybb, Fabp5, Fth1, Fxyd5, Gm49339, Igf1, Il4i1, Itgax, Lgals3, Lpl, Lrpap1, Lyz2, Rab7b, Spp1, Tmsb10, Trem2, Vat1

drOutput <- lapply(1:5, function(X){
  load(paste0('reviewer1_comment6/Trem2r',X,'.RData'))
  write.csv(O$diffRegulation, file = paste0('reviewer1_comment6/Trem2r',X,'.csv'), row.names = FALSE)
  Z <- O$diffRegulation$Z
  names(Z) <- O$diffRegulation$gene
  return(Z)
})

allGenes <- unique(unlist(lapply(drOutput, names)))

allZ <- t(do.call(rbind.data.frame,lapply(drOutput, function(X){X[allGenes]})))
rownames(allZ) <- allGenes
allZ <- allZ[complete.cases(allZ),]
allZ <- allZ[order(apply(apply(allZ,2,rank),1,mean), decreasing = TRUE),]
colnames(allZ) <- paste0('R', 1:5)

library(ComplexHeatmap)
png(filename = 'reviewer1_comment6.png', width = 700, height = 2500, res = 300)
Heatmap(allZ, show_row_names = FALSE, show_row_dend = FALSE, name = 'Z') +
  rowAnnotation(link = anno_mark(at = which(rownames(allZ)%in%drGenes), labels = rownames(allZ)[rownames(allZ)%in%drGenes]))
dev.off()


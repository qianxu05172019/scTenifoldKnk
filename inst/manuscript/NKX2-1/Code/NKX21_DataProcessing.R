# setwd('/data/dcosorioh/manuscript/')
#
# library(Matrix)
# scTenifoldKnk <- function(countMatrix, gKO = NULL){
#   set.seed(1)
#   WT <- scTenifoldNet::makeNetworks(countMatrix, q = 0.9)
#   set.seed(1)
#   WT <- scTenifoldNet::tensorDecomposition(WT)
#   WT <- as.matrix(WT$X)
#   #KO <- rCUR::CUR(WT, sv = RSpectra::svds(WT, 5))
#   #C <- KO@C
#   #C[gKO,] <- 0
#   #KO <- C %*% KO@U %*% KO@R
#   KO <- WT
#   KO[gKO,] <- 0
#   set.seed(1)
#   MA <- scTenifoldNet::manifoldAlignment(WT, KO)
#   set.seed(1)
#   DR <- scTenifoldNet::dRegulation(MA)
#   outputList <- list()
#   outputList$WT <- WT
#   outputList$KO <- KO
#   outputList$diffRegulation <- DR
#   return(outputList)
# }
# source('https://raw.githubusercontent.com/dosorio/utilities/master/singleCell/scQC.R')
#
# WT <- readMM('NKX2-1/Data/GSM3716703_Nkx2-1_control_scRNAseq_matrix.mtx.gz')
# rownames(WT) <- read.csv('NKX2-1/Data/GSM3716703_Nkx2-1_control_scRNAseq_genes.tsv.gz', sep = '\t', header = FALSE, stringsAsFactors = FALSE)[,2]
# colnames(WT) <- readLines('NKX2-1/Data/GSM3716703_Nkx2-1_control_scRNAseq_barcodes.tsv.gz')
# WT <- scQC(WT)
# WT <- WT[rowMeans(WT != 0) > 0.05,]
# WT <- WT[!grepl('^Rp[[:digit:]]+|^Rpl|^Rps|^Mt-', rownames(WT), ignore.case = TRUE),]
# WT <- scTenifoldKnk(WT, gKO = 'Nkx2-1')
# save(WT, file = 'NKX21_GSM3716703.RData')
library(fgsea)
library(ggplot2)
library(enrichR)
library(igraph)
source('https://raw.githubusercontent.com/dosorio/utilities/master/singleCell/plotDR.R')
source('https://raw.githubusercontent.com/dosorio/utilities/master/singleCell/plotKO.R')
source('https://raw.githubusercontent.com/dosorio/utilities/master/idConvert/hsa2mmu_SYMBOL.R')

load('../Results/GSM3716703.RData')
write.csv(GSM3716703$diffRegulation, '../Results/dr_GSM3716703.csv')
#GSM3716703 <- WT
markerGenes <- read.csv('../Data/pnas.1906663116.sd01.csv', stringsAsFactors = FALSE, row.names = 1)
markerGenes$T.test.p.value <- as.numeric(markerGenes$T.test.p.value)
markerGenes <- markerGenes[complete.cases(markerGenes),]
markerGenesAT1 <- markerGenes$gene_short_name[markerGenes$T.test.p.value < 0.05]

markerGenes <- read.csv('../Data/pnas.1906663116.sd05.csv', stringsAsFactors = FALSE)
markerGenes <- markerGenes[,1:10]
markerGenes$T.test.p.value <- as.numeric(markerGenes$T.test.p.value)
markerGenes <- markerGenes[complete.cases(markerGenes),]
markerGenesAT2 <- markerGenes$gene_short_name[markerGenes$T.test.p.value < 0.05]

markerGenes <- unique(c(markerGenesAT1, markerGenesAT2))
dGenes <- GSM3716703$diffRegulation$gene[GSM3716703$diffRegulation$p.adj < 0.01]

png('../Results/dr2_GSM3716703.png', width = 2500, height = 2500, res = 300)
plotDR(GSM3716703, boldGenes = dGenes[dGenes %in% markerGenes])
dev.off()

png('../Results/ego2_GSM3716703.png', width = 5000,height = 5000, res = 300, pointsize = 20, bg = NA)
X <- GSM3716703
gKO <- 'Nkx2-1'
q <- 0.995
gList <- unique(c(gKO, X$diffRegulation$gene[X$diffRegulation$p.adj < 0.05]))
sCluster <- as.matrix(X$WT[gList,gList])
koInfo <- sCluster[gKO,]
sCluster[abs(sCluster) <= quantile(abs(sCluster), q)] <- 0
sCluster[gKO,] <- koInfo
diag(sCluster) <- 0
sCluster <-  reshape2::melt(as.matrix(sCluster))
colnames(sCluster) <- c('from', 'to', 'W')
sCluster <- sCluster[sCluster$W != 0,]
netPlot <- graph_from_data_frame(sCluster, directed = TRUE)
dPlot <- centr_degree(netPlot)$res
W <- rep(1,nrow(sCluster))
sG   <- (names(V(netPlot))[dPlot > 1])[-1]
W[sCluster$from %in% sG] <- 0.2
W[sCluster$to %in% sG] <- 0.2
W[sCluster$from %in% gKO] <- 1
W[sCluster$from %in% gKO & sCluster$to %in% sG] <- 0.8
set.seed(1)
layPlot <- layout_with_fr(netPlot, weights = W)
dPlot <- (dPlot/max(dPlot))*20
E <- enrichr(gList, c("BioPlanet_2019", "KEGG_2019_Mouse", "Reactome_2016","GO_Biological_Process_2018", "GO_Molecular_Function_2018", "GO_Cellular_Component_2018"))
E <- do.call(rbind.data.frame, E)
E <- E[E$Adjusted.P.value < 0.05,]
E <- E[order(E$Adjusted.P.value),]
E$Term <- unlist(lapply(strsplit(E$Term,''), function(X){
  X[1] <- toupper(X[1])
  X <- paste0(X,collapse = '')
  X <- gsub('\\([[:print:]]+\\)|Homo[[:print:]]+|WP[[:digit:]]+','',X)
  X <- gsub("'s",'',X)
  X <- unlist(strsplit(X,','))[1]
  X <- gsub('[[:blank:]]$','',X)
  return(X)
}))
E <- E[c(1,2,3,6,8),]
tPlot <- strsplit(E$Genes, ';')
pPlot <- matrix(0,nrow = length(V(netPlot)), ncol = nrow(E))
rownames(pPlot) <- toupper(names(V(netPlot)))
for(i in seq_along(tPlot)){
  pPlot[unlist(tPlot[i]),i] <- 1
}
pPlot <- lapply(seq_len(nrow(pPlot)), function(X){as.vector(pPlot[X,])})
names(pPlot) <- names(V(netPlot))
tPlot <- unique(unlist(tPlot))
eGenes <- toupper(names(V(netPlot))) %in% tPlot
vColor <- rgb(195/255, 199/255, 198/255 ,0.3)
pieColors <- list(hcl.colors(nrow(E), palette = 'Zissou 1', alpha = 0.7))
par(mar=c(4,0,0,0), xpd = TRUE)
suppressWarnings(plot(netPlot,
                      layout = layPlot,
                      edge.arrow.size=.2,
                      vertex.label.color="black",
                      vertex.shape = ifelse(eGenes,'pie','circle'),
                      vertex.pie = pPlot,
                      vertex.size = 10+dPlot,
                      vertex.pie.color=pieColors,
                      vertex.label.family="Times",
                      vertex.label.font=ifelse(eGenes,2,1),
                      edge.color = ifelse(E(netPlot)$W > 0, 'red', 'blue'),
                      edge.curved = ifelse(W == 0.2, 0, 0.1),
                      vertex.color = vColor,
                      vertex.frame.color = NA))
sigLevel <- formatC(E$Adjusted.P.value, digits = 2, format = 'g', width = 0, drop0trailing = TRUE)
gSetNames <- lengths(strsplit(E$Genes, ';'))
gSetNames <- paste0('(', gSetNames,') ', E$Term, ' FDR = ', sigLevel)
legend(x = -1.05, y = -1.05, legend = gSetNames, bty = 'n', ncol = 2, cex = 1, col = unlist(pieColors), pch = 16)
dev.off()

CT <- read.csv('../Data/PanglaoDB_markers_27_Mar_2020.tsv', header = TRUE, sep = '\t', stringsAsFactors = FALSE)
namesCT <- unique(CT$cell.type)
CT <- lapply(namesCT, function(X){
  CT$official.gene.symbol[CT$cell.type %in% X]
})
names(CT) <- namesCT

zGSM3716703 <- GSM3716703$diffRegulation$Z
names(zGSM3716703) <- toupper(GSM3716703$diffRegulation$gene)
set.seed(1)
GSEA <- fgseaMultilevel(CT, zGSM3716703)
GSEA <- GSEA[order(GSEA$padj),]

png('../Results/gsea1_GSM3716703.png', width = 1000, height = 1000, res = 300)
gSet <- 'Pulmonary alveolar type I cells'
plotEnrichment(CT[[gSet]], zGSM3716703) +
  labs(title = 'Pulmonary\nalveolar\ntype I cells', subtitle = paste0('FDR = ', formatC(GSEA$padj[GSEA$pathway %in% gSet], digits = 2, format = 'e'))) +
  xlab('Gene rank') + ylab('Enrichment Score') + theme(plot.title = element_text(face = 2, size = 25))
dev.off()

png('../Results/gsea2_GSM3716703.png', width = 1000, height = 1000, res = 300)
gSet <- 'Pulmonary alveolar type II cells'
plotEnrichment(CT[[gSet]], zGSM3716703) +
  labs(title = 'Pulmonary\nalveolar\ntype II cells', subtitle = paste0('FDR = ', formatC(GSEA$padj[GSEA$pathway %in% gSet], digits = 2, format = 'e'))) +
  xlab('Gene rank') + ylab('Enrichment Score') + theme(plot.title = element_text(face = 2, size = 25))
dev.off()

REACTOME <- gmtPathways('https://amp.pharm.mssm.edu/Enrichr/geneSetLibrary?mode=text&libraryName=Reactome_2016')
set.seed(1)
Enrichment <- fgseaMultilevel(REACTOME, zGSM3716703)
Enrichment <- Enrichment[Enrichment$NES > 0 & Enrichment$padj < 0.05,]
png('../Results/gsea3_GSM3716703.png', width = 1000, height = 1000, res = 300)
gSet <- "Extracellular matrix organization Homo sapiens R-HSA-1474244"
plotEnrichment(REACTOME[[gSet]], zGSM3716703) +
  labs(title = "Extracellular\nmatrix\norganization", subtitle = paste0('FDR = ', formatC(Enrichment$padj[Enrichment$pathway %in% gSet], digits = 2, format = 'e'))) +
  xlab('Gene rank') + ylab('Enrichment Score') + theme(plot.title = element_text(face = 2, size = 25))
dev.off()

CC <- gmtPathways('https://amp.pharm.mssm.edu/Enrichr/geneSetLibrary?mode=text&libraryName=GO_Cellular_Component_2018')
set.seed(1)
ccEnrichment <- fgseaMultilevel(CC, zGSM3716703)
ccEnrichment <- ccEnrichment[ccEnrichment$NES > 0,]
ccEnrichment <- ccEnrichment[ccEnrichment$padj < 0.05,]

png('../Results/gsea4_GSM3716703.png', width = 1000, height = 1000, res = 300)
gSet <- "microvillus (GO:0005902)"
plotEnrichment(CC[[gSet]], zGSM3716703) +
  labs(title = "Microvillus\n(GO:0005902)", subtitle = paste0('FDR = ', formatC(ccEnrichment$padj[ccEnrichment$pathway %in% gSet], digits = 2, format = 'e'))) +
  xlab('Gene rank') + ylab('Enrichment Score') + theme(plot.title = element_text(face = 2, size = 25))
dev.off()

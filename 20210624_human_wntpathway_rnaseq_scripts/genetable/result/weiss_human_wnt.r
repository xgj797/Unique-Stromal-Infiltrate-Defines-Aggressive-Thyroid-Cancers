rm(list=ls()) 
outFile=''
parSampleFile1='fileList1.txt'
parSampleFile2='fileList2.txt'
parSampleFile3=''
parFile1=''
parFile2=''
parFile3=''
outputPdf<-TRUE;outputPng<-TRUE;outputTIFF<-FALSE;showVolcanoLegend<-TRUE;usePearsonInHCA<-TRUE;showLabelInPCA<-TRUE;useGreenRedColorInHCA<-TRUE;top25cvInHCA<-FALSE;

setwd('/scratch/weissvl/shengq2/20210624_human_wntpathway_rnaseq/genetable/result')

source("countTableVisFunctions.R")
options(bitmapType='cairo')

library(heatmap3)
library(DESeq2)  
library(RColorBrewer)
library(colorRamps)
library(genefilter)

countTableFileList<-parSampleFile1
groupFileList<-parSampleFile2
if (exists("parSampleFile3")) {
  colorFileList<-parSampleFile3
} else {
    colorFileList<-""
}

fixColorRange<-TRUE

geneFile<-parFile1
totalCountFile<-parFile3

if(!exists("onlySamplesInGroup")){
  onlySamplesInGroup=FALSE
}

if(!exists("outputPdf")){
  outputPdf<-FALSE
}

if(!exists("outputPng") | !outputPdf ){
  outputPng<-TRUE
}

outputFormat<-c()
if(outputPdf){
  outputFormat<-c("PDF")
}
if(outputPng){
  outputFormat<-c(outputFormat, "PNG")
}

if(!exists("hasRowNames")){
  hasRowNames<-NA
}

if(exists("useGreenRedColorInHCA") && useGreenRedColorInHCA){
  hmcols <- colorRampPalette(c("green", "black", "red"))(256)
}else{
  hmcols <- colorRampPalette(rev(brewer.pal(n = 7, name ="RdYlBu")))(100)
}

if(exists("usePearsonInHCA") && usePearsonInHCA){
  distf <- function(x) as.dist(1 - cor(t(x), use = "pa"))
}else{
  distf <- dist
}

if(!exists("useGroupAsBatch")){
  useGroupAsBatch<-FALSE
}

if(!exists("showLabelInPCA")){
  showLabelInPCA<-TRUE
}

if(!exists("transformTable")){
  transformTable<-FALSE
}

if(!exists("suffix")){
  suffix<-""
}

task_suffix<-suffix

if(!exists("outputDirectory")){
  outputDirectory<-""
}

if (!exists("minMedian")){
  minMedian<-1
}

if (!exists("minMedianInGroup")){
  minMedianInGroup<-1
}

#source("/home/zhaos/source/ngsperl/lib/CQS/countTableVisFunctions.R")

##Solving node stack overflow problem start###
#when there are too many genes, drawing dendrogram may failed due to node stack overflow,
#It could be solved by forcing stats:::plotNode to be run as interpreted code rather then byte-compiled code via a nasty hack.
#http://stackoverflow.com/questions/16559250/error-in-heatmap-2-gplots/25877485#25877485

# Convert a byte-compiled function to an interpreted-code function 
unByteCode <- function(fun)
{
  FUN <- eval(parse(text=deparse(fun)))
  environment(FUN) <- environment(fun)
  FUN
}

# Replace function definition inside of a locked environment **HACK** 
assignEdgewise <- function(name, env, value)
{
  unlockBinding(name, env=env)
  assign( name, envir=env, value=value)
  lockBinding(name, env=env)
  invisible(value)
}

# Replace byte-compiled function in a locked environment with an interpreted-code
# function
unByteCodeAssign <- function(fun)
{
  name <- gsub('^.*::+','', deparse(substitute(fun)))
  FUN <- unByteCode(fun)
  retval <- assignEdgewise(name=name,
                           env=environment(FUN),
                           value=FUN
  )
  invisible(retval)
}

# Use the above functions to convert stats:::plotNode to interpreted-code:
unByteCodeAssign(stats:::plotNode)

# Now raise the interpreted code recursion limit (you may need to adjust this,
#  decreasing if it uses to much memory, increasing if you get a recursion depth error ).
options(expressions=5e4)
drawPCA<-function(filename, rldmatrix, showLabelInPCA, groups, groupColors, outputFormat){
  genecount<-nrow(rldmatrix)
  if(genecount > 2){
    cat("saving PCA to ", filename, "\n")
    pca<-prcomp(t(rldmatrix))
    supca<-summary(pca)$importance
    pcadata<-data.frame(pca$x)
    pcalabs=paste0(colnames(pcadata), "(", round(supca[2,] * 100), "%)")
    pcadata["sample"]<-row.names(pcadata)
    if(!is.na(groups[1])){
      pcadata$group<-groups
    }
    
    if(showLabelInPCA){
      g <- ggplot(pcadata, aes(x=PC1, y=PC2, label=sample)) + 
        geom_text(vjust=-0.6, size=4)
    }else{
      g <- ggplot(pcadata, aes(x=PC1, y=PC2)) +
        theme(legend.position="top")
    }
    if(!is.na(groups[1])){
      g<-g+geom_point(aes(col=group), size=4) + 
        scale_colour_manual(name="",values = groupColors)
    }else{
      g<-g+geom_point(size=4) 
    }
    g<-g+scale_x_continuous(limits=c(min(pcadata$PC1) * 1.2,max(pcadata$PC1) * 1.2)) +
      scale_y_continuous(limits=c(min(pcadata$PC2) * 1.2,max(pcadata$PC2) * 1.2)) + 
      geom_hline(aes(yintercept=0), size=.2) + 
      geom_vline(aes(xintercept=0), size=.2) + 
      xlab(pcalabs[1]) + ylab(pcalabs[2]) +
      theme_bw2()
    
    for(format in outputFormat){
      if("PDF" == format){
        pdf(paste0(filename, ".pdf"), width=6, height=5)
      }else{
        png(filename=paste0(filename, ".png"), width=3000, height=3000, res=300)
      }
      print(g)
      dev.off()
    }
  }
}

##Solving node stack overflow problem end###

if (geneFile!="") { #visualization based on genes in geneFile only
  genes<-read.table(geneFile, sep="\t", header=F, stringsAsFactors=F)$V1
  print(paste0("There are ", length(genes), " genes in gene file."))
}else{
  genes<-NA
}

if(colorFileList != ""){
  colorsTab<-read.table(colorFileList, sep="\t", header=F, stringsAsFactors=F)
  groupColors<-colorsTab$V1
  names(groupColors)<-colorsTab$V2
}else{
  groupColors<-NA
}

#start work:
countTableFileAll<-read.delim(countTableFileList,header=F,as.is=T,check.names=F)
i<-1
for (i in 1:nrow(countTableFileAll)) {
  countTableFile<-countTableFileAll[i,1]
  
  if(outputDirectory==""){
    outputFilePrefix=countTableFile
  }else{
    bname=basename(countTableFile)
    dpath=dirname(countTableFile)
    dname=basename(dpath)
    while(dname=="result"){
      dpath=dirname(dpath)
      dname=basename(dpath)
    }
    outputFilePrefix=paste0(outputDirectory, "/", dname, "." , bname)
  }
  
  countTableTitle<-countTableFileAll[i,2]
  
  print(paste0("Reading ",countTableFile))
  
  if (grepl(".csv$",countTableFile)) {
    count<-read.csv(countTableFile,header=T,row.names=1,as.is=T,check.names=FALSE)
  } else {
    count<-read.delim(countTableFile,header=T,row.names=1,as.is=T,check.names=FALSE)
  }
  
  if(transformTable){
    count<-t(count)
  }
  
  if (nrow(count)==0) {
    next;
  }
  
  if (ncol(count)<2) {
    next;
  }
  
  if(!is.na(genes)){
    if("Feature_gene_name" %in% colnames(count)){
      curgenes<-c(genes, rownames(count)[count$Feature_gene_name %in% genes])
    }else{
      curgenes<-genes
    }
  }else{
    curgenes<-NA
  }
  
  count[is.na(count)]<-0
  
  colClass<-sapply(count, class)
  countNotNumIndex<-which(colnames(count) %in% c("Feature_length","Location","Sequence") | (colClass!="numeric" & colClass!="integer"))
  if (length(countNotNumIndex)==0) {
    countNotNumIndex<-0;
  } else {
    countNotNumIndex<-max(countNotNumIndex)
  } #Please note here we only use columns after the rightest Non-Number column as count data
  countNum<-count[,c((countNotNumIndex+1):ncol(count))]
  countNum<-round(countNum,0)
  
  #remove genes with total reads 0
  countNum<-countNum[which(rowSums(countNum,na.rm=T)>0),]
  #remove samples with total reads 0
  countNum<-countNum[,which(colSums(countNum,na.rm=T)>0)]
  
  if (groupFileList!="") {
    sampleToGroup<-getSampleInGroup(groupFileList, colnames(countNum), useLeastGroups,onlySamplesInGroup=onlySamplesInGroup)
    if (onlySamplesInGroup) {
      countNum<-countNum[,which(colnames(countNum) %in% as.character(sampleToGroup$V1))]
      #remove genes with total reads 0
      countNum<-countNum[which(rowSums(countNum,na.rm=T)>0),]
    }
  }else{
    sampleToGroup<-data.frame("V1"=colnames(countNum), "V2"="all", "V3"="all")
  }
  
  titles<-unique(sampleToGroup$V3)
  title<-titles[1]
  for(title in titles){
    print(paste0("Processing ", title, " samples"))
    validSampleToGroup<-sampleToGroup[sampleToGroup$V3 == title,,drop=F]
    validSampleToGroup$V2<-factor(validSampleToGroup$V2, levels=sort(unique(validSampleToGroup$V2)))
    
    if(title != "all"){
      curSuffix = paste0(suffix, ".", title)
    }else{
      curSuffix = suffix
    }
    curSuffix<-gsub("\\s+", "_", curSuffix)
    
    write.table(validSampleToGroup, paste0(outputFilePrefix,curSuffix,".correlation.groups"),col.names=F, row.names=F, quote=F, sep="\t")
    
    #filter reads/genes by parameter
    validCountNum<-filterCountTable(countNum,validSampleToGroup,minMedian=minMedian,minMedianInGroup=minMedianInGroup)
    
    #normlize by total reads or VSD
    if (totalCountFile!="") { #normlize with total count *10^6
      totalCount<-read.csv(totalCountFile,header=T,as.is=T,row.names=1,check.names=FALSE)
      totalCount<-unlist(totalCount[totalCountKey,])
      notValidSamples = colnames(validCountNum)[!(colnames(validCountNum) %in% names(totalCount))]
      if (length(notValidSamples) > 0){
        stop(paste0("Sample ", notValidSamples, " not found in total count table ", totalCountFile, "\n"))
      }
      countNumVsd<-10^6*t(t(validCountNum)/totalCount[colnames(validCountNum)])
      write.table(countNumVsd, paste0(outputFilePrefix,curSuffix,".RPM.txt"),col.names=NA, quote=F, sep="\t")
      countNumVsd<-log2(countNumVsd+1)
      ylab<-"log2(Mapped Reads per Million)"
    } else {
      dds=DESeqDataSetFromMatrix(countData = validCountNum, colData = as.data.frame(rep(1,ncol(validCountNum))),design = ~1)
      dds<-try(myEstimateSizeFactors(dds))
      vsdres<-try(temp<-DESeq2::varianceStabilizingTransformation(dds, blind = TRUE))
      if (class(vsdres) == "try-error") {
        message=paste0("Warning: varianceStabilizingTransformation function failed.\n",as.character(vsdres))
        warning(message)
        writeLines(message,paste0(outputFilePrefix,curSuffix,".vsd.warning"))
        next;
      }
      countNumVsd<-assay(temp)
      colnames(countNumVsd)<-colnames(validCountNum)
      write.table(countNumVsd, paste0(outputFilePrefix,curSuffix,".vsd.txt"),col.names=NA, quote=F, sep="\t")
      
      ylab<-"VSD"
    }
    
    if(!is.na(curgenes)){
      countNumVsd<-countNumVsd[rownames(countNumVsd) %in% curgenes,]
      if("Feature_gene_name" %in% colnames(count)){
        geneNames<-count[rownames(countNumVsd), "Feature_gene_name"]
        if(length(unique(geneNames)) == nrow(countNumVsd)){
          rownames(countNumVsd)<-geneNames
        }
      }
      print(paste0("There are ", nrow(countNumVsd), " genes will be used for visualization."))
      write.csv(countNumVsd, paste0(outputFilePrefix,curSuffix,".genes.csv"), quote=F)
    }

    hasMultipleGroup<-length(unique(validSampleToGroup$V2)) > 1
    if (hasMultipleGroup) {
      groups<-validSampleToGroup$V2
      if (is.na(groupColors)){
        colors<-makeColors(length(unique(groups)))
      }else{
        colors<-groupColors
      }
      conditionColors<-as.matrix(data.frame(Group=colors[groups]))
    }else{
      groups<-NA
      colors<-NA
      conditionColors<-NA
    }
    
    #visualization    
    countHT<-countNumVsd

    #density plot
    dataForPlot<-melt(countHT)
    colnames(dataForPlot)[2]<-"Sample"
    p<-ggplot(dataForPlot, aes(value, colour = Sample)) +geom_density() + theme_bw2() + xlab(ylab)
    if(ncol(countHT) > 20){
      p<-p+theme(legend.position = "none")
    }
 
    for(format in outputFormat){
      if("PDF" == format){
        pdf(paste0(outputFilePrefix,curSuffix,".density.pdf"),width=7,height=7)
      }else{
        png(paste0(outputFilePrefix,curSuffix,".density.png"),width=2000,height=2000,res=300)
      }
      print(p)
      dev.off()
    }
    
    #pca plot
    print(paste0("Drawing PCA for ", title, " samples."))
    drawPCA(paste0(outputFilePrefix,curSuffix,".PCA"), countHT, showLabelInPCA, groups, colors, outputFormat)
    
    #hca plot
    hcaOption<-getHeatmapOption(countHT)
    if(!is.na(hasRowNames) & hasRowNames){
      hcaOption$labRow<-NULL
    }
    
    width=min(8000, max(2000, 50 * ncol(countHT)))
    if (ncol(countHT)>1 & nrow(countHT)>1) {
      print(paste0("Drawing heatmap for ", title, " samples."))
      if (hasMultipleGroup) {
        legendfun<-function() showLegend(legend=unique(groups),col=unique(conditionColors[,1]))
      }else{
        legendfun<-NULL
      }
      
      if(exists("top25cvInHCA") && top25cvInHCA){
        rv<-rowVars(countNumVsd)
        countHT<-countNumVsd[rv>=quantile(rv)[4],]
        write.csv(countHT, paste0(outputFilePrefix,curSuffix,".heatmap.top25variance.csv"))
      }

      for(format in outputFormat){
        if("PDF" == format){
          pdf(paste0(outputFilePrefix,curSuffix,".heatmap.pdf"),width=10,height=10)
        }else{
          png(paste0(outputFilePrefix,curSuffix,".heatmap.png"),width=width,height=width,res=300)
        }
        
        if(hasMultipleGroup){
          heatmap3(countHT,distfun=distf,balanceColor=TRUE,useRaster=FALSE,margin=hcaOption$margin,showRowDendro=hcaOption$showRowDendro,labRow=hcaOption$labRow,Rowv=hcaOption$Rowv,col=hmcols,legendfun=legendfun,ColSideColors=conditionColors,cexCol=hcaOption$cexCol)
        } else {
          heatmap3(countHT,distfun=distf,balanceColor=TRUE,useRaster=FALSE,margin=hcaOption$margin,showRowDendro=hcaOption$showRowDendro,labRow=hcaOption$labRow,Rowv=hcaOption$Rowv,col=hmcols,cexCol=hcaOption$cexCol)
        }
        
        dev.off()
      }
    } else {
      print(paste0("Not enough samples or genes. Can't Draw heatmap for ", title, " samples."))
    }
    
    if (ncol(countNumVsd)>1 & nrow(countNumVsd)>1) {
      print("Doing correlation analysis of samples ...")
      #correlation distribution
      countNumCor<-corTableWithoutZero(countNumVsd,method="spearman")
      write.csv(countNumCor, file=paste0(outputFilePrefix,curSuffix,".Correlation.csv"), row.names=T)

      countNumCorTest<-corTestTableWithoutZero(countNumVsd,method="spearman")
      write.csv(countNumCorTest, file=paste0(outputFilePrefix,curSuffix,".Correlation.Test.csv"), row.names=T)
      
      colAll<-colorRampPalette(rev(brewer.pal(n = 7, name ="RdYlBu")))(100)
      if (min(countNumCor,na.rm=T)<0) {
        colAllLabel<-c(-1,0,1)
        if (fixColorRange) {
          col<-col_part(data_all=c(-1,1),data_part=countNumCor,col=colAll)
        } else {
          col<-colAll
        }
      } else {
        colAllLabel<-c(0,0.5,1)
        if (fixColorRange) {
          col<-col_part(data_all=c(0,1),data_part=countNumCor,col=colAll)
        } else {
          col<-colAll
        }
      }
      legendfun<-function(x) {
        par(mar = c(5, 1, 1, 1));
        image(x=1:length(colAll),y=1,z=matrix(1:length(colAll),ncol=1),xlab="",xaxt="n",yaxt="n",col=colAll);
        axis(1,at=c(1,length(colAll)/2,length(colAll)),labels=colAllLabel)
      }
      if (hasMultipleGroup) {
        legendfun<-function() showLegend(legend=unique(groups),col=unique(conditionColors[,1]))
      }
      for(format in outputFormat){
        if("PDF" == format){
          pdf(paste0(outputFilePrefix,curSuffix,".Correlation.pdf"),width=7,height=7)
        }else{
          png(paste0(outputFilePrefix,curSuffix,".Correlation.png"),width=width,height=width,res=300)
        }
        labRow=NULL
        hcaOption<-getHeatmapOption(countNumCor, TRUE)
        if(hasMultipleGroup) { #has group information
          heatmap3(countNumCor[nrow(countNumCor):1,],scale="none",balanceColor=T,labRow=hcaOption$labRow,margin=hcaOption$margin,Rowv=NA,Colv=NA,col=col,legendfun=legendfun,ColSideColors=conditionColors)
        }else{
          heatmap3(countNumCor[nrow(countNumCor):1,],scale="none",balanceColor=T,labRow=hcaOption$labRow,margin=hcaOption$margin,Rowv=NA,Colv=NA,col=col,legendfun=legendfun)
        }
        dev.off()
      }
      
      if (ncol(countNumCor)>3) {
        if (any(is.na(countNumCor)) | length(unique(as.vector(countNumCor)))<=1) {
          print(paste0("NA in correlation matrix or not enought unique values. Can't draw .Correlation.Cluster figure"))
        } else {
          for(format in outputFormat){
            if("PDF" == format){
              pdf(paste0(outputFilePrefix,curSuffix,".Correlation.Cluster.pdf"),width=7, height=7)
            }else{
              png(paste0(outputFilePrefix,curSuffix,".Correlation.Cluster.png"),width=width,height=width,res=300)
            }
            if(hasMultipleGroup){
              temp=try(heatmap3(countNumCor,scale="none",balanceColor=T,labRow=hcaOption$labRow,margin=hcaOption$margin,col=col,legendfun=legendfun,ColSideColors=conditionColors))
            }else{
              temp=try(heatmap3(countNumCor,scale="none",balanceColor=T,labRow=hcaOption$labRow,margin=hcaOption$margin,col=col))
            }
            dev.off()
          }
        }
      }
      
      if (hasMultipleGroup) {
        cexColGroup<-1
        if(length(unique(validSampleToGroup$V2)) < 3){
          saveInError(paste0("Less than 3 groups. Can't do correlation analysis for group table for ",countTableFile),fileSuffix = paste0(suffix,Sys.Date(),".warning"))
          next
        }
        
        countNumVsdGroup<-mergeTableBySampleGroup(countNumVsd,validSampleToGroup)
        
        #heatmap
        hcaOption<-getHeatmapOption(countNumVsdGroup)
        for(format in outputFormat){
          if("PDF" == format){
            pdf(paste0(outputFilePrefix,curSuffix,".Group.heatmap.pdf"),width=10,height=10) 
          }else{
            png(paste0(outputFilePrefix,curSuffix,".Group.heatmap.png"),width=2000,height=2000,res=300)
          }
          heatmap3(countNumVsdGroup,distfun=distf,balanceColor=TRUE,useRaster=FALSE,margin=hcaOption$margin,showRowDendro=hcaOption$showRowDendro,labRow=hcaOption$labRow,Rowv=hcaOption$Rowv,col=hmcols,cexCol=cexColGroup)
          dev.off()
        }
        
        print("Doing correlation analysis of groups ...")
        
        #correlation distribution
        countNumCor<-corTableWithoutZero(countNumVsdGroup,method="spearman")
        write.csv(countNumCor, file=paste0(outputFilePrefix,curSuffix,".Group.Correlation.csv"), row.names=T)

        countNumCorTest<-corTestTableWithoutZero(countNumVsdGroup,method="spearman")
        write.csv(countNumCorTest, file=paste0(outputFilePrefix,curSuffix,".Group.Correlation.Test.csv"), row.names=T)
        
        colAll<-colorRampPalette(rev(brewer.pal(n = 7, name ="RdYlBu")))(100)
        colAllLabel<-c(0,0.5,1)
        countNumCor[countNumCor<0]<-0
        if (fixColorRange) {
          col<-col_part(data_all=c(0,1),data_part=countNumCor,col=colAll)
        } else {
          col<-colAll
        }
        
        legendfun<-function(x) {
          par(mar = c(5, 1, 1, 1));
          image(x=1:length(colAll),y=1,z=matrix(1:length(colAll),ncol=1),xlab="",xaxt="n",yaxt="n",col=colAll);
          axis(1,at=c(1,length(colAll)/2,length(colAll)),labels=colAllLabel)
        }
        
        hcaOption<-getHeatmapOption(countNumCor, TRUE)
        for(format in outputFormat){
          if("PDF" == format){
            pdf(paste0(outputFilePrefix,curSuffix,".Group.Correlation.pdf"),width=10,height=10)
          }else{
            png(paste0(outputFilePrefix,curSuffix,".Group.Correlation.png"),width=2000,height=2000,res=300)
          }
          heatmap3(countNumCor[nrow(countNumCor):1,],scale="none",balanceColor=T,margin=hcaOption$margin,Rowv=NA,Colv=NA,col=col,legendfun=legendfun,cexCol=cexColGroup,cexRow=cexColGroup)
          dev.off()
        }
        
        if (ncol(countNumCor)< 3) {
          saveInError(paste0("Less than 3 samples. Can't do correlation analysis for group table for ",countTableFile),fileSuffix = paste0(outputFilePrefix,suffix,Sys.Date(),".warning"))
        } else {
          if (length(table(countNumCor))==1) {
            saveInError(paste0("Correlation for groups all equal to 1. Can't do correlation analysis for group table for ",countTableFile),fileSuffix = paste0(suffix,Sys.Date(),".warning"))
            next;
          }
          for(format in outputFormat){
            if("PDF" == format){
              pdf(paste0(outputFilePrefix,curSuffix,".Group.Correlation.Cluster.pdf"),width=10, height=10)
            }else{
              png(paste0(outputFilePrefix,curSuffix,".Group.Correlation.Cluster.png"),width=2000,height=2000,res=300)
            }
            heatmap3(countNumCor,scale="none",balanceColor=T,margin=hcaOption$margin,col=col,legendfun=legendfun,cexCol=cexColGroup,cexRow=cexColGroup)
            dev.off()
          }
        }     
      }
    } else {
      print("Not enough samples or genes. Can't do correlation analysis.")
    }
  }
}

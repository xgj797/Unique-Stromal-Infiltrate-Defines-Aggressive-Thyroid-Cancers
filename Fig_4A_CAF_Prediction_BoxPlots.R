### Figure 4A CAF Prediction Boxplots: Information
# This script reads in normalized expression data and immune deconvolution for our cohort of thyroid lesions, filters to non-metastatic lesions, and prints out boxplots for CAF EPIC and CAF MCPCOUNTER prediction algorithms by diagnosis

### Chapters: 
# 1. Load necessary packages
# 2. Read in data file
# 3. Prepare file for making box plots of CAF EPIC and CAF MCPCOUNTER by Diagnosis
# 4. Restrict to non-metastatic lesions of interest
# 5. Rename CAF EPIC and CAF MCPCOUNTER variables
# 6. Log2 Transform CAF EPIC and CAF MCPCOUNTER variables
# 7. Make CAF EPIC and CAF MCPCOUNTER plots by Diagnosis

### Chapter 1. Load necessary packages
library(tidyverse)
library(RColorBrewer)

### Chapter 2. Read in data file
CleanedMergedData <- readRDS(file = "data_in_use/CleanedMergedData_DESeq2NormalizedReads.rds")

### Chapter 3. Prepare file for making box plots of CAF EPIC and CAF MCPCOUNTER by Diagnosis 
# Establish a column for labeling as Follicular, Papillary, or Transformed (will use to color plots)
CleanedMergedData$Category <- "Benign"

# Follicular lesions (these are grouped due to their RAS-like status by BRAF-RAS score)
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "FA" |      # FA = Follicular Adenoma
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "HA" |      # HA = Hurthle Cell Adenoma
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "NIFTP" |   # NIFTP = Noninvasive follicular thyroid neoplasm with papillary-like nuclear features (NIFTP)
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "FTC" |     # FTC = Follicular Thyroid Carcinoma
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "HC" |      # HC = Hurthle Cell Carcinoma 
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "EFVPTC"){  # EFVPTC = Encapsulated Follicular Variant of Papillary Thyroid Carcinoma
        CleanedMergedData$Category[i] <- "Follicular" # Set all of the above variants as "Follicular" for the purpose of coloring plots
  }
}

# Papillary lesions (These are groupeddue to their BRAF-like status by BRAF-RAS score)
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "IFVPTC" | # IFVPTC = Infiltrative Follicular Variant of Papillary Thyroid Carcinoma
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "PTC"){    # PTC = Papillary Thyroid Carcinoma
        CleanedMergedData$Category[i] <- "Papillary" # Set all of the above variants as "Follicular" for the purpose of coloring plots
  }
}

# Transformed lesion
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "PDTC" | # PDTC = Poorly Differentiated Thyroid Carcinoma
     CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC[i] == "ATC"){  # ATC = Anaplastic Thyroid Carcinoma
        CleanedMergedData$Category[i] <- "Transformed" # Set all of the above as "Transformed" for the purpose of coloring plots
  }
}

# Create a new variable to group diagnoses for plotting (Diagnosis_Simplified)
# Grouping FA with HA (FA/HA) and FTC with HC (FTC/HC)
CleanedMergedData$Diagnosis_Simplified <- CleanedMergedData$Diagnosis.with.iFVPTC.and.eFVPTC
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis_Simplified[i] == "FA" | CleanedMergedData$Diagnosis_Simplified[i] == "HA"){
    CleanedMergedData$Diagnosis_Simplified[i] <- "FA/HA"
  }
  else if(CleanedMergedData$Diagnosis_Simplified[i] == "FTC" | CleanedMergedData$Diagnosis_Simplified[i] == "HC"){
    CleanedMergedData$Diagnosis_Simplified[i] <- "FTC/\nHC" # \n creates a space between FTC and HC on the plot
  }
}

# Additional grouping of diagnoses for plotting useing the "Diagnosis_Simplified" variable created above
# Grouping EFVPTC with NIFTP (EFVPTC/NIFTP) and PTC with IFVPTC (PTC/IFVPTC)
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis_Simplified[i] == "NIFTP" | CleanedMergedData$Diagnosis_Simplified[i] == "EFVPTC"){
    CleanedMergedData$Diagnosis_Simplified[i] <- "EFVPTC/\nNIFTP" # \n creates a space between EFVPTC and NIFTP on the plot
  }
  else if(CleanedMergedData$Diagnosis_Simplified[i] == "PTC" | CleanedMergedData$Diagnosis_Simplified[i] == "IFVPTC"){
    CleanedMergedData$Diagnosis_Simplified[i] <- "PTC/\nIFVPTC" # \n creates a space between PTC and IFVPTC on the plot
  }
}

# Create a new variable to add a BRAF and RAS component to the simplified diagnosis
CleanedMergedData$Diagnosis_Simplified_BRS <- CleanedMergedData$Diagnosis_Simplified
CleanedMergedData$Category_BRS <- CleanedMergedData$Category
for(i in 1:nrow(CleanedMergedData)){
  if(CleanedMergedData$Diagnosis_Simplified_BRS[i] == "ATC"){
    if(CleanedMergedData$BRS[i] > 0){ # ATC samples with BRAF-RAS Score (BRS) > 0 are RAS-like
      CleanedMergedData$Diagnosis_Simplified_BRS[i] <- "  ATC \n RAS" # \n creates a space between ATC and RAS for the purpose of plotting
    }
    else if(CleanedMergedData$BRS[i] < 0){ # ATC samples with BRAF-RAS Score (BRS) < 0 are BRAF-like
      CleanedMergedData$Diagnosis_Simplified_BRS[i] <- " ATC \n BRAF" # \n creates a space between ATC and BRAF for the purpose of plotting
    }
  }
}

### Chapter 4. Restrict to non-metastatic lesions of interest
# Restrict to non-metastatic lesions
CleanedMergedData_NonMet <- CleanedMergedData %>% subset(Location.type == "Non-Metastic")

# Restrict to histotypes of interest
CleanedMergedData_NonMet_Restricted <- CleanedMergedData_NonMet %>% subset(Diagnosis_Simplified != "HT" & # Remove # Not plotting Hashimoto's thyroiditis (HT)
                                                                           Diagnosis_Simplified != "MNG" &  # Not plotting multinodular goiter (MNG)
                                                                           Diagnosis.with.HTPTC != "HTPTC") # Excluding PTC samples with background Hashimoto's thyroiditis due to confounding expression of iCAF markers


### Chapter 5. Rename CAF EPIC and CAF MCPCOUNTER variables
# CAF EPIC and CAF MCPCOUNTER renaming
CleanedMergedData_NonMet_Restricted <- CleanedMergedData_NonMet_Restricted %>% dplyr::rename("CAF_EPIC" = "Cancer associated fibroblast_EPIC")
CleanedMergedData_NonMet_Restricted <- CleanedMergedData_NonMet_Restricted %>% dplyr::rename("CAF_MCPCOUNTER" = "Cancer associated fibroblast_MCPCOUNTER")

### Chapter 6. Log2 Transform CAF EPIC and CAF MCPCOUNTER variables
# First make into numerics:
CleanedMergedData_NonMet_Restricted$CAF_EPIC <- as.numeric(CleanedMergedData_NonMet_Restricted$CAF_EPIC)
CleanedMergedData_NonMet_Restricted$CAF_MCPCOUNTER <- as.numeric(CleanedMergedData_NonMet_Restricted$CAF_MCPCOUNTER)
# Now log transform
CleanedMergedData_NonMet_Restricted$CAF_EPIC <- log(CleanedMergedData_NonMet_Restricted$CAF_EPIC*100+1, 2) # multiply from 100 to move from decimals to whole numbers
CleanedMergedData_NonMet_Restricted$CAF_MCPCOUNTER <- log(CleanedMergedData_NonMet_Restricted$CAF_MCPCOUNTER+1, 2)

### Chapter 7. Make CAF EPIC and CAF MCPCOUNTER plots by Diagnosis
## CAF EPIC
# Create a variable Plot_EPIC that is a ggplot of the CAF_EPIC data 
Plot_EPIC <- ggplot(CleanedMergedData_NonMet_Restricted, aes(Diagnosis_Simplified_BRS, CAF_EPIC)) +
  geom_boxplot(outlier.size = -1, 
               aes(fill = Category_BRS),
               alpha = 0.4, 
               show.legend = FALSE) + 
  geom_jitter(aes(),
              position = position_jitter(width = 0.1, height = 0),
              size = 1.5, 
              alpha = 0.7,
              show.legend = FALSE) +
  scale_fill_manual(values = c("blue", "red", "purple")) + # Blue = Follicular; Red = Papillary; Purple = Transformed
  labs (x = "Diagnosis", y = "Log2(CAF EPIC)") + 
  theme_classic() +  
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5), 
    axis.title.x = element_text(face = "bold", size = 14.5), 
    axis.title.y = element_text(face = "bold", size = 13),
    axis.text.x = element_text(face = "bold", size = 10.5), 
    axis.text.y = element_text(face = "bold", size = 16)) +
  scale_x_discrete(name ="Diagnosis", limits = c("FA/HA", "FTC/\nHC", "EFVPTC/\nNIFTP", "PTC/\nIFVPTC", "PDTC", "  ATC \n RAS", " ATC \n BRAF")) +
  scale_y_continuous(breaks = c(0, 2, 4, 6),
                     limits = c(0,6.8)) 
                     
# Save the Plot_EPIC as a png                       
ggsave("outputs/Transformation_Series_BRS_CAF_EPIC.png", 
       width = 5, height = 3, 
       Plot_EPIC, dpi = 600)

## CAF EPIC Stats ##
# Non-parametric statistics for CAF_EPIC by Diagnosis w/ bonferroni correction on the pairwise.wilcox.test
kruskal.test(CAF_EPIC ~ Diagnosis_Simplified_BRS, data = CleanedMergedData_NonMet_Restricted) 
pairwise.wilcox.test(CleanedMergedData_NonMet_Restricted$CAF_EPIC, CleanedMergedData_NonMet_Restricted$Diagnosis_Simplified_BRS, 
                     p.adjust.method = "bonferroni")
                     
                     
## CAF MCPCOUNTER
# Create a variable Plot_MCPCOUNTER that is a ggplot of the CAF_MCPCOUNTER data                      
Plot_MCPCOUNTER <- ggplot(CleanedMergedData_NonMet_Restricted, aes(Diagnosis_Simplified_BRS, CAF_MCPCOUNTER)) +
  geom_boxplot(outlier.size = -1, 
               aes(fill = Category_BRS),
               alpha = 0.4, 
               show.legend = FALSE) + 
  geom_jitter(aes(),
              position = position_jitter(width = 0.1, height = 0),
              size = 1.5, 
              alpha = 0.7,
              show.legend = FALSE) +
  scale_fill_manual(values = c("blue", "red", "purple")) + # Blue = Follicular; Red = Papillary; Purple = Transformed
  labs (x = "Diagnosis", y = "Log2\n(CAF MCPCOUNTER)") + 
  theme_classic() + 
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5), 
    axis.title.x = element_text(face = "bold", size = 14.5), 
    axis.title.y = element_text(face = "bold", size = 13),
    axis.text.x = element_text(face = "bold", size = 10.5), 
    axis.text.y = element_text(face = "bold", size = 16)) +
  scale_x_discrete(name ="Diagnosis", limits = c("FA/HA", "FTC/\nHC", "EFVPTC/\nNIFTP", "PTC/\nIFVPTC", "PDTC", "  ATC \n RAS", " ATC \n BRAF")) +
  scale_y_continuous(breaks = c(4, 6, 8, 10, 12),
                     limits = c(4,12.5)) 
                  
# Save the Plot_MCPCOUNTER as a png                     
ggsave("outputs/Transformation_Series_BRS_CAF_MCPCOUNTER.png", 
       width = 5, height = 3, 
       Plot_MCPCOUNTER, dpi = 600)

## CAF MCPCOUNTER Stats ##
# Non-parametric statistics for CAF_MCPCOUNTER by Diagnosis w/ bonferroni correction on the pairwise.wilcox.test
kruskal.test(CAF_MCPCOUNTER ~ Diagnosis_Simplified_BRS, data = CleanedMergedData_NonMet_Restricted) # shouldn't be necessary for only two groups
pairwise.wilcox.test(CleanedMergedData_NonMet_Restricted$CAF_MCPCOUNTER, CleanedMergedData_NonMet_Restricted$Diagnosis_Simplified_BRS, # this returned 0.068
                     p.adjust.method = "bonferroni")



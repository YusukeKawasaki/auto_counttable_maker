library(tximport)
library(readr)
library(RCurl)

# 2018/12/05 Y.Yasumizu
# usage : Rscript quantmerge_gene.R
# automatically detect salmon output (*/salmon_output_${name}/quant.sf)

# metadataがないときはダウンロードする。
meta.m <- 'gencode.vM19.metadata.MGI.gz'
meta.base.m <- 'ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M19'
meta.h <- 'gencode.v29.metadata.HGNC.gz'
meta.base.h <- 'ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29'

# quant.sfの検索
files <- list.files('.', recursive=T, pattern='quant.sf')

# sample nameの回収
names <- c()
for (f in files){
    n <- (unlist(strsplit(files, 'salmon_output_')[1])[2])
    n <- (unlist(strsplit(n, '/quant.sf')[1])[1])
#     print(n)
    names <- c(names, n)
}
print(names)

names(files) <- names

# 生物種の判定
sample_tx <- read.table(files[1], nrows = 2)[2,'V1']

if (length(grep("^ENSMUST.*", sample_tx)) == 1) {
    print('MOUSE')
    meta <- meta.m
    meta.base <- meta.base.m
} else if (length(grep("^ENST.*", sample_tx)) == 1)  {
    print('HUMAN')
    meta <- meta.h
    meta.base <- meta.base.h
} else {
    print('unknown transcript id. use mouse or human transcripts annotation by GENCODE.')
}


# metadataの取得。
f.meta <- list.files('.', recursive=T, pattern=meta)
if (length(f.meta) == 0){
    print('Downloading metadata ... ')
    print(paste0(meta.base,'/',meta))
    download.file(paste0(meta.base,'/',meta), destfile = meta)
    tx2knownGene <- read_delim(meta, '\t', col_names = c('TXNAME', 'GENEID'))
} else {
    tx2knownGene <- read_delim(f.meta, '\t', col_names = c('TXNAME', 'GENEID'))
}

# txi.salmon <- tximport(files, type = "salmon", tx2gene = tx2knownGene)
txi.salmon <- tximport(files, type = "salmon", tx2gene = tx2knownGene, countsFromAbundance="scaledTPM")
# head(txi.salmon$counts)

write.table(txi.salmon$counts, file="scaledTPM.tsv",sep="\t",col.names=NA,row.names=T,quote=F)

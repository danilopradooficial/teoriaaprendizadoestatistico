# Atividade 01 - Dicionario de variaveis (Aula 02)
# Tipagem do ANTAQ: codigo nao e numero; str e summary depois do tipo certo.
# Na raiz: Rscript estrutura/codigos/01-dicionario-variaveis.R

user_lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table", lib = user_lib, repos = "https://cloud.r-project.org")
}
library(data.table)

root <- if (file.exists(file.path("estrutura", "dataset"))) {
  "."
} else if (file.exists(file.path("..", "..", "estrutura", "dataset"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

num <- function(x) {
  if (is.numeric(x)) return(x)
  as.numeric(gsub(",", ".", as.character(x), fixed = TRUE))
}

base <- file.path("estrutura", "dataset")
ano  <- "2024"

atrac  <- ler(file.path(base, ano, paste0(ano, "Atracacao.txt")))
tempos <- ler(file.path(base, ano, paste0(ano, "TemposAtracacao.txt")))

# ---- quantitativas continuas (horas) ----
cols_t <- c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
            "TEsperaDesatracacao", "TAtracado", "TEstadia")
for (cl in cols_t) {
  if (cl %in% names(tempos)) tempos[[cl]] <- num(tempos[[cl]])
}

# ---- identificadores: character, nunca media ----
for (cl in c("IDAtracacao", "CDTUP", "IDBerco", "Nº da Capitania", "Nº do IMO")) {
  if (cl %in% names(atrac)) atrac[[cl]] <- as.character(atrac[[cl]])
}
if ("IDAtracacao" %in% names(tempos)) {
  tempos[, IDAtracacao := as.character(IDAtracacao)]
}

# ---- qualitativas nominais -> factor ----
for (cl in c("Complexo Portuário", "Tipo de Operação",
             "Tipo de Navegação da Atracação", "SGUF", "Região Geográfica",
             "Porto Atracação", "Tipo da Autoridade Portuária")) {
  if (cl %in% names(atrac)) atrac[[cl]] <- factor(atrac[[cl]])
}

# ---- ordinal: mes na ordem do calendario ----
ord_mes <- c("jan", "fev", "mar", "abr", "mai", "jun",
             "jul", "ago", "set", "out", "nov", "dez")
mes_raw <- tolower(substr(trimws(as.character(atrac$Mes)), 1, 3))
atrac[, Mes := factor(mes_raw, levels = ord_mes, ordered = TRUE)]

# ---- nacionalidade do armador: 0/1/2 nao e quantidade ----
if ("Nacionalidade do Armador" %in% names(atrac)) {
  atrac[, `Nacionalidade do Armador` := factor(
    as.integer(`Nacionalidade do Armador`),
    levels = c(0, 1, 2),
    labels = c("nao_informado", "brasileira", "estrangeira")
  )]
}

# ---- flag 0/1: qualitativa indicadora, integer para filtro ----
if ("FlagMCOperacaoAtracacao" %in% names(atrac)) {
  atrac[, FlagMCOperacaoAtracacao := as.integer(FlagMCOperacaoAtracacao)]
}

# ---- coordenadas: texto "lon,lat" -> dois numeric ----
if ("Coordenadas" %in% names(atrac)) {
  atrac[, c("lon", "lat") := tstrsplit(Coordenadas, ",", type.convert = TRUE)]
}

# ---- unidade amostral: uma escala (join 1:1 com tempos) ----
esc <- merge(atrac, tempos, by = "IDAtracacao")

# classes das colunas-chave (o que o laboratorio pede)
chaves <- c("IDAtracacao", "CDTUP", "Mes", "Tipo de Operação",
            "Nacionalidade do Armador", "FlagMCOperacaoAtracacao",
            "Nº do IMO", "lon", "lat")
classes <- sapply(chaves, function(cl) {
  if (!cl %in% names(esc)) return(NA_character_)
  paste(class(esc[[cl]]), collapse = "/")
})

sink(file.path("estrutura", "codigos", "01-numeros.txt"))
cat("ano=", ano, " n_atrac=", nrow(atrac), " n_escala=", nrow(esc), "\n", sep = "")
cat("\n=== class (depois da tipagem) ===\n")
print(classes)
cat("\n=== summary(Mes) ===\n")
print(summary(esc$Mes))
cat("\n=== summary(Tipo de Operacao) ===\n")
print(summary(esc$`Tipo de Operação`))
cat("\n=== summary(TOperacao) ===\n")
print(summary(esc$TOperacao))
cat("\n=== CDTUP nao e numero (primeiros niveis) ===\n")
print(head(levels(factor(esc$CDTUP)), 8))
cat("class_CDTUP=", class(esc$CDTUP)[1], "\n", sep = "")
cat("class_IMO=", class(esc$`Nº do IMO`)[1], "\n", sep = "")
sink()

cat("OK -> estrutura/codigos/01-numeros.txt\n")
print(classes)

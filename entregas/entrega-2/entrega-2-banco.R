# Entrega 2 - Banco limpo para o artigo final
# Na raiz: Rscript entregas/entrega-2/entrega-2-banco.R
# Gera em entregas/entrega-2/:
#   entrega-2-escalas.csv  (lido pelo artigo-final.Rnw)
#   entrega-2-numeros.txt

user.lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user.lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user.lib, .libPaths()))
for (pkg in c("data.table", "randomForest")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, lib = user.lib, repos = "https://cloud.r-project.org")
  }
}
library(data.table)
library(randomForest)

root <- if (file.exists(file.path("estrutura", "dataset"))) {
  "."
} else if (file.exists(file.path("..", "..", "estrutura", "dataset"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)
saida <- file.path("entregas", "entrega-2")
dir.create(saida, recursive = TRUE, showWarnings = FALSE)

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}
num <- function(x) if (is.numeric(x)) x else as.numeric(gsub(",", ".", as.character(x), fixed = TRUE))
ascii <- function(x) {
  x <- iconv(as.character(x), from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", ".", x))
  gsub("^\\.|\\.$", "", x)
}

atrac  <- ler(file.path("estrutura", "dataset", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("estrutura", "dataset", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("estrutura", "dataset", "2024", "2024Carga.txt"))
tempos[, TOperacao := num(TOperacao)]
carga[, `:=`(VLPesoCargaBruta = num(VLPesoCargaBruta), TEU = num(TEU))]

dt <- merge(atrac, tempos, by = "IDAtracacao")
santos <- dt[`Complexo Portuário` == "Santos" &
               `Tipo de Operação` == "Movimentação da Carga" &
               is.finite(TOperacao)]
mc <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1]
agg <- mc[, .(peso.t = sum(VLPesoCargaBruta, na.rm = TRUE),
              teu    = sum(TEU, na.rm = TRUE),
              n.part = .N), by = IDAtracacao]
nat <- mc[, .(peso = sum(VLPesoCargaBruta, na.rm = TRUE)),
          by = .(IDAtracacao, `Natureza da Carga`)]
nat <- nat[order(-peso), .SD[1], by = IDAtracacao]
setnames(nat, "Natureza da Carga", "natureza")

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- merge(esc, nat[, .(IDAtracacao, natureza)], by = "IDAtracacao", all.x = TRUE)
esc <- esc[peso.t > 0]
q99 <- quantile(esc$TOperacao, 0.99)
esc <- esc[TOperacao <= q99]

meses.pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
esc[, mes := tolower(substr(trimws(as.character(Mes)), 1, 3))]
esc[, navegacao := ascii(`Tipo de Navegação da Atracação`)]
esc[, natureza := ascii(natureza)]
esc[, terminal.raw := ascii(Terminal)]
top.term <- esc[, .N, by = terminal.raw][order(-N)][1:10, terminal.raw]
esc[, terminal := ifelse(is.na(terminal.raw) | !(terminal.raw %in% top.term),
                         "outros", terminal.raw)]

# banco limpo: so resposta + preditores legitimos (sem id, sem vazamento)
banco <- data.frame(
  log.t3    = log1p(esc$TOperacao),
  log.peso  = log1p(esc$peso.t),
  log.teu   = log1p(esc$teu),
  log.part  = log1p(esc$n.part),
  natureza  = as.character(esc$natureza),
  navegacao = as.character(esc$navegacao),
  terminal  = as.character(esc$terminal),
  mes       = as.character(esc$mes),
  stringsAsFactors = FALSE
)
banco <- na.omit(banco)
banco <- banco[banco$mes %in% meses.pt, ]
n <- nrow(banco)

write.csv(banco, file.path(saida, "entrega-2-escalas.csv"), row.names = FALSE)

# placar de apoio (mesmas dobras do funil) para citar no texto
set.seed(1)
dobra <- sample(rep(1:5, length = n))
mse <- function(a, b) mean((a - b)^2)
cv.base <- mean(sapply(1:5, function(j) {
  tr <- banco[dobra != j, ]; va <- banco[dobra == j, ]
  mse(va$log.t3, rep(mean(tr$log.t3), nrow(va)))
}))
cv.mqo <- mean(sapply(1:5, function(j) {
  tr <- banco[dobra != j, ]; va <- banco[dobra == j, ]
  mse(va$log.t3, predict(lm(log.t3 ~ log.peso + log.teu + log.part, data = tr), va))
}))
set.seed(1)
rf <- randomForest(log.t3 ~ ., data = banco, mtry = 3, ntree = 500, importance = TRUE)
oob <- tail(rf$mse, 1)
imp <- sort(importance(rf, type = 1)[, 1], decreasing = TRUE)

# RMSE horas via OOB: prever com arvores OOB e voltar com expm1
# (aproximacao: usar previsao do modelo no banco e CV base/mqo em horas)
rmse.h <- function(ajusta) {
  preds <- numeric(n)
  for (j in 1:5) {
    tr <- banco[dobra != j, ]; va <- banco[dobra == j, ]
    preds[dobra == j] <- ajusta(tr, va)
  }
  sqrt(mean((expm1(banco$log.t3) - expm1(preds))^2))
}
rmse.base <- rmse.h(function(tr, va) rep(mean(tr$log.t3), nrow(va)))
rmse.mqo  <- rmse.h(function(tr, va) predict(lm(log.t3 ~ log.peso + log.teu + log.part, data = tr), va))

sink(file.path(saida, "entrega-2-numeros.txt"))
cat("n=", n, " p=", ncol(banco) - 1, "\n", sep = "")
cat("q99.T3=", round(as.numeric(q99), 2), "\n", sep = "")
cat("cv.base=", round(cv.base, 4), "\n", sep = "")
cat("cv.mqo=", round(cv.mqo, 4), "\n", sep = "")
cat("oob.rf=", round(oob, 4), "\n", sep = "")
cat("rmse.base.h=", round(rmse.base, 2), "\n", sep = "")
cat("rmse.mqo.h=", round(rmse.mqo, 2), "\n", sep = "")
cat("pct.var=", round(100 * rf$rsq[length(rf$rsq)], 1), "\n", sep = "")
cat("importancia:\n"); print(round(imp, 2))
sink()

cat("OK -> ", normalizePath(saida), " n=", n, " oob=", round(oob, 4), "\n", sep = "")

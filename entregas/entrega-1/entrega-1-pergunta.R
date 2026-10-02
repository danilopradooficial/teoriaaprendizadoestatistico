# Entrega 1 - A pergunta do trabalho
# Na raiz: Rscript entregas/entrega-1/entrega-1-pergunta.R
# Le os microdados de estrutura/dataset e grava em entregas/entrega-1/:
#   entrega-1-escalas.csv     (uma linha por escala, lido pelo .Rnw)
#   entrega-1-resultados.csv  (CV(5) das duas perguntas, lido pelo .Rnw)
#   entrega-1-numeros.txt     (todos os numeros citados no texto)

user.lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user.lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user.lib, .libPaths()))
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table", lib = user.lib, repos = "https://cloud.r-project.org")
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
saida <- file.path("entregas", "entrega-1")

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}
num <- function(x) if (is.numeric(x)) x else as.numeric(gsub(",", ".", as.character(x), fixed = TRUE))

atrac  <- ler(file.path("estrutura", "dataset", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("estrutura", "dataset", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("estrutura", "dataset", "2024", "2024Carga.txt"))

t.cols <- c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
            "TEsperaDesatracacao", "TAtracado", "TEstadia")
for (cl in t.cols) tempos[[cl]] <- num(tempos[[cl]])
for (cl in c("VLPesoCargaBruta", "TEU")) carga[[cl]] <- num(carga[[cl]])

# ---- 1) recorte: Santos, movimentacao de carga, 2024 ----
dt <- merge(atrac, tempos, by = "IDAtracacao")
santos <- dt[`Complexo Portuário` == "Santos" &
               `Tipo de Operação` == "Movimentação da Carga" &
               is.finite(TOperacao)]
n.bruto <- nrow(santos)

mc <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1]
agg <- mc[, .(peso.t = sum(VLPesoCargaBruta, na.rm = TRUE),
              teu    = sum(TEU, na.rm = TRUE),
              n.part = .N),
          by = IDAtracacao]
nat <- mc[, .(peso = sum(VLPesoCargaBruta, na.rm = TRUE)),
          by = .(IDAtracacao, `Natureza da Carga`)]
nat <- nat[order(-peso), .SD[1], by = IDAtracacao]
setnames(nat, "Natureza da Carga", "natureza")

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- merge(esc, nat[, .(IDAtracacao, natureza)], by = "IDAtracacao", all.x = TRUE)
esc <- esc[peso.t > 0]
q99 <- quantile(esc$TOperacao, 0.99)
n.antes.p99 <- nrow(esc)
esc <- esc[TOperacao <= q99]

# duracao da operacao calculada pelas datas: e o proprio T3 escrito de outro jeito
data.hora <- function(x) as.POSIXct(x, format = "%d/%m/%Y %H:%M:%S", tz = "UTC")
esc[, dur.datas := as.numeric(difftime(data.hora(`Data Término Operação`),
                                       data.hora(`Data Início Operação`),
                                       units = "hours"))]

# categorias em ASCII (o .Rnw nao pode ter acento em string de R)
ascii <- function(x) {
  x <- iconv(as.character(x), from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", ".", x))
  gsub("^\\.|\\.$", "", x)
}
meses.pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
esc[, mes := tolower(substr(trimws(as.character(Mes)), 1, 3))]
esc[, navegacao := ascii(`Tipo de Navegação da Atracação`)]
esc[, natureza := ascii(natureza)]
esc[, terminal.raw := ascii(Terminal)]
top.term <- esc[, .N, by = terminal.raw][order(-N)][1:10, terminal.raw]
esc[, terminal := ifelse(is.na(terminal.raw) | !(terminal.raw %in% top.term),
                         "outros", terminal.raw)]

escalas <- esc[, .(
  T3 = TOperacao,                       # resposta (horas)
  peso.t, teu, n.part,                  # preditores conhecidos na chegada
  natureza, navegacao, terminal, mes,
  T1 = TEsperaAtracacao,                # tempos que NAO se conhecem na chegada
  T2 = TEsperaInicioOp,
  T4 = TEsperaDesatracacao,
  TAtracado, TEstadia, dur.datas        # contem T3 dentro de si: vazamento
)]

fwrite(escalas, file.path(saida, "entrega-1-escalas.csv"))

# ---- 2) diagnostico: os quatro descartes ----
n <- nrow(escalas)
vaz.cols <- c("T1", "T2", "T4", "TAtracado", "TEstadia", "dur.datas")
numcols <- c("T3", "peso.t", "teu", "n.part", vaz.cols)
cc.todas <- abs(cor(escalas[, ..numcols], use = "pairwise.complete.obs")[, "T3"])
cc.todas <- sort(cc.todas[names(cc.todas) != "T3"], decreasing = TRUE)

limpo <- escalas[, .(T3, peso.t, teu, n.part, natureza, navegacao, terminal, mes)]
limpo[, `:=`(log.peso = log1p(peso.t), log.teu = log1p(teu), log.part = log1p(n.part))]
cc.limpo <- abs(cor(limpo[, .(T3, log.peso, log.teu, log.part)])[, "T3"])
cc.limpo <- sort(cc.limpo[names(cc.limpo) != "T3"], decreasing = TRUE)

faltantes <- colSums(is.na(escalas))
limpo <- na.omit(limpo)
for (cl in c("natureza", "navegacao", "terminal")) set(limpo, j = cl, value = factor(limpo[[cl]]))
limpo[, mes := factor(mes, levels = meses.pt)]

f.x <- ~ log.peso + log.teu + log.part + natureza + navegacao + terminal + mes
p.colunas <- 7
p.dummies <- ncol(model.matrix(f.x, data = limpo)) - 1

corte <- 24
limpo[, longa := as.integer(T3 > corte)]
balanco <- table(limpo$longa)

# ---- 3) CV(5): linha de base contra lm/glm, nas metricas das fichas ----
set.seed(1)
k <- 5
dobra <- sample(rep(1:k, length = nrow(limpo)))

auc <- function(y, s) {
  r <- rank(s)
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
rmse <- function(a, b) sqrt(mean((a - b)^2))
f.lm.h   <- update(f.x, T3 ~ .)
f.lm.log <- update(f.x, log1p(T3) ~ .)
f.glm    <- update(f.x, longa ~ .)

res <- rbindlist(lapply(1:k, function(j) {
  tr <- limpo[dobra != j]; te <- limpo[dobra == j]
  # pergunta 1: regressao, RMSE em horas
  base.h <- rep(mean(tr$T3), nrow(te))
  m.h    <- lm(f.lm.h, data = tr)
  m.log  <- lm(f.lm.log, data = tr)
  smear  <- mean(exp(residuals(m.log)))        # correcao de Duan para voltar do log
  p.log  <- (exp(predict(m.log, te)) * smear) - 1
  # pergunta 2: classificacao, AUC e acuracia
  maj    <- as.integer(mean(tr$longa) >= 0.5)
  m.g    <- glm(f.glm, data = tr, family = binomial)
  s.g    <- predict(m.g, te, type = "response")
  p.h    <- predict(m.h, te)
  data.table(
    dobra = j,
    rmse.base = rmse(te$T3, base.h),
    rmse.lm.h = rmse(te$T3, p.h),
    rmse.lm.log = rmse(te$T3, p.log),
    mae.base = mean(abs(te$T3 - base.h)),
    mae.lm.h = mean(abs(te$T3 - p.h)),
    mae.lm.log = mean(abs(te$T3 - p.log)),
    acc.base = mean(te$longa == maj),
    acc.glm = mean(te$longa == as.integer(s.g >= 0.5)),
    auc.base = 0.5,
    auc.glm = auc(te$longa, s.g),
    # a pergunta 1 tambem responde a 2: basta cortar a previsao em 24 h
    acc.lm.corte = mean(te$longa == as.integer(p.h > corte)),
    auc.lm.corte = auc(te$longa, p.h)
  )
}))
media <- res[, lapply(.SD, mean), .SDcols = -"dobra"]
dp    <- res[, lapply(.SD, sd),   .SDcols = -"dobra"]

ganho.p1 <- 1 - min(media$rmse.lm.h, media$rmse.lm.log) / media$rmse.base
ganho.p2.acc <- media$acc.glm - media$acc.base

resultados <- rbind(
  data.table(medida = names(media), media = as.numeric(media), dp = as.numeric(dp)),
  data.table(medida = c("n.bruto", "q99", "corte", "k"),
             media  = c(n.bruto, q99, corte, k), dp = NA)
)
fwrite(resultados, file.path(saida, "entrega-1-resultados.csv"))

sink(file.path(saida, "entrega-1-numeros.txt"))
cat("escalas Santos mov. carga com T3=", n.bruto, "\n", sep = "")
cat("com carga (peso>0)=", n.antes.p99, " P99 T3=", round(q99, 2), " h\n", sep = "")
cat("n final=", n, " n sem faltantes=", nrow(limpo), "\n", sep = "")
cat("p colunas=", p.colunas, " p dummies=", p.dummies, "\n", sep = "")
cat("sd(T3)=", sd(limpo$T3), " media=", mean(limpo$T3), " mediana=", median(limpo$T3), "\n", sep = "")
cat("\n=== correlacao |r| com T3, todas as colunas numericas ===\n")
print(round(cc.todas, 4))
cat("\n=== correlacao |r| com T3, so preditores legitimos ===\n")
print(round(cc.limpo, 4))
cat("\n=== faltantes ===\n")
print(faltantes[faltantes > 0])
cat("\n=== balanco T3 >", corte, "h ===\n")
print(balanco); print(round(prop.table(balanco), 4))
cat("\n=== CV(5) media (dp) ===\n")
print(resultados)
cat("\nganho RMSE P1 sobre a base=", round(100 * ganho.p1, 1), "%\n", sep = "")
cat("ganho acuracia P2 sobre a base=", round(100 * ganho.p2.acc, 1), " p.p.\n", sep = "")
sink()

print(resultados)
cat("OK\n")

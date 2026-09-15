# Atividade 05 - Avaliacao e selecao de modelos (Aula 06)
# Na raiz: Rscript estrutura/codigos/05-avaliacao-selecao-modelos.R

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

out.dir <- file.path("consolidados", "graficos", "05")
dir.create(out.dir, recursive = TRUE, showWarnings = FALSE)

salvar <- function(nome, expr, w = 1000, h = 1000, mar = c(4.5, 4.5, 3.2, 1.2)) {
  png(file.path(out.dir, nome), width = w, height = h, res = 120)
  op <- par(pty = "s", mar = mar)
  on.exit({ par(op); dev.off() }, add = TRUE)
  force(expr)
  invisible()
}

azul <- "#2C5F8A"
laranja <- "#C45C26"
verde <- "#2E7D4F"
roxo <- "#6B3FA0"

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

atrac  <- ler(file.path("estrutura", "dataset", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("estrutura", "dataset", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("estrutura", "dataset", "2024", "2024Carga.txt"))

for (cl in c("TOperacao")) {
  if (!is.numeric(tempos[[cl]])) {
    tempos[[cl]] <- as.numeric(gsub(",", ".", as.character(tempos[[cl]]), fixed = TRUE))
  }
}
for (cl in c("VLPesoCargaBruta", "TEU")) {
  if (!is.numeric(carga[[cl]])) {
    carga[[cl]] <- as.numeric(gsub(",", ".", as.character(carga[[cl]]), fixed = TRUE))
  }
}

dt <- merge(atrac, tempos, by = "IDAtracacao")
santos <- dt[`Complexo Portuário` == "Santos" &
               `Tipo de Operação` == "Movimentação da Carga" &
               is.finite(TOperacao)]

agg <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1,
             .(peso.t = sum(VLPesoCargaBruta, na.rm = TRUE),
               teu    = sum(TEU, na.rm = TRUE)),
             by = IDAtracacao]

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso.t > 0 & is.finite(TOperacao)]
esc[, y        := log1p(TOperacao)]
esc[, log.peso := log1p(peso.t)]
esc[, log.teu  := log1p(teu)]
esc[, T3       := TOperacao]

q99 <- quantile(esc$T3, 0.99)
esc.m <- esc[T3 <= q99]

# ---- 1) dividir 70/30 ANTES de qualquer ajuste (laboratorio da aula) ----
set.seed(1)
n <- nrow(esc.m)
itr <- sample(n, round(0.7 * n))
tr <- as.data.frame(esc.m[itr])
te <- as.data.frame(esc.m[-itr])

mse <- function(m, d) mean((d$y - predict(m, d))^2)
rmse <- function(m, d) sqrt(mse(m, d))
mae.h <- function(m, d) {
  pred <- expm1(predict(m, d))
  mean(abs(d$T3 - pred))
}

# ---- grafico no molde do slide: tres polinomios nos nossos dados ----
# X = log1p(peso), Y = log1p(T3); graus 1, 3 e 12
graus.slide <- c(1, 3, 12)
cores.slide <- c(verde, laranja, roxo)

salvar("01-tres-polinomios.png", {
  set.seed(1)
  idx <- sample.int(nrow(tr), min(3000L, nrow(tr)))
  plot(tr$log.peso[idx], tr$y[idx],
       pch = 19, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.35),
       xlab = "log1p(peso da escala, t)",
       ylab = "log1p(T3, h)",
       main = "Tres candidatos: graus 1, 3 e 12")
  g.grid <- seq(min(tr$log.peso), max(tr$log.peso), length.out = 200)
  for (k in seq_along(graus.slide)) {
    g <- graus.slide[k]
    m <- lm(y ~ poly(log.peso, g), data = tr)
    lines(g.grid, predict(m, data.frame(log.peso = g.grid)),
          col = cores.slide[k], lwd = 2)
  }
  legend("topleft",
         legend = c("grau 1", "grau 3", "grau 12"),
         col = cores.slide, lwd = 2, bty = "n", cex = 0.9)
})

# MSE treino/teste dos tres graus (mesmo protocolo do slide)
mse.grau.tr <- mse.grau.te <- numeric(3)
names(mse.grau.tr) <- names(mse.grau.te) <- paste0("grau", graus.slide)
for (k in seq_along(graus.slide)) {
  g <- graus.slide[k]
  m <- lm(y ~ poly(log.peso, g), data = tr)
  mse.grau.tr[k] <- mse(m, tr)
  mse.grau.te[k] <- mse(m, te)
}

# ---- 2) laboratorio: DOIS candidatos das aulas passadas ----
m1 <- lm(y ~ log.peso, data = tr)
m2 <- lm(y ~ log.peso + log.teu, data = tr)

mse.tr <- c(m1 = mse(m1, tr), m2 = mse(m2, tr))
mse.te <- c(m1 = mse(m1, te), m2 = mse(m2, te))
rmse.tr <- sqrt(mse.tr)
rmse.te <- sqrt(mse.te)
mae.te <- c(m1 = mae.h(m1, te), m2 = mae.h(m2, te))
vencedor <- names(which.min(rmse.te))

salvar("02-rmse-treino-teste.png", {
  mat <- rbind(rmse.tr, rmse.te)
  colnames(mat) <- c("so tonelagem", "tonelagem + TEU")
  bp <- barplot(mat, beside = TRUE, col = c(verde, laranja),
                ylim = c(0, max(mat) * 1.25),
                main = "RMSE: treino x teste",
                ylab = "RMSE (escala log1p(T3))")
  legend("topright", legend = c("treino", "teste"),
         fill = c(verde, laranja), bty = "n")
  text(bp, mat, sprintf("%.3f", mat), pos = 3, cex = 0.8)
})

# regressao: mesma reta (m1) no treino e no teste (molde da aula)
salvar("03-reta-treino-teste.png", {
  set.seed(1)
  layout(matrix(c(1, 2), 1, 2), widths = c(1, 1))
  par(pty = "s", mar = c(4.5, 4.5, 3.2, 1.2))
  i.tr <- sample.int(nrow(tr), min(2500L, nrow(tr)))
  i.te <- sample.int(nrow(te), min(1500L, nrow(te)))
  lim.x <- range(c(tr$log.peso, te$log.peso))
  lim.y <- range(c(tr$y, te$y))
  plot(tr$log.peso[i.tr], tr$y[i.tr],
       pch = 19, cex = 0.35, col = rgb(46/255, 125/255, 79/255, 0.35),
       xlim = lim.x, ylim = lim.y,
       main = "Treino (70%)",
       xlab = "log1p(peso)", ylab = "log1p(T3)")
  abline(m1, col = laranja, lwd = 2)
  plot(te$log.peso[i.te], te$y[i.te],
       pch = 19, cex = 0.35, col = rgb(196/255, 92/255, 38/255, 0.35),
       xlim = lim.x, ylim = lim.y,
       main = "Teste (30%) - mesma reta",
       xlab = "log1p(peso)", ylab = "log1p(T3)")
  abline(m1, col = azul, lwd = 2)
}, w = 1600, h = 800, mar = c(4.5, 4.5, 3.2, 1))

salvar("04-previsto-vs-real-teste.png", {
  set.seed(1)
  pred2 <- expm1(predict(m2, te))
  idx <- sample.int(nrow(te), min(2500L, nrow(te)))
  plot(pred2[idx], te$T3[idx],
       pch = 16, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.3),
       main = "Teste: T3 previsto x real (modelo 2)",
       xlab = "T3 previsto (h)", ylab = "T3 real (h)")
  abline(0, 1, col = laranja, lwd = 2)
})

# curva em U: graus 1 a 12 (como na aula)
graus <- 1:12
etr <- ete <- numeric(12)
for (g in graus) {
  m <- lm(y ~ poly(log.peso, g), data = tr)
  etr[g] <- mse(m, tr)
  ete[g] <- mse(m, te)
}
g.best <- which.min(ete)

salvar("05-curva-u-grau.png", {
  matplot(graus, cbind(etr, ete), type = "l", lwd = 3, lty = 1,
          col = c(verde, laranja),
          xlab = "grau (flexibilidade)", ylab = "MSE",
          main = "Curva em U: poly(log.peso)")
  legend("topright", legend = c("treino", "teste"),
         col = c(verde, laranja), lwd = 3, bty = "n")
  points(g.best, min(ete), pch = 19, cex = 1.4, col = roxo)
})

sink(file.path("estrutura", "codigos", "05-numeros.txt"))
cat("n=", n, "\n", sep = "")
cat("n.treino=", nrow(tr), " n.teste=", nrow(te), "\n", sep = "")
cat("seed=1 prop.treino=0.7\n", sep = "")
cat("Y=log1p(T3) X1=log1p(peso) X2=log1p(teu)\n", sep = "")
cat("\n=== tres graus (slide): MSE treino ===\n")
print(mse.grau.tr)
cat("\n=== tres graus (slide): MSE teste ===\n")
print(mse.grau.te)
cat("\n=== laboratorio m1 vs m2: RMSE treino ===\n")
print(rmse.tr)
cat("\n=== laboratorio m1 vs m2: RMSE teste ===\n")
print(rmse.te)
cat("\n=== MAE teste (horas) ===\n")
print(mae.te)
cat("\nvencedor=", vencedor, "\n", sep = "")
cat("\n=== coef m2 (treino) ===\n")
print(coef(m2))
cat("\n=== curva U: MSE teste por grau 1..12 ===\n")
print(setNames(ete, paste0("grau", graus)))
cat("grau.melhor.u=", g.best, "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
print(list.files(out.dir))

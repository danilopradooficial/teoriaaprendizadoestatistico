# Atividade 09 - Splines e modelos aditivos (Aula 10)
# Na raiz: Rscript estrutura/codigos/09-splines-modelos-aditivos.R

user.lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user.lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user.lib, .libPaths()))
for (pkg in c("data.table", "mgcv")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, lib = user.lib, repos = "https://cloud.r-project.org")
  }
}
library(data.table)
library(splines)
library(mgcv)

root <- if (file.exists(file.path("estrutura", "dataset"))) {
  "."
} else if (file.exists(file.path("..", "..", "estrutura", "dataset"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)

out.dir <- file.path("consolidados", "graficos", "09")
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
cinza <- "grey70"
pontos <- rgb(0.17, 0.37, 0.54, 0.12)

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}
num <- function(x) if (is.numeric(x)) x else as.numeric(gsub(",", ".", as.character(x), fixed = TRUE))

atrac  <- ler(file.path("estrutura", "dataset", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("estrutura", "dataset", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("estrutura", "dataset", "2024", "2024Carga.txt"))
tempos[, TOperacao := num(TOperacao)]
carga[, `:=`(VLPesoCargaBruta = num(VLPesoCargaBruta), TEU = num(TEU))]

dt <- merge(atrac, tempos, by = "IDAtracacao")
santos <- dt[`Complexo Portuário` == "Santos" &
               `Tipo de Operação` == "Movimentação da Carga" &
               is.finite(TOperacao)]
agg <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1,
             .(peso.t = sum(VLPesoCargaBruta, na.rm = TRUE),
               teu    = sum(TEU, na.rm = TRUE),
               n.part = .N),
             by = IDAtracacao]
esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso.t > 0]
esc <- esc[TOperacao <= quantile(TOperacao, 0.99)]

d <- data.frame(
  y  = log1p(esc$TOperacao),
  x1 = log1p(esc$peso.t),
  x2 = log1p(esc$teu),
  x3 = log1p(esc$n.part)
)
d <- na.omit(d)
n <- nrow(d)

set.seed(1)
dobra <- sample(rep(1:5, length = n))
mse <- function(a, b) mean((a - b)^2)

cv.de <- function(ajusta) {
  mean(sapply(1:5, function(j) {
    tr <- d[dobra != j, ]
    va <- d[dobra == j, ]
    mse(va$y, ajusta(tr, va))
  }))
}

# ---- placar do laboratorio (slide 31) ----
cv.base <- cv.de(function(tr, va) rep(mean(tr$y), nrow(va)))
cv.mqo  <- cv.de(function(tr, va) predict(lm(y ~ x1 + x2 + x3, data = tr), va))

dfs <- 2:8
cv.ns <- sapply(dfs, function(k) {
  cv.de(function(tr, va) {
    predict(lm(y ~ ns(x1, df = k) + x2 + x3, data = tr), va)
  })
})
names(cv.ns) <- dfs
df.best <- dfs[which.min(cv.ns)]
cv.ns.best <- min(cv.ns)

cv.gam <- cv.de(function(tr, va) {
  g <- gam(y ~ s(x1) + s(x2) + s(x3), data = tr)
  as.numeric(predict(g, va))
})

# spline de suavizacao univariada (aprofunda a 08)
cv.ss <- cv.de(function(tr, va) {
  sp <- smooth.spline(tr$x1, tr$y)
  predict(sp, va$x1)$y
})

# reta univariada (ancora da 08 / 03a)
cv.reta1 <- cv.de(function(tr, va) predict(lm(y ~ x1, data = tr), va))

# ns so em x1 (U da spline de regressao)
cv.ns1 <- sapply(dfs, function(k) {
  cv.de(function(tr, va) predict(lm(y ~ ns(x1, df = k), data = tr), va))
})
names(cv.ns1) <- dfs
df1.best <- dfs[which.min(cv.ns1)]

# GAM no banco inteiro: edf e curvas
g.full <- gam(y ~ s(x1) + s(x2) + s(x3), data = d)
edf <- round(summary(g.full)$s.table[, "edf"], 2)
names(edf) <- c("s(x1).peso", "s(x2).teu", "s(x3).part")

# smooth.spline no banco inteiro
sp.full <- smooth.spline(d$x1, d$y)
df.ss <- round(sp.full$df, 2)

# RMSE em horas (escala original) para o lab
rmse.h <- function(ajusta) {
  preds <- numeric(n)
  for (j in 1:5) {
    tr <- d[dobra != j, ]
    va <- d[dobra == j, ]
    preds[dobra == j] <- ajusta(tr, va)
  }
  sqrt(mean((expm1(d$y) - expm1(preds))^2))
}
rmse.base <- rmse.h(function(tr, va) rep(mean(tr$y), nrow(va)))
rmse.mqo  <- rmse.h(function(tr, va) predict(lm(y ~ x1 + x2 + x3, data = tr), va))
rmse.ns   <- rmse.h(function(tr, va) {
  predict(lm(y ~ ns(x1, df = df.best) + x2 + x3, data = tr), va)
})
rmse.gam  <- rmse.h(function(tr, va) {
  as.numeric(predict(gam(y ~ s(x1) + s(x2) + s(x3), data = tr), va))
})

# ---- graficos ----
idx <- sample.int(n, min(2000, n))
g.x <- seq(min(d$x1), max(d$x1), length = 300)

salvar("01-polinomio-vs-natural.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  # polinomio grau 9 (df = 10 com intercepto) vs ns df = 10
  m.poly <- lm(y ~ poly(x1, 9), data = d)
  m.nat  <- lm(y ~ ns(x1, df = 10), data = d)
  for (lab in c("polinomio grau 9", "spline natural, df = 10")) {
    plot(d$x1[idx], d$y[idx], pch = 16, cex = 0.45, col = pontos,
         xlab = "log(1 + peso)", ylab = "log(1 + T3)", main = lab)
    if (lab == "polinomio grau 9") {
      lines(g.x, predict(m.poly, data.frame(x1 = g.x)), col = laranja, lwd = 2.5)
    } else {
      lines(g.x, predict(m.nat, data.frame(x1 = g.x)), col = azul, lwd = 2.5)
    }
  }
})

salvar("02-ns-df-baixo-alto.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  for (k in c(2, 8)) {
    m <- lm(y ~ ns(x1, df = k), data = d)
    plot(d$x1[idx], d$y[idx], pch = 16, cex = 0.45, col = pontos,
         xlab = "log(1 + peso)", ylab = "log(1 + T3)",
         main = paste0("ns, df = ", k))
    lines(g.x, predict(m, data.frame(x1 = g.x)), col = azul, lwd = 2.5)
  }
})

salvar("03-cv-ns-df.png", {
  plot(dfs, cv.ns1, type = "b", pch = 16, col = azul, lwd = 2,
       xlab = "df da spline natural (so x1)", ylab = "CV(5): MSE de validacao",
       main = "Spline de regressao: CV por df")
  points(df1.best, min(cv.ns1), pch = 16, cex = 2, col = laranja)
  abline(h = cv.reta1, lty = 2, col = "grey40")
  mtext("<- mais rigido      mais flexivel ->", side = 3, line = 0.2, cex = 0.8)
  legend("topright", c("ns(x1)", "reta y ~ x1"),
         col = c(azul, "grey40"), lwd = 2, lty = c(1, 2), bty = "n", cex = 0.85)
})

salvar("04-smooth-spline.png", {
  plot(d$x1[idx], d$y[idx], pch = 16, cex = 0.45, col = pontos,
       xlab = "log(1 + peso)", ylab = "log(1 + T3)",
       main = paste0("smooth.spline (GCV), df efetivos = ", df.ss))
  lines(g.x, predict(sp.full, g.x)$y, col = verde, lwd = 2.5)
  abline(lm(y ~ x1, data = d), col = "grey30", lwd = 2, lty = 2)
  legend("topleft", c("spline de suavizacao", "reta MQO"),
         col = c(verde, "grey30"), lwd = 2.5, lty = c(1, 2), bty = "n", cex = 0.85)
})

salvar("05-gam-curvas-parciais.png", w = 1800, h = 700, mar = c(4.2, 4.2, 2.5, 1), {
  par(mfrow = c(1, 3), pty = "s")
  plot(g.full, scheme = 1, select = 1, col = azul, lwd = 2,
       xlab = "log(1 + peso)", ylab = "f1 parcial",
       main = paste0("peso, edf = ", edf[1]))
  plot(g.full, scheme = 1, select = 2, col = laranja, lwd = 2,
       xlab = "log(1 + TEU)", ylab = "f2 parcial",
       main = paste0("TEU, edf = ", edf[2]))
  plot(g.full, scheme = 1, select = 3, col = verde, lwd = 2,
       xlab = "log(1 + partidas)", ylab = "f3 parcial",
       main = paste0("partidas, edf = ", edf[3]))
})

placar.nomes <- c("base", "reta 1x", "MQO 3x",
                  paste0("ns df=", df.best), "smooth.spline", "GAM")
placar.cv <- c(cv.base, cv.reta1, cv.mqo, cv.ns.best, cv.ss, cv.gam)

salvar("06-placar-cv.png", {
  o <- order(placar.cv, decreasing = TRUE)
  barplot(placar.cv[o], names.arg = placar.nomes[o], horiz = TRUE, las = 1,
          col = c(cinza, azul, roxo, laranja, verde, "#8B4513")[o],
          xlab = "CV(5): MSE de validacao (escala log)",
          main = "Placar: base, MQO, spline e GAM",
          xlim = c(0, max(placar.cv) * 1.08))
  abline(v = cv.mqo, lty = 2, col = "grey40")
})

# comparacao bs vs ns nas pontas (grafico extra)
salvar("07-bs-vs-ns-pontas.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  m.bs <- lm(y ~ bs(x1, df = 6), data = d)
  m.ns <- lm(y ~ ns(x1, df = 6), data = d)
  for (lado.b in c("esq", "dir")) {
    faixa <- if (lado.b == "esq") quantile(d$x1, c(0, 0.08)) else quantile(d$x1, c(0.92, 1))
    sel <- d$x1 >= faixa[1] & d$x1 <= faixa[2]
    gg <- seq(faixa[1], faixa[2], length = 200)
    plot(d$x1[sel], d$y[sel], pch = 16, cex = 0.6, col = pontos,
         main = if (lado.b == "esq") "ponta esquerda (leves)" else "ponta direita (pesados)",
         xlab = "log(1 + peso)", ylab = "log(1 + T3)")
    lines(gg, predict(m.bs, data.frame(x1 = gg)), col = laranja, lwd = 2.5)
    lines(gg, predict(m.ns, data.frame(x1 = gg)), col = azul, lwd = 2.5)
    legend(if (lado.b == "esq") "topleft" else "bottomright",
           c("bs (cubica)", "ns (natural)"),
           col = c(laranja, azul), lwd = 2.5, bty = "n", cex = 0.85)
  }
})

# ---- exercicios de calculo (numeros da aula) ----
# Ex1: K=4 nos
# Ex2: f(x) = 100 + 2x + 3(x-50)+ - 4(x-80)+
ex2.x <- c(40, 50, 60, 100)
ex2.f <- 100 + 2 * ex2.x + 3 * pmax(ex2.x - 50, 0) - 4 * pmax(ex2.x - 80, 0)

# Ex3: pedagio
# g1=3+2x => g''=0 => int=0
# g2=x^2 => g''=2 => int_0^1 4 dt = 4
# g3=x^3 => g''=6x => int_0^1 36 x^2 = 12
# candidatos: RSS 52,30,12 e pedagio 0,4,30; criterio = RSS + lambda * pedagio
ex3.rss <- c(52, 30, 12)
ex3.ped <- c(0, 4, 30)
ex3.lams <- c(0.1, 1, 10)
ex3.crit <- outer(ex3.rss, ex3.lams, function(r, l) r + l * ex3.ped)
# reshape: each row is candidate, cols are lambda
ex3.mat <- sapply(ex3.lams, function(l) ex3.rss + l * ex3.ped)
colnames(ex3.mat) <- paste0("lam=", ex3.lams)
rownames(ex3.mat) <- c("A", "B", "C")

# Ex4: predicao GAM
ex4.y <- 340 - 20 + 60 + 26
ex4.y2 <- 340 - 20 - 11 + 26

sink(file.path("estrutura", "codigos", "09-numeros.txt"))
cat("n=", n, "\n", sep = "")
cat("\n=== CV(5) placar ===\n")
cat("cv.base=", round(cv.base, 4), "\n", sep = "")
cat("cv.reta1=", round(cv.reta1, 4), "\n", sep = "")
cat("cv.mqo=", round(cv.mqo, 4), "\n", sep = "")
cat("cv.ns por df (ns(x1)+x2+x3):\n"); print(round(cv.ns, 4))
cat("df.best=", df.best, " cv.ns.best=", round(cv.ns.best, 4), "\n", sep = "")
cat("cv.ss=", round(cv.ss, 4), " df.ss=", df.ss, "\n", sep = "")
cat("cv.gam=", round(cv.gam, 4), "\n", sep = "")
cat("\n=== CV(5) ns so x1 ===\n"); print(round(cv.ns1, 4))
cat("df1.best=", df1.best, "\n", sep = "")
cat("\n=== edf do GAM ===\n"); print(edf)
cat("\n=== RMSE horas (CV) ===\n")
cat("rmse.base=", round(rmse.base, 2), "\n", sep = "")
cat("rmse.mqo=", round(rmse.mqo, 2), "\n", sep = "")
cat("rmse.ns=", round(rmse.ns, 2), "\n", sep = "")
cat("rmse.gam=", round(rmse.gam, 2), "\n", sep = "")
cat("\n=== exercicios ===\n")
cat("ex2 f(40,50,60,100)=", ex2.f, "\n")
cat("ex3 pedagios g1,g2,g3 = 0, 4, 12\n")
cat("ex3 criterio:\n"); print(ex3.mat)
cat("ex4 yhat=", ex4.y, " yhat.2km=", ex4.y2, " delta=", ex4.y2 - ex4.y, "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
print(list.files(out.dir))
print(round(setNames(placar.cv, placar.nomes), 4))
print(edf)

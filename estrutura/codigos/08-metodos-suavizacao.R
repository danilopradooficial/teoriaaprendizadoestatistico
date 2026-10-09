# Atividade 08 - Metodos de suavizacao (Aula 09)
# Na raiz: Rscript estrutura/codigos/08-metodos-suavizacao.R

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

out.dir <- file.path("consolidados", "graficos", "08")
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

x <- log1p(esc$peso.t)          # o preditor numerico mais importante do funil
y <- log1p(esc$TOperacao)       # a resposta das atividades 05 a 07
n <- length(y)

# ---- as funcoes da aula ----
knn.reg <- function(x0, x, y, k) mean(y[order(abs(x - x0))[1:k]])
nw <- function(x0, x, y, h) { w <- dnorm((x - x0) / h); sum(w * y) / sum(w) }

set.seed(1)
dobra <- sample(rep(1:5, length = n))
mse <- function(a, b) mean((a - b)^2)

# ---- 1) KNN: CV(5) por k ----
# os vizinhos de cada ponto de validacao sao ordenados uma vez por dobra;
# a predicao com k vizinhos e a media dos k primeiros
ks <- c(1, 3, 5, 10, 20, 40, 80, 150, 300, 600, 1500)
cv.knn <- sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  xt <- x[tr]; yt <- y[tr]
  ys <- t(sapply(x[va], function(x0) yt[order(abs(xt - x0))[1:max(ks)]]))
  cum <- t(apply(ys, 1, cumsum))
  sapply(ks, function(k) mse(cum[, k] / k, y[va]))
})
cvk <- rowMeans(cv.knn)
ep.k <- apply(cv.knn, 1, sd) / sqrt(5)
k.best <- ks[which.min(cvk)]

# ---- 2) kernel (Nadaraya-Watson): CV(5) por h ----
hs <- round(sd(x) * c(0.01, 0.02, 0.05, 0.1, 0.2, 0.4, 0.8, 1.6), 3)
cv.nw <- sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  d <- outer(x[va], x[tr], "-")
  sapply(hs, function(h) {
    w <- dnorm(d / h)
    p <- as.numeric(w %*% y[tr]) / rowSums(w)
    p[!is.finite(p)] <- mean(y[tr])     # janela fixa sem vizinhos: NaN
    mse(p, y[va])
  })
})
cvh <- rowMeans(cv.nw)
h.best <- hs[which.min(cvh)]

# ---- 3) reta e loess pelas mesmas dobras ----
cv.reta <- mean(sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  m <- lm(y ~ x, data = data.frame(x = x[tr], y = y[tr]))
  mse(predict(m, data.frame(x = x[va])), y[va])
}))
spans <- c(0.05, 0.1, 0.2, 0.3, 0.5, 0.75)
cv.loess <- sapply(spans, function(s) mean(sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  m <- loess(y ~ x, data = data.frame(x = x[tr], y = y[tr]), span = s, degree = 1,
             control = loess.control(surface = "direct"))
  mse(predict(m, data.frame(x = x[va])), y[va])
})))
span.best <- spans[which.min(cv.loess)]

# ---- 4) efeito de borda: predicoes de CV e vies medio nas pontas ----
pred.cv <- function(metodo) {
  p <- numeric(n)
  for (j in 1:5) {
    tr <- dobra != j; va <- dobra == j
    p[va] <- metodo(x[va], x[tr], y[tr])
  }
  p
}
p.nw <- pred.cv(function(x0, xt, yt) sapply(x0, nw, x = xt, y = yt, h = h.best))
p.knn <- pred.cv(function(x0, xt, yt) sapply(x0, knn.reg, x = xt, y = yt, k = k.best))
p.loess <- pred.cv(function(x0, xt, yt) {
  m <- loess(y ~ x, data = data.frame(x = xt, y = yt), span = span.best, degree = 1,
             control = loess.control(surface = "direct"))
  predict(m, data.frame(x = x0))
})
p.spl <- pred.cv(function(x0, xt, yt) predict(smooth.spline(xt, yt), x0)$y)
p.reta <- pred.cv(function(x0, xt, yt) {
  b <- coef(lm(yt ~ xt)); b[1] + b[2] * x0
})
q <- quantile(x, c(0.02, 0.98))
esq <- x <= q[1]; dir <- x >= q[2]
borda <- sapply(list(knn = p.knn, kernel = p.nw, loess = p.loess,
                     spline = p.spl, reta = p.reta), function(p)
  c(vies.esq = mean(y[esq] - p[esq]), vies.dir = mean(y[dir] - p[dir]),
    cv = mse(p, y)))

# ---- 5) maldicao da dimensionalidade ----
ps <- c(1, 2, 3, 5, 10, 20, 50)
lado <- 0.1^(1 / ps)
n.10viz <- 10 / 0.1^ps

# KNN com 1 a 3 preditores reais (padronizados) e depois colunas de ruido
reais <- scale(cbind(log.peso = x, log.teu = log1p(esc$teu), log.part = log1p(esc$n.part)))
set.seed(9)
ruido <- matrix(rnorm(n * 17), n, 17)
Xall <- cbind(reais, ruido)
ps.knn <- c(1, 2, 3, 5, 10, 20)
cv.knn.p <- sapply(ps.knn, function(p) mean(sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  A <- Xall[va, 1:p, drop = FALSE]; B <- Xall[tr, 1:p, drop = FALSE]
  d2 <- outer(rowSums(A^2), rowSums(B^2), "+") - 2 * A %*% t(B)
  yt <- y[tr]
  p.va <- apply(d2, 1, function(r) mean(yt[order(r)[1:k.best]]))
  mse(p.va, y[va])
})))

# ---- 6) exercicios novos: contas com numeros do porto ----
ex.x <- c(10, 14, 20, 26, 35, 50)      # mil t
ex.y <- c(18, 22, 30, 28, 44, 60)      # horas
ex.knn <- sapply(c(1, 3, 5, 6), function(k) knn.reg(24, ex.x, ex.y, k))
ex.w5 <- exp(-0.5 * ((ex.x - 24) / 5)^2)
ex.w2 <- exp(-0.5 * ((ex.x - 24) / 2)^2)
ex.nw5 <- sum(ex.w5 * ex.y) / sum(ex.w5)
ex.nw2 <- sum(ex.w2 * ex.y) / sum(ex.w2)

# ---- graficos ----
g <- seq(min(x), max(x), length = 300)
curva.knn <- function(k) sapply(g, knn.reg, x = x, y = y, k = k)
curva.nw <- function(h) sapply(g, nw, x = x, y = y, h = h)
nuvem <- function(titulo) plot(x, y, pch = 16, cex = 0.45, col = pontos, main = titulo,
                               xlab = "log(1 + peso)", ylab = "log(1 + T3)")

salvar("01-knn-k-pequeno-grande.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  for (k in c(3, 600)) {
    nuvem(paste("KNN, k =", k))
    lines(g, curva.knn(k), col = roxo, lwd = 2.5)
  }
})

salvar("02-cv-knn.png", {
  plot(ks, cvk, type = "b", log = "x", pch = 16, col = roxo, lwd = 2,
       xlab = "k (escala log)", ylab = "CV(5): MSE de validacao",
       main = "KNN: o U espelhado")
  points(k.best, min(cvk), pch = 16, cex = 2, col = laranja)
  abline(h = cv.reta, lty = 2, col = "grey40")
  mtext("<- mais flexivel      mais rigido ->", side = 3, line = 0.2, cex = 0.8)
  legend("topright", c("KNN", "reta (Aula 04)"), col = c(roxo, "grey40"),
         lty = c(1, 2), lwd = 2, bty = "n", cex = 0.85)
})

salvar("03-kernel-h-pequeno-grande.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  for (h in c(hs[1], hs[length(hs)])) {
    nuvem(paste("kernel, h =", h))
    lines(g, curva.nw(h), col = verde, lwd = 2.5)
  }
})

salvar("04-cv-kernel.png", {
  plot(hs, cvh, type = "b", log = "x", pch = 16, col = verde, lwd = 2,
       xlab = "h (escala log)", ylab = "CV(5): MSE de validacao",
       main = "Kernel: o mesmo U")
  points(h.best, min(cvh), pch = 16, cex = 2, col = laranja)
  abline(h = cv.reta, lty = 2, col = "grey40")
  mtext("<- mais flexivel      mais rigido ->", side = 3, line = 0.2, cex = 0.8)
})

salvar("05-knn-x-kernel-x-reta.png", {
  nuvem("Melhor KNN x melhor kernel x reta")
  lines(g, curva.knn(k.best), col = roxo, lwd = 2.5, type = "s")
  lines(g, curva.nw(h.best), col = verde, lwd = 2.5)
  abline(lm(y ~ x), col = "grey30", lwd = 2, lty = 2)
  legend("topleft", c(paste("KNN, k =", k.best), paste("kernel, h =", h.best), "reta"),
         col = c(roxo, verde, "grey30"), lwd = 2.5, lty = c(1, 1, 2), bty = "n", cex = 0.85)
})

salvar("06-efeito-borda.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  m.lo <- loess(y ~ x, span = span.best, degree = 1, control = loess.control(surface = "direct"))
  m.sp <- smooth.spline(x, y)
  for (lado.b in c("esq", "dir")) {
    faixa <- if (lado.b == "esq") quantile(x, c(0, 0.08)) else quantile(x, c(0.92, 1))
    sel <- x >= faixa[1] & x <= faixa[2]
    gg <- seq(faixa[1], faixa[2], length = 200)
    plot(x[sel], y[sel], pch = 16, cex = 0.6, col = pontos,
         main = if (lado.b == "esq") "ponta esquerda (navios leves)" else "ponta direita (navios pesados)",
         xlab = "log(1 + peso)", ylab = "log(1 + T3)")
    lines(gg, sapply(gg, nw, x = x, y = y, h = h.best), col = verde, lwd = 2.5)
    lines(gg, predict(m.lo, data.frame(x = gg)), col = laranja, lwd = 2.5)
    lines(gg, predict(m.sp, gg)$y, col = azul, lwd = 2.5, lty = 2)
    legend(if (lado.b == "esq") "topleft" else "bottomright",
           c("kernel (media local)", "loess (reta local)", "spline"),
           col = c(verde, laranja, azul), lwd = 2.5, lty = c(1, 1, 2), bty = "n", cex = 0.8)
  }
})

salvar("07-maldicao-dimensionalidade.png", w = 1800, h = 900, {
  par(mfrow = c(1, 2))
  plot(ps, lado, type = "b", pch = 16, col = roxo, lwd = 2, log = "x", ylim = c(0, 1),
       xlab = "p (preditores, escala log)", ylab = "lado do cubo com 10% dos dados",
       main = "lado = 0,1^(1/p)")
  abline(h = 1, lty = 3, col = "grey50")
  text(ps, lado, sprintf("%.2f", lado), pos = 1, cex = 0.8)
  plot(ps.knn, cv.knn.p, type = "b", pch = 16, col = laranja, lwd = 2,
       xlab = "p (3 reais + ruido)", ylab = "CV(5): MSE de validacao",
       main = paste0("KNN (k = ", k.best, ") com mais colunas"))
})

sink(file.path("estrutura", "codigos", "08-numeros.txt"))
cat("n=", n, " sd(x)=", round(sd(x), 3), " var(y)=", round(var(y), 4), "\n", sep = "")
cat("\n=== CV(5) reta ===\n"); cat("cv.reta=", round(cv.reta, 4), "\n", sep = "")
cat("\n=== CV(5) KNN por k ===\n"); print(round(setNames(cvk, ks), 4))
cat("ep por k:\n"); print(round(setNames(ep.k, ks), 4))
cat("k.best=", k.best, "\n", sep = "")
cat("\n=== CV(5) kernel por h ===\n"); print(round(setNames(cvh, hs), 4))
cat("h.best=", h.best, "\n", sep = "")
cat("\n=== CV(5) loess por span ===\n"); print(round(setNames(cv.loess, spans), 4))
cat("span.best=", span.best, "\n", sep = "")
cat("\n=== borda: vies medio (y - previsto) nos 2% de cada ponta ===\n"); print(round(borda, 4))
cat("n.esq=", sum(esq), " n.dir=", sum(dir), "\n", sep = "")
cat("\n=== maldicao: lado e n para 10 vizinhos ===\n")
print(data.frame(p = ps, lado = round(lado, 3), n.10viz = signif(n.10viz, 3)))
cat("\n=== KNN por p (3 reais + ruido) ===\n"); print(round(setNames(cv.knn.p, ps.knn), 4))
cat("mse chutar media=", round(mean((y - mean(y))^2), 4), "\n", sep = "")
cat("\n=== exercicios novos ===\n")
cat("knn k=1,3,5,6:", round(ex.knn, 3), "\n")
cat("pesos h=5:", signif(ex.w5, 4), "\n"); cat("norm h=5:", round(ex.w5 / sum(ex.w5), 4), "\n")
cat("nw h=5:", round(ex.nw5, 3), "\n")
cat("pesos h=2:", signif(ex.w2, 4), "\n"); cat("norm h=2:", round(ex.w2 / sum(ex.w2), 4), "\n")
cat("nw h=2:", round(ex.nw2, 3), "\n")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
print(list.files(out.dir))

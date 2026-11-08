# Atividade 11 - Agrupamento e componentes principais (Aula 12)
# Na raiz: Rscript estrutura/codigos/11-agrupamento-pca.R

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

out.dir <- file.path("consolidados-aulas", "graficos", "11")
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

# silhueta do slide da Aula 12
silhueta <- function(cluster, D) {
  D <- as.matrix(D)
  n <- length(cluster)
  s <- numeric(n)
  for (i in 1:n) {
    mesmo <- which(cluster == cluster[i])
    if (length(mesmo) == 1) { s[i] <- 0; next }
    a <- mean(D[i, mesmo[mesmo != i]])
    outros <- setdiff(unique(cluster), cluster[i])
    b <- min(sapply(outros, function(k) mean(D[i, cluster == k])))
    s[i] <- (b - a) / max(a, b)
  }
  s
}

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
               n.part = .N), by = IDAtracacao]
esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso.t > 0]
esc <- esc[TOperacao <= quantile(TOperacao, 0.99)]

d.full <- data.frame(
  y        = log1p(esc$TOperacao),
  log.peso = log1p(esc$peso.t),
  log.teu  = log1p(esc$teu),
  log.part = log1p(esc$n.part)
)
d.full <- na.omit(d.full)
n.full <- nrow(d.full)

# amostra para silhueta (matriz n x n)
set.seed(1)
idx <- if (n.full > 2000) sample(n.full, 2000) else seq_len(n.full)
d <- d.full[idx, ]
n <- nrow(d)
X <- d[, c("log.peso", "log.teu", "log.part")]
y <- d$y

# ---- PCA ----
pca <- prcomp(X, scale. = TRUE)
var.exp <- (pca$sdev^2) / sum(pca$sdev^2)
cum.var <- cumsum(var.exp)
rot <- round(pca$rotation[, 1:2], 3)

# ---- K-means + silhueta ----
Z <- scale(X)
D <- dist(Z)
ks <- 2:8
set.seed(1)
S <- sapply(ks, function(k) {
  set.seed(1)
  mean(silhueta(kmeans(Z, centers = k, nstart = 25)$cluster, D))
})
names(S) <- ks
K <- ks[which.max(S)]
set.seed(1)
km <- kmeans(Z, centers = K, nstart = 25)

centros <- aggregate(X, list(grupo = km$cluster), mean)
centros$n <- as.integer(table(km$cluster)[as.character(centros$grupo)])
centros$y.medio <- tapply(y, km$cluster, mean)[as.character(centros$grupo)]

# W por K (cotovelo)
set.seed(1)
W <- sapply(ks, function(k) {
  set.seed(1)
  kmeans(Z, centers = k, nstart = 25)$tot.withinss
})

# hierarquico (amostra menor para desenho)
set.seed(2)
idx.h <- sample(n, min(80, n))
hc <- hclust(dist(Z[idx.h, ]), method = "complete")

# ---- exercicios calculo ----
# Ex4 aula: r=0.6 -> PC1 guarda (1+r)/2 = 0.8; PC1=(z1+z2)/sqrt(2); escore (2,1)
ex4.frac <- (1 + 0.6) / 2
ex4.score <- (2 + 1) / sqrt(2)

# ---- graficos ----
salvar("01-pca-variancia.png", {
  bp <- barplot(var.exp, names.arg = paste0("PC", 1:3), col = azul,
                ylim = c(0, 1), ylab = "fracao da variancia",
                main = "PCA: variancia por componente")
  lines(bp, cum.var, type = "b", pch = 16, col = laranja, lwd = 2)
  legend("topright", c("por PC", "acumulada"), col = c(azul, laranja),
         lwd = 2, pch = c(15, 16), bty = "n")
})

salvar("02-silhueta-por-k.png", {
  plot(ks, S, type = "b", pch = 16, col = roxo, lwd = 2,
       xlab = "K", ylab = "silhueta media",
       main = "Escolha de K pela silhueta", ylim = range(c(0, S)))
  points(K, max(S), pch = 16, cex = 2, col = laranja)
  abline(h = 0, lty = 3, col = "grey50")
})

salvar("03-pc1-pc2-grupos.png", {
  cols <- c(azul, laranja, verde, roxo, "#8B4513", "#008B8B", "#DC143C", "#2F4F4F")
  plot(pca$x[, 1], pca$x[, 2], pch = 16, cex = 0.55,
       col = cols[km$cluster],
       xlab = paste0("PC1 (", round(100 * var.exp[1], 1), "%)"),
       ylab = paste0("PC2 (", round(100 * var.exp[2], 1), "%)"),
       main = paste0("Grupos no plano PC1 x PC2 (K = ", K, ")"))
  legend("topright", paste("grupo", 1:K), col = cols[1:K], pch = 16, bty = "n", cex = 0.85)
})

salvar("04-boxplot-y-por-grupo.png", {
  boxplot(y ~ km$cluster, col = rgb(0.17, 0.37, 0.54, 0.4),
          xlab = "grupo", ylab = "log(1 + T3)",
          main = "Resposta T3 por grupo (K-medias)")
})

salvar("05-dendrograma.png", w = 1200, h = 900, mar = c(2, 4, 3, 1), {
  plot(hc, labels = FALSE, main = "Hierarquico (ligacao completa, n=80)",
       xlab = "", sub = "")
  if (K <= 8) rect.hclust(hc, k = min(K, 8), border = laranja)
})

# nomes interpretativos pelos centros
ord.teu <- order(centros$log.teu)
nomes.g <- character(K)
if (K >= 2) {
  nomes.g[ord.teu[1]] <- "pouco-TEU"
  nomes.g[ord.teu[K]] <- "muito-TEU"
  if (K >= 3) {
    mid <- setdiff(seq_len(K), c(ord.teu[1], ord.teu[K]))
    for (j in mid) nomes.g[j] <- paste0("intermediario-", j)
  }
} else {
  nomes.g[] <- "unico"
}
centros$nome <- nomes.g[centros$grupo]

sink(file.path("estrutura", "codigos", "11-numeros.txt"))
cat("n.full=", n.full, " n.amostra=", n, "\n", sep = "")
cat("\n=== PCA ===\n")
cat("var.exp=", round(var.exp, 4), "\n")
cat("cum.var=", round(cum.var, 4), "\n")
cat("rotation PC1 PC2:\n"); print(rot)
cat("\n=== silhueta ===\n"); print(round(S, 4))
cat("K.best=", K, " S.max=", round(max(S), 4), "\n", sep = "")
cat("W por K:\n"); print(round(W, 1))
cat("\n=== centros ===\n"); print(centros)
cat("\n=== exercicios ===\n")
cat("ex4 frac PC1=", ex4.frac, " score=", round(ex4.score, 4), "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
cat("K=", K, " S=", round(max(S), 4), " PC1%=", round(100 * var.exp[1], 1), "\n", sep = "")
print(centros)

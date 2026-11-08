# Atividade 10 - Arvores de decisao e random forest (Aula 11)
# Na raiz: Rscript estrutura/codigos/10-arvores-random-forest.R

user.lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user.lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user.lib, .libPaths()))
for (pkg in c("data.table", "rpart", "randomForest")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, lib = user.lib, repos = "https://cloud.r-project.org")
  }
}
library(data.table)
library(rpart)
library(randomForest)

root <- if (file.exists(file.path("estrutura", "dataset"))) {
  "."
} else if (file.exists(file.path("..", "..", "estrutura", "dataset"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)

out.dir <- file.path("consolidados-aulas", "graficos", "10")
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
esc <- esc[TOperacao <= quantile(TOperacao, 0.99)]

meses.pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
esc[, mes := tolower(substr(trimws(as.character(Mes)), 1, 3))]
esc[, navegacao := ascii(`Tipo de Navegação da Atracação`)]
esc[, natureza := ascii(natureza)]
esc[, terminal.raw := ascii(Terminal)]
top.term <- esc[, .N, by = terminal.raw][order(-N)][1:10, terminal.raw]
esc[, terminal := ifelse(is.na(terminal.raw) | !(terminal.raw %in% top.term),
                         "outros", terminal.raw)]

d <- data.frame(
  y         = log1p(esc$TOperacao),
  log.peso  = log1p(esc$peso.t),
  log.teu   = log1p(esc$teu),
  log.part  = log1p(esc$n.part),
  natureza  = factor(esc$natureza),
  navegacao = factor(esc$navegacao),
  terminal  = factor(esc$terminal),
  mes       = factor(esc$mes, levels = meses.pt)
)
d <- na.omit(d)
n <- nrow(d)
p <- ncol(d) - 1

set.seed(1)
dobra <- sample(rep(1:5, length = n))
mse <- function(a, b) mean((a - b)^2)

# ancora da 09 (mesmos tres numericos) + base
cv.de.num <- function(ajusta) {
  mean(sapply(1:5, function(j) {
    tr <- d[dobra != j, ]
    va <- d[dobra == j, ]
    mse(va$y, ajusta(tr, va))
  }))
}
cv.base <- cv.de.num(function(tr, va) rep(mean(tr$y), nrow(va)))
cv.mqo  <- cv.de.num(function(tr, va) {
  predict(lm(y ~ log.peso + log.teu + log.part, data = tr), va)
})
# GAM da 09 (ancora fixa do placar, se mgcv disponivel recalcula)
cv.gam <- 0.2669
if (requireNamespace("mgcv", quietly = TRUE)) {
  library(mgcv)
  cv.gam <- cv.de.num(function(tr, va) {
    as.numeric(predict(gam(y ~ s(log.peso) + s(log.teu) + s(log.part), data = tr), va))
  })
}

# ---- arvore: cresce e poda (lab Aula 11) ----
# xval = dobra: rpart usa os indices de dobra (1..5) se length == n
cheia <- rpart(y ~ ., data = d, cp = 0.001, xval = dobra, minsplit = 20)
tab <- cheia$cptable
i.best <- which.min(tab[, "xerror"])
cp.best <- tab[i.best, "CP"]
# xerror e relativo ao RSS da raiz; MSE CV ≈ xerror * var(y) * (n-1)/n
# slide: tab[i,"xerror"] * mean((d$y - mean(d$y))^2)
cv.arv <- as.numeric(tab[i.best, "xerror"] * mean((d$y - mean(d$y))^2))
arv <- prune(cheia, cp = cp.best)
n.folhas <- sum(arv$frame$var == "<leaf>")
primeira <- as.character(arv$frame$var[1])

# ---- random forest: mtry por OOB ----
ms <- unique(pmax(1L, as.integer(round(c(sqrt(p), p / 3, p / 2, p)))))
oob <- sapply(ms, function(m) {
  set.seed(1)
  tail(randomForest(y ~ ., data = d, mtry = m, ntree = 300)$mse, 1)
})
names(oob) <- ms
m.best <- ms[which.min(oob)]
set.seed(1)
rf <- randomForest(y ~ ., data = d, mtry = m.best, ntree = 500, importance = TRUE)
oob.best <- tail(rf$mse, 1)
imp <- importance(rf, type = 1)  # %IncMSE
imp <- sort(imp[, 1], decreasing = TRUE)

# ---- exercicios de calculo (numeros da aula) ----
# Ex1: areas e precos
ex1.x <- c(50, 70, 90, 120, 150, 200)
ex1.y <- c(200, 220, 260, 300, 310, 420)
rss.corte <- function(s) {
  esq <- ex1.y[ex1.x < s]; dir <- ex1.y[ex1.x >= s]
  sum((esq - mean(esq))^2) + sum((dir - mean(dir))^2)
}
ex1.rss <- sapply(c(80, 135, 175), rss.corte)

# Ex2: impureza
p.no <- 30 / 40
ex2.E <- min(p.no, 1 - p.no)
ex2.G <- 2 * p.no * (1 - p.no)
ex2.D <- -p.no * log2(p.no) - (1 - p.no) * log2(1 - p.no)

# Ex3: OOB fraction
ex3.10 <- (1 - 1 / 10)^10
ex3.1000 <- (1 - 1 / 1000)^1000
ex3.fora <- 300 * ex3.1000

# Ex4: C_alpha
ex4.rss <- c(900, 300, 200); ex4.T <- c(1, 4, 12)
ex4.crit <- function(a) ex4.rss + a * ex4.T

# ---- graficos ----
salvar("01-arvore-podada.png", w = 1400, h = 1100, mar = c(1, 1, 3, 1), {
  plot(arv, uniform = TRUE, margin = 0.08, main = paste0(
    "Arvore podada (", n.folhas, " folhas, cp = ", signif(cp.best, 3), ")"))
  text(arv, cex = 0.65, use.n = TRUE)
})

salvar("02-cp-xerror.png", {
  plot(tab[, "nsplit"] + 1, tab[, "xerror"], type = "b", pch = 16, col = azul, lwd = 2,
       xlab = "numero de folhas (aprox.)", ylab = "xerror relativo (CV)",
       main = "Poda: custo-complexidade")
  points(tab[i.best, "nsplit"] + 1, tab[i.best, "xerror"], pch = 16, cex = 2, col = laranja)
  abline(h = tab[i.best, "xerror"] + tab[i.best, "xstd"], lty = 2, col = "grey40")
})

salvar("03-oob-mtry.png", {
  plot(ms, oob, type = "b", pch = 16, col = verde, lwd = 2,
       xlab = "mtry", ylab = "OOB MSE",
       main = "Floresta: escolha de m por OOB")
  points(m.best, min(oob), pch = 16, cex = 2, col = laranja)
})

salvar("04-importancia-rf.png", {
  top <- head(imp, 12)
  par(mar = c(4.5, 10, 3.2, 1.2))
  barplot(rev(top), horiz = TRUE, las = 1, col = azul,
          xlab = "%IncMSE (permutacao OOB)",
          main = "Importancia na floresta")
})

placar.nomes <- c("base", "MQO 3x", "GAM", "arvore", "RF OOB")
placar.cv <- c(cv.base, cv.mqo, cv.gam, cv.arv, oob.best)
salvar("05-placar-cv.png", {
  o <- order(placar.cv, decreasing = TRUE)
  barplot(placar.cv[o], names.arg = placar.nomes[o], horiz = TRUE, las = 1,
          col = c(cinza, azul, verde, laranja, roxo)[o],
          xlab = "MSE (CV ou OOB, escala log)",
          main = "Placar: base, MQO, GAM, arvore, RF",
          xlim = c(0, max(placar.cv) * 1.08))
})

sink(file.path("estrutura", "codigos", "10-numeros.txt"))
cat("n=", n, " p=", p, "\n", sep = "")
cat("\n=== placar ===\n")
cat("cv.base=", round(cv.base, 4), "\n", sep = "")
cat("cv.mqo=", round(cv.mqo, 4), "\n", sep = "")
cat("cv.gam=", round(cv.gam, 4), "\n", sep = "")
cat("cv.arv=", round(cv.arv, 4), " cp.best=", signif(cp.best, 4),
    " folhas=", n.folhas, "\n", sep = "")
cat("oob por mtry:\n"); print(round(oob, 4))
cat("m.best=", m.best, " oob.best=", round(oob.best, 4), "\n", sep = "")
cat("\n=== primeira pergunta ===\n")
cat("raiz=", primeira, "\n", sep = "")
cat("\n=== importancia top ===\n"); print(round(head(imp, 10), 2))
cat("\n=== exercicios ===\n")
cat("ex1 rss 80,135,175:", round(ex1.rss, 1), "\n")
cat("ex2 E,G,D:", round(c(ex2.E, ex2.G, ex2.D), 4), "\n")
cat("ex3 (1-1/n)^n n=10,1000:", round(c(ex3.10, ex3.1000), 4),
    " fora media=", round(ex3.fora, 1), "\n")
cat("ex4 crit alpha=10:", ex4.crit(10), "\n")
cat("ex4 crit alpha=50:", ex4.crit(50), "\n")
cat("ex4 crit alpha=300:", ex4.crit(300), "\n")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
print(round(setNames(placar.cv, placar.nomes), 4))
cat("raiz=", primeira, " folhas=", n.folhas, "\n", sep = "")

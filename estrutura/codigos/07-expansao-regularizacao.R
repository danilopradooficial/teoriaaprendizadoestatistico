# Atividade 07 - Expansao e regularizacao (Aula 08)
# Na raiz: Rscript estrutura/codigos/07-expansao-regularizacao.R

user.lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user.lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user.lib, .libPaths()))
for (pkg in c("data.table", "glmnet")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, lib = user.lib, repos = "https://cloud.r-project.org")
  }
}
library(data.table)
library(glmnet)

root <- if (file.exists(file.path("estrutura", "dataset"))) {
  "."
} else if (file.exists(file.path("..", "..", "estrutura", "dataset"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)

out.dir <- file.path("consolidados", "graficos", "07")
dir.create(out.dir, recursive = TRUE, showWarnings = FALSE)

salvar <- function(nome, expr, w = 1000, h = 1000, mar = c(4.5, 4.5, 3.2, 1.2)) {
  png(file.path(out.dir, nome), width = w, height = h, res = 120)
  op <- par(mar = mar)
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
               teu    = sum(TEU, na.rm = TRUE),
               n.part = .N),
             by = IDAtracacao]

# natureza modal dominante por escala
nat <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1,
             .(peso = sum(VLPesoCargaBruta, na.rm = TRUE)),
             by = .(IDAtracacao, `Natureza da Carga`)]
nat <- nat[order(-peso), .SD[1], by = IDAtracacao]
setnames(nat, "Natureza da Carga", "natureza")

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- merge(esc, nat[, .(IDAtracacao, natureza)], by = "IDAtracacao", all.x = TRUE)
esc <- esc[peso.t > 0 & is.finite(TOperacao)]
esc[, T3 := TOperacao]
q99 <- quantile(esc$T3, 0.99)
esc <- esc[T3 <= q99]

# ---- expansao de atributos (acelerador da Aula 08) ----
esc[, y          := log1p(T3)]
esc[, log.peso   := log1p(peso.t)]
esc[, log.teu    := log1p(teu)]
esc[, log.peso.2 := log.peso^2]                 # potencia
esc[, log.teu.2  := log.teu^2]
esc[, peso.x.teu := log.peso * log.teu]         # interacao
esc[, log.part   := log1p(n.part)]
# gemea quase colinear (como area / area_util da aula)
set.seed(8)
esc[, log.peso.gemea := log.peso + rnorm(.N, 0, 0.02)]

meses.pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
mes.raw <- tolower(substr(trimws(as.character(esc$Mes)), 1, 3))
esc[, mes := factor(mes.raw, levels = meses.pt)]
esc[, navegacao := factor(`Tipo de Navegação da Atracação`)]
# reduz cardinalidade da natureza
top.nat <- esc[, .N, by = natureza][order(-N)][1:6, natureza]
esc[, natureza.g := factor(
  ifelse(is.na(natureza) | !(natureza %in% top.nat), "outras", as.character(natureza))
)]

dados <- as.data.frame(esc[, .(
  y, log.peso, log.teu, log.peso.2, log.teu.2, peso.x.teu,
  log.part, log.peso.gemea, mes, navegacao, natureza.g
)])
dados <- na.omit(dados)

# matriz de desenho (sem intercepto) - glmnet exige matriz
X <- model.matrix(y ~ . , data = dados)[, -1]
yv <- dados$y
n <- nrow(dados)
p <- ncol(X)

cat("n=", n, " p=", p, "\n", sep = "")

# ---- MQO de referencia (expansao completa, sem freio) ----
m.mqo <- lm(y ~ ., data = dados)
rmse.mqo.tr <- sqrt(mean(residuals(m.mqo)^2))

# ---- laboratorio PDF: Lasso e Ridge com CV ----
set.seed(1)
cvl <- cv.glmnet(X, yv, alpha = 1)   # Lasso
cvr <- cv.glmnet(X, yv, alpha = 0)   # Ridge
cve <- cv.glmnet(X, yv, alpha = 0.5) # Elastic Net

# coeficientes no lambda.1se (regra da aula)
cl.1se <- coef(cvl, s = "lambda.1se")
cl.min <- coef(cvl, s = "lambda.min")
nz.1se <- cl.1se[as.vector(cl.1se) != 0, , drop = FALSE]
nz.min <- cl.min[as.vector(cl.min) != 0, , drop = FALSE]

i.min <- which(cvl$lambda == cvl$lambda.min)
i.1se <- which(cvl$lambda == cvl$lambda.1se)

# ---- graficos ----
salvar("01-cv-lasso-curva-u.png", {
  plot(cvl)
  abline(v = log(cvl$lambda.min), col = roxo, lwd = 2)
  abline(v = log(cvl$lambda.1se), col = laranja, lwd = 2, lty = 2)
  legend("topleft",
         legend = c("lambda.min", "lambda.1se"),
         col = c(roxo, laranja), lwd = 2, lty = c(1, 2), bty = "n", cex = 0.85)
}, mar = c(4.5, 4.5, 3.5, 1.2))

salvar("02-caminhos-ridge-lasso.png", {
  layout(matrix(c(1, 2), 1, 2))
  par(mar = c(4.5, 4.5, 3.5, 1.2), pty = "s")
  plot(glmnet(X, yv, alpha = 0), xvar = "lambda")
  title("Ridge (L2)", line = 2.4)
  plot(glmnet(X, yv, alpha = 1), xvar = "lambda")
  title("Lasso (L1)", line = 2.4)
}, w = 1600, h = 800, mar = c(4.5, 4.5, 3.5, 1))

# barras dos sobreviventes (sem intercepto)
salvar("03-coeficientes-lasso-1se.png", {
  par(pty = "s")
  nomes <- rownames(nz.1se)
  vals  <- as.numeric(nz.1se)
  keep <- nomes != "(Intercept)"
  nomes <- nomes[keep]
  vals  <- vals[keep]
  o <- order(abs(vals), decreasing = TRUE)
  nomes <- nomes[o]
  vals  <- vals[o]
  # nomes curtos
  nomes <- gsub("navegacao", "nav.", nomes, fixed = TRUE)
  nomes <- gsub("natureza.g", "nat.", nomes, fixed = TRUE)
  bp <- barplot(vals, names.arg = nomes, las = 2, cex.names = 0.65,
                col = ifelse(vals >= 0, azul, laranja),
                main = "Lasso lambda.1se: sobreviventes",
                ylab = "coeficiente")
  abline(h = 0, col = cinza)
})

salvar("04-cv-mse-metodos.png", {
  par(pty = "s")
  vals <- c(
    MQO = mean((yv - fitted(m.mqo))^2),  # treino (referencia otimista)
    Ridge = min(cvr$cvm),
    Lasso = min(cvl$cvm),
    ElasticNet = min(cve$cvm)
  )
  # MQO aqui e so treino; os outros sao CV - rotulo claro
  bp <- barplot(vals, col = c(cinza, verde, azul, laranja),
                ylim = c(0, max(vals) * 1.25),
                main = "Erro: MQO (treino) x CV min",
                ylab = "MSE")
  text(bp, vals, sprintf("%.3f", vals), pos = 3, cex = 0.8)
  legend("topright",
         legend = c("MQO = so treino", "demais = CV"),
         bty = "n", cex = 0.75)
})

# ---- numeros ----
sink(file.path("estrutura", "codigos", "07-numeros.txt"))
cat("n=", n, " p=", p, "\n", sep = "")
cat("seed=1\n", sep = "")
cat("preditores=", paste(colnames(X), collapse = " | "), "\n", sep = "")
cat("\n=== MQO (treino, expansao completa) ===\n")
cat("R2=", summary(m.mqo)$r.squared, "\n", sep = "")
cat("RMSE.treino=", rmse.mqo.tr, "\n", sep = "")
cat("\n=== Lasso CV ===\n")
cat("lambda.min=", cvl$lambda.min, "\n", sep = "")
cat("lambda.1se=", cvl$lambda.1se, "\n", sep = "")
cat("CV.mse.min=", cvl$cvm[i.min], " CV.rmse.min=", sqrt(cvl$cvm[i.min]), "\n", sep = "")
cat("CV.mse.1se=", cvl$cvm[i.1se], " CV.rmse.1se=", sqrt(cvl$cvm[i.1se]), "\n", sep = "")
cat("nzero.min=", cvl$nzero[i.min], " nzero.1se=", cvl$nzero[i.1se], "\n", sep = "")
cat("CV.sd.min=", cvl$cvsd[i.min], "\n", sep = "")
cat("limiar.1se=", cvl$cvm[i.min] + cvl$cvsd[i.min], "\n", sep = "")
cat("\n=== sobreviventes lambda.1se ===\n")
print(round(nz.1se, 4))
cat("\n=== sobreviventes lambda.min ===\n")
print(round(nz.min, 4))
cat("\n=== Ridge CV ===\n")
cat("lambda.min=", cvr$lambda.min, " CV.mse.min=", min(cvr$cvm), "\n", sep = "")
cat("\n=== Elastic Net alpha=0.5 ===\n")
cat("lambda.min=", cve$lambda.min, " CV.mse.min=", min(cve$cvm), "\n", sep = "")
cat("\n=== placar CV mse minimo ===\n")
cat("lasso=", min(cvl$cvm), " ridge=", min(cvr$cvm),
    " elastic=", min(cve$cvm), "\n", sep = "")
# correlacao das gemeas
cat("\ncor.log.peso.gemea=", cor(dados$log.peso, dados$log.peso.gemea), "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out.dir), "\n", sep = "")
print(list.files(out.dir))

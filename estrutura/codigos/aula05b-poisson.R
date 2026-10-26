# Aula 05b Parte D - Poisson no banco do grupo (Santos)
# Na raiz: Rscript estrutura/codigos/aula05b-poisson.R
# Contagem: escalas Santos 2024 x mes x navegacao (caso 2 do guia)

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

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

atrac <- ler(file.path("estrutura", "dataset", "2024", "2024Atracacao.txt"))
n.ficha <- nrow(atrac)  # so para a tutora ver o arquivo bruto

# recorte do trabalho: Santos, movimentacao de carga
santos <- atrac[`Complexo Portuário` == "Santos" &
                  `Tipo de Operação` == "Movimentação da Carga"]

meses.pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
santos[, mes := tolower(substr(trimws(as.character(Mes)), 1, 3))]
santos[, navegacao := as.character(`Tipo de Navegação da Atracação`)]
santos <- santos[!is.na(mes) & mes %in% meses.pt & !is.na(navegacao) & navegacao != ""]

# M7: contagem com table() + as.data.frame() (guarda os zeros)
cont <- as.data.frame(table(
  factor(santos$mes, levels = meses.pt),
  factor(santos$navegacao)
))
names(cont) <- c("mes", "navegacao", "n")
cont$mes <- factor(cont$mes, levels = meses.pt)
cont$navegacao <- factor(cont$navegacao)

# juntar navegacoes raras (aparecem pouco) para a CV nao quebrar com nivel novo
tab.nav <- sort(tapply(cont$n, cont$navegacao, sum), decreasing = TRUE)
keep <- names(tab.nav)[tab.nav >= 30]
cont$navegacao <- as.character(cont$navegacao)
cont$navegacao[!(cont$navegacao %in% keep)] <- "Outras"
cont$navegacao <- factor(cont$navegacao)

# re-agregar depois do juntar
cont <- aggregate(n ~ mes + navegacao, data = cont, sum)
cont$mes <- factor(cont$mes, levels = meses.pt)

# M8: Poisson
m <- glm(n ~ mes + navegacao, family = poisson, data = cont)
phi <- sum(residuals(m, type = "pearson")^2) / df.residual(m)
mq <- if (phi >= 1.5) {
  glm(n ~ mes + navegacao, family = quasipoisson, data = cont)
} else {
  m
}

# M9: CV(5) mesmas dobras
set.seed(1)
dobra <- sample(rep(1:5, length = nrow(cont)))
rmse.cv <- function(ajusta) {
  sqrt(mean(sapply(1:5, function(j) {
    tr <- cont[dobra != j, , drop = FALSE]
    va <- cont[dobra == j, , drop = FALSE]
    # alinhar fatores ao treino
    tr$mes <- factor(tr$mes, levels = levels(cont$mes))
    tr$navegacao <- factor(tr$navegacao, levels = levels(cont$navegacao))
    va$mes <- factor(as.character(va$mes), levels = levels(tr$mes))
    va$navegacao <- factor(as.character(va$navegacao), levels = levels(tr$navegacao))
    # dropar niveis so da validacao (sem treino)
    ok <- !is.na(va$mes) & !is.na(va$navegacao)
    if (!any(ok)) return(NA_real_)
    mean((va$n[ok] - ajusta(tr, va[ok, , drop = FALSE]))^2)
  }), na.rm = TRUE))
}

rmse.base <- rmse.cv(function(tr, va) rep(mean(tr$n), nrow(va)))
rmse.mqo  <- rmse.cv(function(tr, va) as.numeric(predict(lm(n ~ mes + navegacao, data = tr), va)))
rmse.pois <- rmse.cv(function(tr, va) {
  as.numeric(predict(glm(n ~ mes + navegacao, family = poisson, data = tr),
                     va, type = "response"))
})

sink(file.path("estrutura", "codigos", "aula05b-numeros.txt"))
cat("n.atrac.bruto=", n.ficha, "\n", sep = "")
cat("n.escalas.santos.mc=", nrow(santos), "\n", sep = "")
cat("n.linhas.cont=", nrow(cont), "\n", sep = "")
cat("zeros=", sum(cont$n == 0), "\n", sep = "")
cat("summary n:\n"); print(summary(cont$n))
cat("navegacoes:\n"); print(table(cont$navegacao))
cat("\n=== M8 Poisson ===\n")
cat("phi=", round(phi, 3), "\n", sep = "")
cat("familia=", if (phi >= 1.5) "quasipoisson" else "poisson", "\n", sep = "")
cat("exp(coef) razoes de taxas:\n")
print(round(exp(coef(mq)), 3))
cat("\n=== M9 CV(5) RMSE ===\n")
cat("rmse.base=", round(rmse.base, 3), "\n", sep = "")
cat("rmse.mqo=", round(rmse.mqo, 3), "\n", sep = "")
cat("rmse.pois=", round(rmse.pois, 3), "\n", sep = "")
sink()

cat("OK -> estrutura/codigos/aula05b-numeros.txt\n")
cat("phi=", round(phi, 3),
    " base=", round(rmse.base, 3),
    " mqo=", round(rmse.mqo, 3),
    " pois=", round(rmse.pois, 3), "\n", sep = "")
print(summary(cont$n))

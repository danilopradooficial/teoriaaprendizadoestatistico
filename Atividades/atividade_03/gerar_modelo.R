# Atividade 03 - Regressao linear (Aula 04)
# Alinhada a EDA segmentada (tempos em Santos) - Atividade 02B.
# Na raiz: Rscript Atividades/atividade_03/gerar_modelo.R

user_lib <- file.path(Sys.getenv("USERPROFILE"), "Documents", "R", "win-library", "4.6")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table", lib = user_lib, repos = "https://cloud.r-project.org")
}
library(data.table)

root <- if (file.exists("DatasetMovimentacaoPortuaria")) {
  "."
} else if (file.exists(file.path("..", "..", "DatasetMovimentacaoPortuaria"))) {
  file.path("..", "..")
} else {
  stop("Rode na raiz do repositorio.")
}
setwd(root)

out_dir <- file.path("Atividades", "atividade_03", "graficos")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("Atividades", "atividade_03"), showWarnings = FALSE)

salvar <- function(nome, expr, mar = c(4.5, 4.5, 3.2, 1.2)) {
  png(file.path(out_dir, nome), width = 1000, height = 1000, res = 120)
  op <- par(pty = "s", mar = mar)
  on.exit({ par(op); dev.off() }, add = TRUE)
  force(expr)
  invisible()
}

azul <- "#2C5F8A"
laranja <- "#C45C26"

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

atrac  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Carga.txt"))

for (cl in c("TOperacao", "TEsperaAtracacao")) {
  if (!is.numeric(tempos[[cl]])) {
    tempos[[cl]] <- as.numeric(gsub(",", ".", as.character(tempos[[cl]]), fixed = TRUE))
  }
}
if (!is.numeric(carga$VLPesoCargaBruta)) {
  carga[, VLPesoCargaBruta := as.numeric(gsub(",", ".", as.character(VLPesoCargaBruta), fixed = TRUE))]
}
if (!is.numeric(carga$TEU)) {
  carga[, TEU := as.numeric(gsub(",", ".", as.character(TEU), fixed = TRUE))]
}

dt <- merge(atrac, tempos, by = "IDAtracacao")
santos <- dt[`Complexo Portuário` == "Santos" &
               `Tipo de Operação` == "Movimentação da Carga" &
               is.finite(TOperacao)]

agg <- carga[IDAtracacao %in% santos$IDAtracacao & FlagMCOperacaoCarga == 1,
             .(peso_t = sum(VLPesoCargaBruta, na.rm = TRUE),
               teu    = sum(TEU, na.rm = TRUE),
               n_part = .N),
             by = IDAtracacao]

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso_t > 0 & is.finite(TOperacao)]

# transformacoes (EDA: T3 e peso assimetricos)
esc[, y       := log1p(TOperacao)]
esc[, log_peso := log1p(peso_t)]
esc[, log_teu  := log1p(teu)]
esc[, longo_curso := as.integer(`Tipo de Navegação da Atracação` == "Longo Curso")]

# corta extremos de cadastro no Y (P99) para o ajuste didatico
q99 <- quantile(esc$TOperacao, 0.99)
esc_m <- esc[TOperacao <= q99]

cat("n=", nrow(esc_m), " med_T3=", median(esc_m$TOperacao),
    " med_peso=", median(esc_m$peso_t), "\n", sep = "")

# ---- 1) regressao SIMPLES ----
m_simples <- lm(y ~ log_peso, data = esc_m)
s_simples <- summary(m_simples)
cat("\n=== SIMPLES ===\n")
print(coef(m_simples))
cat("R2=", s_simples$r.squared, " RSE=", s_simples$sigma, "\n", sep = "")

# grafico quadrado: nuvem + reta
salvar("01_reta_simples.png", {
  set.seed(2024)
  idx <- sample.int(nrow(esc_m), min(3000L, nrow(esc_m)))
  plot(esc_m$log_peso[idx], esc_m$y[idx],
       pch = 16, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.3),
       main = "Santos 2024 - simples: log1p(T3) ~ log1p(peso)",
       xlab = "log1p(peso da escala, t)", ylab = "log1p(TOperacao, h)")
  abline(m_simples, col = laranja, lwd = 2)
})

# ---- matriz de correlacao (preditores numericos da multipla) ----
# NAO incluir T1/T2/T4/TA/TE (vazamento / identidade com tempos)
Xnum <- esc_m[, .(log_peso, log_teu, longo_curso, n_part)]
C <- cor(Xnum, use = "complete.obs")
cat("\n=== CORRELACAO ENTRE PREDITORES ===\n")
print(round(C, 3))

salvar("02_matriz_correlacao.png", {
  # heatmap simples em base R
  n <- ncol(C)
  image(1:n, 1:n, t(C[n:1, ]), zlim = c(-1, 1),
        col = colorRampPalette(c(laranja, "white", azul))(40),
        axes = FALSE, main = "Correlacao entre preditores (Santos)")
  axis(1, at = 1:n, labels = colnames(C), cex.axis = 0.85)
  axis(2, at = 1:n, labels = rev(rownames(C)), las = 1, cex.axis = 0.85)
  for (i in 1:n) for (j in 1:n) {
    text(i, n - j + 1, sprintf("%.2f", C[j, i]), cex = 0.9)
  }
})

# ---- 2) regressao MULTIPLA ----
# se |cor| alta entre log_peso e log_teu, ainda assim reportamos e comentamos
m_multi <- lm(y ~ log_peso + log_teu + longo_curso, data = esc_m)
s_multi <- summary(m_multi)
cat("\n=== MULTIPLA ===\n")
print(coef(m_multi))
cat("R2=", s_multi$r.squared, " R2_adj=", s_multi$adj.r.squared,
    " RSE=", s_multi$sigma, "\n", sep = "")
print(s_multi$coefficients)

# ---- 3) residuos vs ajustados (diagnostico, pty=s) ----
salvar("03_residuos_vs_ajustados.png", {
  plot(fitted(m_multi), resid(m_multi),
       pch = 16, cex = 0.4, col = rgb(44/255, 95/255, 138/255, 0.35),
       main = "Diagnostico - residuos vs ajustados (multipla)",
       xlab = "Valores ajustados", ylab = "Residuos")
  abline(h = 0, col = laranja, lwd = 2, lty = 2)
})

# ---- 4) previsao ----
# cenario: escala longo curso, peso mediano tipico de granel/container
novo <- data.frame(
  log_peso = log1p(median(esc_m$peso_t)),
  log_teu = log1p(median(esc_m$teu)),
  longo_curso = 1
)
yhat <- predict(m_multi, newdata = novo)
# intervalo de previsao
pint <- predict(m_multi, newdata = novo, interval = "prediction", level = 0.95)
cat("\n=== PREVISAO ===\n")
cat("cenario: peso=", median(esc_m$peso_t), " teu=", median(esc_m$teu),
    " longo_curso=1\n", sep = "")
cat("yhat log1p(T3)=", yhat, " => T3_hat=", expm1(yhat), " h\n", sep = "")
print(pint)
cat("T3_hat intervalo (h): ", expm1(pint[1, "lwr"]), " a ", expm1(pint[1, "upr"]), "\n", sep = "")

# salva numeros para o md
sink(file.path("Atividades", "atividade_03", "_numeros.txt"))
cat("n=", nrow(esc_m), "\n", sep = "")
cat("q99_T3=", q99, "\n", sep = "")
cat("b0_s=", coef(m_simples)[1], "\n", sep = "")
cat("b1_s=", coef(m_simples)[2], "\n", sep = "")
cat("R2_s=", s_simples$r.squared, "\n", sep = "")
cat("RSE_s=", s_simples$sigma, "\n", sep = "")
cat("R2_m=", s_multi$r.squared, "\n", sep = "")
cat("R2adj_m=", s_multi$adj.r.squared, "\n", sep = "")
cat("RSE_m=", s_multi$sigma, "\n", sep = "")
cat("b_log_peso=", coef(m_multi)["log_peso"], "\n", sep = "")
cat("b_log_teu=", coef(m_multi)["log_teu"], "\n", sep = "")
cat("b_longo=", coef(m_multi)["longo_curso"], "\n", sep = "")
cat("cor_peso_teu=", C["log_peso", "log_teu"], "\n", sep = "")
cat("peso_med=", median(esc_m$peso_t), "\n", sep = "")
cat("teu_med=", median(esc_m$teu), "\n", sep = "")
cat("yhat=", yhat, "\n", sep = "")
cat("T3_hat=", expm1(yhat), "\n", sep = "")
cat("T3_lwr=", expm1(pint[1, "lwr"]), "\n", sep = "")
cat("T3_upr=", expm1(pint[1, "upr"]), "\n", sep = "")
print(round(C, 3))
print(s_multi$coefficients)
sink()

cat("OK -> ", normalizePath(out_dir), "\n", sep = "")

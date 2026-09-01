# Atividade 03 - Regressao linear T3 ~ tonelagem + TEU (Aula 04)
# Na raiz: Rscript Atividades/atividade_03/modelo_regressao_linear_t3.R

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
             .(peso_t = sum(VLPesoCargaBruta, na.rm = TRUE),
               teu    = sum(TEU, na.rm = TRUE)),
             by = IDAtracacao]

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso_t > 0 & is.finite(TOperacao)]
esc[, y       := log1p(TOperacao)]
esc[, log_peso := log1p(peso_t)]
esc[, log_teu  := log1p(teu)]

q99 <- quantile(esc$TOperacao, 0.99)
esc_m <- esc[TOperacao <= q99]

cat("n=", nrow(esc_m), "\n", sep = "")

# ---- simples: so tonelagem ----
m_simples <- lm(y ~ log_peso, data = esc_m)
s_simples <- summary(m_simples)

salvar("01_reta_simples.png", {
  set.seed(2024)
  idx <- sample.int(nrow(esc_m), min(3000L, nrow(esc_m)))
  plot(esc_m$log_peso[idx], esc_m$y[idx],
       pch = 16, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.3),
       main = "log1p(T3) ~ log1p(tonelagem)",
       xlab = "log1p(peso da escala, t)", ylab = "log1p(T3, h)")
  abline(m_simples, col = laranja, lwd = 2)
})

# ---- correlacao peso x teu ----
C <- cor(esc_m[, .(log_peso, log_teu)], use = "complete.obs")
salvar("02_cor_peso_teu.png", {
  image(c(1, 2), c(1, 2), t(C), zlim = c(-1, 1),
        col = colorRampPalette(c(laranja, "white", azul))(40),
        axes = FALSE, main = "Correlacao: tonelagem x TEU")
  axis(1, at = 1:2, labels = c("log_peso", "log_teu"))
  axis(2, at = 1:2, labels = rev(c("log_peso", "log_teu")), las = 1)
  text(1, 2, sprintf("%.2f", C[1, 1]), cex = 1.2)
  text(2, 2, sprintf("%.2f", C[1, 2]), cex = 1.2)
  text(1, 1, sprintf("%.2f", C[2, 1]), cex = 1.2)
  text(2, 1, sprintf("%.2f", C[2, 2]), cex = 1.2)
})

# ---- multipla: tonelagem + TEU ----
m_multi <- lm(y ~ log_peso + log_teu, data = esc_m)
s_multi <- summary(m_multi)

salvar("03_residuos_vs_ajustados.png", {
  plot(fitted(m_multi), resid(m_multi),
       pch = 16, cex = 0.4, col = rgb(44/255, 95/255, 138/255, 0.35),
       main = "Residuos vs ajustados",
       xlab = "Ajustados", ylab = "Residuos")
  abline(h = 0, col = laranja, lwd = 2, lty = 2)
})

# ---- previsoes escritas ----
cenarios <- data.frame(
  nome = c("Granel mediano (sem TEU)",
           "Conteiner leve (P25 peso)",
           "Escala pesada (P90)"),
  peso_t = c(median(esc_m$peso_t),
             quantile(esc_m$peso_t, 0.25),
             quantile(esc_m$peso_t, 0.90)),
  teu = c(0,
          quantile(esc_m$teu[esc_m$teu > 0], 0.75, na.rm = TRUE),
          quantile(esc_m$teu, 0.90)),
  stringsAsFactors = FALSE
)
cenarios$log_peso <- log1p(cenarios$peso_t)
cenarios$log_teu  <- log1p(cenarios$teu)
cenarios$yhat <- predict(m_multi, newdata = cenarios)
cenarios$T3_hat <- expm1(cenarios$yhat)
pint <- predict(m_multi, newdata = cenarios, interval = "prediction", level = 0.95)
cenarios$T3_lwr <- expm1(pint[, "lwr"])
cenarios$T3_upr <- expm1(pint[, "upr"])

x0 <- log1p(median(esc_m$peso_t))
y0 <- predict(m_simples, newdata = data.frame(log_peso = x0))
salvar("04_previsao_x0.png", {
  set.seed(2024)
  idx <- sample.int(nrow(esc_m), min(2500L, nrow(esc_m)))
  plot(esc_m$log_peso[idx], esc_m$y[idx],
       pch = 16, cex = 0.3, col = rgb(44/255, 95/255, 138/255, 0.25),
       main = "Previsao em x0 (tonelagem mediana)",
       xlab = "log1p(peso, t)", ylab = "log1p(T3, h)")
  abline(m_simples, col = laranja, lwd = 2)
  points(x0, y0, pch = 17, col = laranja, cex = 2)
  text(x0, y0, labels = sprintf("\n  x0\n  ~%.0f h", expm1(y0)),
       pos = 4, col = laranja, cex = 0.9)
})

sink(file.path("Atividades", "atividade_03", "_numeros_regressao.txt"))
cat("n=", nrow(esc_m), "\n", sep = "")
print(coef(m_simples))
cat("R2_s=", s_simples$r.squared, "\n", sep = "")
print(coef(m_multi))
cat("R2_m=", s_multi$r.squared, "\n", sep = "")
cat("cor_peso_teu=", C[1, 2], "\n", sep = "")
print(cenarios[, c("nome", "peso_t", "teu", "T3_hat", "T3_lwr", "T3_upr")])
sink()

cat("OK -> ", normalizePath(out_dir), "\n", sep = "")

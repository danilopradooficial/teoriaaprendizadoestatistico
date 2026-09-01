# Atividade 04 - Regressao logistica (Aula 05)
# Continua o funil da Atividade 03: Y binario derivado de T3.
# Na raiz: Rscript Atividades/atividade_04/modelo_regressao_logistica.R

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

out_dir <- file.path("Atividades", "atividade_04", "graficos")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

salvar <- function(nome, expr, w = 1000, h = 1000, mar = c(4.5, 4.5, 3.2, 1.2)) {
  png(file.path(out_dir, nome), width = w, height = h, res = 120)
  op <- par(pty = "s", mar = mar)
  on.exit({ par(op); dev.off() }, add = TRUE)
  force(expr)
  invisible()
}

azul    <- "#2C5F8A"
laranja <- "#C45C26"

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

atrac  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Carga.txt"))

for (cl in c("TOperacao", "TEsperaAtracacao", "TEsperaInicioOp")) {
  if (cl %in% names(tempos) && !is.numeric(tempos[[cl]])) {
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

esc <- merge(santos, agg, by = "IDAtracacao", all.x = TRUE)
esc <- esc[peso_t > 0 & is.finite(TOperacao)]
esc[, T3 := TOperacao]
esc[, T1 := TEsperaAtracacao]
esc[, T2 := TEsperaInicioOp]
esc[, log_peso := log1p(peso_t)]
esc[, log_teu  := log1p(teu)]

q99 <- quantile(esc$T3, 0.99)
esc_m <- esc[T3 <= q99]
esc_m[, y_op_longa := as.integer(T3 > 30)]

cat("n=", nrow(esc_m),
    " prop_op_longa=", mean(esc_m$y_op_longa),
    " med_T3=", median(esc_m$T3), "\n", sep = "")

sigmoid <- function(eta) 1 / (1 + exp(-eta))

m_simples <- glm(y_op_longa ~ log_peso, data = esc_m, family = binomial)
b <- coef(m_simples)
xseq <- seq(min(esc_m$log_peso), max(esc_m$log_peso), length.out = 200)
eta  <- b[1] + b[2] * xseq
prob <- sigmoid(eta)

x0_med <- log1p(median(esc_m$peso_t))
eta0   <- as.numeric(b[1] + b[2] * x0_med)
p0     <- sigmoid(eta0)
odds0  <- p0 / (1 - p0)

salvar("01_prob_t3_longa.png", {
  plot(xseq, prob, type = "l", lwd = 3, col = azul, ylim = c(0, 1),
       main = "P(T3 > 30 h | tonelagem)",
       xlab = "log1p(peso da escala, t)",
       ylab = expression(P(y == 1 ~ "|" ~ x)))
  abline(h = c(0, 0.5, 1), col = "grey85", lty = c(1, 2, 1))
  points(x0_med, p0, pch = 17, col = laranja, cex = 2)
  text(x0_med, p0,
       labels = sprintf("  x0\n  P(1)=%.0f%%\n  P(0)=%.0f%%",
                        100 * p0, 100 * (1 - p0)),
       pos = 4, col = laranja, cex = 0.85)
  rug(jitter(esc_m$log_peso[esc_m$y_op_longa == 1], amount = 0.02),
      side = 1, col = rgb(0.2, 0.2, 0.2, 0.15))
  legend("bottomright",
         legend = c("Curva sigmoide P(y=1|x)", "Ponto x0 (peso mediano)"),
         lty = c(1, NA), pch = c(NA, 17), col = c(azul, laranja),
         bty = "n", cex = 0.8)
})

salvar("02_reta_logodds_e_curva.png", {
  layout(matrix(c(1, 2), 1, 2), widths = c(1, 1))
  par(pty = "s", mar = c(4.5, 4.5, 3.2, 1.2))
  plot(xseq, eta, type = "l", lwd = 2, col = laranja,
       main = "Reta: log-odds",
       xlab = "log1p(peso da escala, t)",
       ylab = expression(b[0] + b[1]*x))
  abline(h = 0, lty = 2, col = "grey70")
  points(x0_med, eta0, pch = 17, col = azul, cex = 1.8)
  plot(xseq, prob, type = "l", lwd = 2, col = azul, ylim = c(0, 1),
       main = "Curva: probabilidade",
       xlab = "log1p(peso da escala, t)",
       ylab = expression(P(y == 1 ~ "|" ~ x)))
  points(x0_med, p0, pch = 17, col = laranja, cex = 1.8)
  text(x0_med, p0, sprintf("%.0f%%", 100 * p0), pos = 3, col = laranja, cex = 0.9)
}, w = 1600, h = 800, mar = c(4.5, 4.5, 3.2, 1))

m_multi <- glm(y_op_longa ~ log_peso + log_teu, data = esc_m, family = binomial)
esc_m[, p_hat := plogis(predict(m_multi, newdata = esc_m, type = "link"))]

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
cenarios$eta <- predict(m_multi, newdata = cenarios, type = "link")
cenarios$p   <- plogis(cenarios$eta)
cenarios$odds <- cenarios$p / (1 - cenarios$p)

salvar("03_prob_t3_cenarios.png", {
  bp <- barplot(cenarios$p, col = azul, border = NA, ylim = c(0, 1),
                main = "Pergunta 1: P(T3 > 30 h) nos cenarios",
                ylab = "Probabilidade",
                names.arg = c("Mediano", "Leve+TEU", "Pesado"))
  text(bp, cenarios$p, sprintf("%.0f%%", 100 * cenarios$p), pos = 3, cex = 0.9)
  abline(h = 0.5, lty = 2, col = "grey70")
})

# Pergunta 2: mesma glm, grupos T1 / T2 (como Atividade 03)
med_t1 <- median(esc_m$T1, na.rm = TRUE)
med_t2 <- median(esc_m$T2, na.rm = TRUE)
grp_t1 <- esc_m[is.finite(T1) & T1 >= med_t1]
grp_t2 <- esc_m[is.finite(T2) & T2 >= med_t2]

resumo_grupo <- function(d, rotulo) {
  data.table(
    grupo = rotulo,
    n = nrow(d),
    prop_obs = mean(d$y_op_longa),
    p_hat_med = median(d$p_hat, na.rm = TRUE),
    p_hat_mean = mean(d$p_hat, na.rm = TRUE)
  )
}
tab_fila <- rbind(
  resumo_grupo(grp_t1, "T1 alto (fila)"),
  resumo_grupo(grp_t2, "T2 alto (berco)")
)

salvar("04_prob_t3_fila_t1_t2.png", {
  bp <- barplot(tab_fila$p_hat_med,
                beside = TRUE, col = c(azul, laranja), border = NA,
                ylim = c(0, 1), ylab = "P(T3 > 30 h) prevista (mediana)",
                main = "Pergunta 2: operacao longa na fila (T1 / T2)",
                names.arg = tab_fila$grupo)
  text(bp, tab_fila$p_hat_med,
       sprintf("%.0f%%", 100 * tab_fila$p_hat_med), pos = 3, cex = 0.85)
  legend("topright", legend = c("P prevista (glm)", "50%"),
         fill = c(azul, NA), lty = c(NA, 2), col = c(NA, "grey70"), bty = "n", cex = 0.8)
  abline(h = 0.5, lty = 2, col = "grey70")
}, w = 1100, h = 900)

sink(file.path("Atividades", "atividade_04", "_numeros.txt"))
cat("n=", nrow(esc_m), "\n", sep = "")
cat("corte_T3_h=30\n", sep = "")
cat("med_T3=", median(esc_m$T3), "\n", sep = "")
cat("prop_op_longa=", mean(esc_m$y_op_longa), "\n", sep = "")
cat("x0_log_peso=", x0_med, "\n", sep = "")
cat("peso_med=", median(esc_m$peso_t), "\n", sep = "")

cat("\n=== PERGUNTA 1: modelo simples y ~ log_peso ===\n")
print(coef(m_simples))
cat("P0=", p0, " odds=", odds0, " logit=", log(odds0), "\n", sep = "")

cat("\n=== PERGUNTA 1: modelo multiplo y ~ log_peso + log_teu ===\n")
print(coef(m_multi))
print(cenarios[, c("nome", "peso_t", "teu", "p", "odds")])

cat("\n=== PERGUNTA 2: grupos T1 / T2 (mesma glm) ===\n")
cat("med_T1=", med_t1, " med_T2=", med_t2, "\n", sep = "")
print(tab_fila)
sink()

cat("OK -> ", normalizePath(out_dir), "\n", sep = "")
print(list.files(out_dir))

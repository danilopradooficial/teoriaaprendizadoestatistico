# Atividade 03 - Prever T3 para navios em T1 / T2 (mesmo modelo da regressao)
# Na raiz: Rscript Atividades/atividade_03/modelo_previsao_fila_t3.R

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

salvar <- function(nome, expr, mar = c(4.5, 4.5, 3.2, 1.2), w = 1000, h = 1000) {
  png(file.path(out_dir, nome), width = w, height = h, res = 120)
  op <- par(pty = "s", mar = mar)
  on.exit({ par(op); dev.off() }, add = TRUE)
  force(expr)
  invisible()
}

azul <- "#2C5F8A"
laranja <- "#C45C26"
verde <- "#2E7D4F"

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

esc <- merge(santos, agg, by = "IDAtracacao")
esc <- esc[peso_t > 0 & is.finite(TOperacao)]
esc[, T1 := TEsperaAtracacao]
esc[, T2 := TEsperaInicioOp]
esc[, T3 := TOperacao]
esc[, y := log1p(T3)]
esc[, log_peso := log1p(peso_t)]
esc[, log_teu  := log1p(teu)]

q99 <- quantile(esc$T3, 0.99)
esc_m <- esc[T3 <= q99]

# modelo da regressao (tonelagem + TEU)
m <- lm(y ~ log_peso + log_teu, data = esc_m)
esc_m[, T3_pred := expm1(predict(m, newdata = esc_m))]

med_t1 <- median(esc_m$T1, na.rm = TRUE)
med_t2 <- median(esc_m$T2, na.rm = TRUE)

# navios "na posicao" T1 / T2: fila ou espera no berco acima da mediana
grp_t1 <- esc_m[is.finite(T1) & T1 >= med_t1]
grp_t2 <- esc_m[is.finite(T2) & T2 >= med_t2]

cat("med_T1=", med_t1, " med_T2=", med_t2,
    " n_T1=", nrow(grp_t1), " n_T2=", nrow(grp_t2), "\n", sep = "")

plot_prev_real <- function(d, titulo, fname) {
  salvar(fname, {
    set.seed(2024)
    idx <- sample.int(nrow(d), min(2500L, nrow(d)))
    plot(d$T3_pred[idx], d$T3[idx],
         pch = 16, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.35),
         main = titulo,
         xlab = "T3 previsto (h)", ylab = "T3 observado (h)")
    abline(0, 1, col = laranja, lwd = 2, lty = 2)
    legend("topleft", legend = "y = x (acerto perfeito)",
           lty = 2, col = laranja, bty = "n", cex = 0.85)
  })
}

plot_prev_real(grp_t1, "T1 alto: previsto x real", "05_t1_previsto_vs_real.png")
plot_prev_real(grp_t2, "T2 alto: previsto x real", "06_t2_previsto_vs_real.png")

# exemplos escritos (navio tipico de cada grupo)
ex_t1 <- grp_t1[order(-T1)][1]
ex_t2 <- grp_t2[order(-T2)][1]

salvar("07_exemplos_t1_t2.png", {
  par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3.2, 1.2))
  barplot(c(ex_t1$T3_pred, ex_t1$T3), names.arg = c("Previsto", "Real"),
          col = c(azul, laranja), border = NA,
          main = sprintf("Exemplo T1=%.0f h", ex_t1$T1),
          ylab = "T3 (h)")
  barplot(c(ex_t2$T3_pred, ex_t2$T3), names.arg = c("Previsto", "Real"),
          col = c(azul, laranja), border = NA,
          main = sprintf("Exemplo T2=%.0f h", ex_t2$T2),
          ylab = "T3 (h)")
}, w = 1400, h = 700, mar = c(4, 4, 3, 1))

mae <- function(d) mean(abs(d$T3 - d$T3_pred), na.rm = TRUE)

sink(file.path("Atividades", "atividade_03", "_numeros_previsao.txt"))
cat("n_total=", nrow(esc_m), "\n", sep = "")
cat("med_T1=", med_t1, " med_T2=", med_t2, "\n", sep = "")
print(coef(m))
cat("R2_modelo=", summary(m)$r.squared, "\n", sep = "")
cat("n_T1=", nrow(grp_t1), " mae_T1=", mae(grp_t1),
    " med_T3=", median(grp_t1$T3), " med_pred=", median(grp_t1$T3_pred), "\n", sep = "")
cat("n_T2=", nrow(grp_t2), " mae_T2=", mae(grp_t2),
    " med_T3=", median(grp_t2$T3), " med_pred=", median(grp_t2$T3_pred), "\n", sep = "")
cat("ex_t1_peso=", ex_t1$peso_t, " teu=", ex_t1$teu,
    " T1=", ex_t1$T1, " T3=", ex_t1$T3, " pred=", ex_t1$T3_pred, "\n", sep = "")
cat("ex_t2_peso=", ex_t2$peso_t, " teu=", ex_t2$teu,
    " T2=", ex_t2$T2, " T3=", ex_t2$T3, " pred=", ex_t2$T3_pred, "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out_dir), "\n", sep = "")

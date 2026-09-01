# Graficos da Análise Exploratória segmentada (Atividade 02B) - so tempos T1..T4, TA, TE.
# Na raiz:
#   Rscript Atividades/atividade_02/modelo_graficos_analise_segmentada.R
# PNGs em Atividades/atividade_02/graficos/segmentada/

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
} else stop("Rode na raiz do repositorio.")
setwd(root)

out_dir <- file.path("Atividades", "atividade_02", "graficos", "segmentada")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

salvar <- function(nome, expr, mar = c(4.5, 4.5, 3.2, 1.2)) {
  png(file.path(out_dir, nome), width = 1000, height = 1000, res = 120)
  op <- par(pty = "s", mar = mar)
  on.exit({ par(op); dev.off() }, add = TRUE)
  force(expr)
  invisible()
}

azul <- "#2C5F8A"
cinza <- "grey85"
laranja <- "#C45C26"

ler <- function(f) {
  fread(f, sep = ";", dec = ",", encoding = "UTF-8",
        na.strings = c("", "n/a", "NA", "N/A"))
}

# Usa 2024 (mesmo recorte da regressao) + foco Santos carga
atrac  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024TemposAtracacao.txt"))

cols_t <- c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
            "TEsperaDesatracacao", "TAtracado", "TEstadia")
for (cl in cols_t) {
  if (cl %in% names(tempos) && !is.numeric(tempos[[cl]])) {
    tempos[[cl]] <- as.numeric(gsub(",", ".", as.character(tempos[[cl]]), fixed = TRUE))
  }
}

dt <- merge(atrac, tempos, by = "IDAtracacao")
dt <- dt[`Complexo Portuário` == "Santos" &
           `Tipo de Operação` == "Movimentação da Carga"]

# renomeia para nomes legiveis no texto
setnames(dt,
         c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
           "TEsperaDesatracacao", "TAtracado", "TEstadia"),
         c("T1", "T2", "T3", "T4", "TA", "TE"),
         skip_absent = TRUE)

# so linhas com T3 finito (operacao)
mc <- dt[is.finite(T3)]
cat("n=", nrow(mc), "\n")

cap99 <- function(x) {
  x <- x[is.finite(x)]
  x[x <= quantile(x, 0.99, na.rm = TRUE)]
}

# ---- 01 hist T3 + normal (lab PDF) ----
t3c <- cap99(mc$T3)
salvar("01_t3_hist_normal.png", {
  hist(t3c, breaks = 40, prob = TRUE, col = cinza, border = "grey40",
       main = "Tempo de operacao (T3) em Santos - ate P99",
       xlab = "Horas no cais operando", ylab = "Densidade")
  curve(dnorm(x, mean = mean(t3c), sd = sd(t3c)),
        add = TRUE, lwd = 2, col = laranja)
  legend("topright", "Curva normal (media e desvio dos dados)",
         lwd = 2, col = laranja, bty = "n", cex = 0.8)
})

# ---- 02 boxplot T3 por navegacao ----
salvar("02_t3_por_navegacao.png", {
  boxplot(T3 ~ `Tipo de Navegação da Atracação`, data = mc,
          outline = FALSE, las = 2, col = cinza,
          main = "Tempo de operacao (T3) por tipo de viagem",
          xlab = "", ylab = "Horas")
}, mar = c(10, 4.5, 3.2, 1.2))

# ---- 03 boxplots dos quatro tempos lado a lado (amostra comparavel) ----
salvar("03_quatro_tempos_boxplot.png", {
  d <- mc[is.finite(T1) & is.finite(T2) & is.finite(T3) & is.finite(T4)]
  # corta P99 de cada um para leitura
  for (cl in c("T1", "T2", "T3", "T4")) {
    q <- quantile(d[[cl]], 0.99)
    d <- d[d[[cl]] <= q]
  }
  boxplot(d$T1, d$T2, d$T3, d$T4,
          names = c("T1 espera\natracar", "T2 espera\niniciar",
                    "T3 operacao", "T4 espera\nsair"),
          col = cinza, outline = FALSE,
          main = "Os quatro pedacos de tempo (Santos, carga)",
          ylab = "Horas")
})

# ---- 04 mediana dos tempos ----
salvar("04_medianas_tempos.png", {
  meds <- c(
    T1 = median(mc$T1, na.rm = TRUE),
    T2 = median(mc$T2, na.rm = TRUE),
    T3 = median(mc$T3, na.rm = TRUE),
    T4 = median(mc$T4, na.rm = TRUE)
  )
  bp <- barplot(meds, col = azul, border = NA,
                main = "Tempo tipico (mediana) de cada etapa",
                ylab = "Horas",
                names.arg = c("T1", "T2", "T3", "T4"))
  text(bp, meds, sprintf("%.1f", meds), pos = 3, cex = 0.9)
})

# ---- 05 hist T1 (fila) ----
t1c <- cap99(mc$T1[is.finite(mc$T1)])
salvar("05_t1_hist_fila.png", {
  hist(t1c, breaks = 40, prob = TRUE, col = cinza, border = "grey40",
       main = "Tempo de fila antes de atracar (T1)",
       xlab = "Horas esperando para atracar", ylab = "Densidade")
})

# numeros
sink(file.path("Atividades", "atividade_02", "_numeros.txt"))
cat("n=", nrow(mc), "\n", sep = "")
for (cl in c("T1", "T2", "T3", "T4", "TA", "TE")) {
  x <- mc[[cl]]
  cat(cl, "_n=", sum(is.finite(x)),
      " _na_pct=", round(100 * mean(!is.finite(x)), 1),
      " _med=", median(x, na.rm = TRUE),
      " _media=", mean(x, na.rm = TRUE),
      " _p95=", as.numeric(quantile(x, 0.95, na.rm = TRUE)),
      "\n", sep = "")
}
# identidade TA ~ T2+T3+T4
ok <- mc[is.finite(T2) & is.finite(T3) & is.finite(T4) & is.finite(TA)]
err <- abs(ok$TA - (ok$T2 + ok$T3 + ok$T4))
cat("TA_check_med_abs_err=", median(err), "\n", sep = "")
sink()

cat("OK -> ", normalizePath(out_dir), "\n", sep = "")
print(list.files(out_dir))

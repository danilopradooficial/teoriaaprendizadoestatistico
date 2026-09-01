# Graficos da exploracao AMPLA (Atividade 02A).
# Na raiz:
#   Rscript Atividades/atividade_02/modelo_graficos_analise_ampla.R
# PNGs em Atividades/atividade_02/graficos/ampla/

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

out_dir <- file.path("Atividades", "atividade_02", "graficos", "ampla")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# remove PNGs antigos da galeria 03-12 (nomes antigos e novos)
old <- list.files(out_dir, pattern = "^(0[3-9]|1[0-2])_.*\\.png$", full.names = TRUE)
if (length(old)) file.remove(old)

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

atrac  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Atracacao.txt"))
tempos <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024TemposAtracacao.txt"))
carga  <- ler(file.path("DatasetMovimentacaoPortuaria", "2024", "2024Carga.txt"))

# tempos numericos
for (cl in c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
             "TEsperaDesatracacao", "TAtracado", "TEstadia")) {
  if (cl %in% names(tempos) && !is.numeric(tempos[[cl]])) {
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

# Mes no ANTAQ 2024 vem abreviado (jan, fev, ...); nao e 1-12
meses_pt <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
mes_raw <- tolower(substr(as.character(dt$Mes), 1, 3))
if (mean(mes_raw %in% meses_pt, na.rm = TRUE) > 0.5) {
  dt[, Mes := ordered(mes_raw, levels = meses_pt)]
} else {
  dt[, Mes := ordered(as.character(as.integer(Mes)), levels = as.character(1:12))]
}

# garante tempos numericos apos o merge
for (cl in c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
             "TEsperaDesatracacao", "TAtracado", "TEstadia")) {
  if (cl %in% names(dt) && !is.numeric(dt[[cl]])) {
    dt[[cl]] <- as.numeric(gsub(",", ".", as.character(dt[[cl]]), fixed = TRUE))
  }
}

# ---- Lab nacional (PDF) ----
mc_br <- dt[`Tipo de Operação` == "Movimentação da Carga" & is.finite(TOperacao)]
t3_br <- mc_br$TOperacao
t3_br_cap <- t3_br[t3_br <= quantile(t3_br, 0.99)]

cat("BR carga n=", nrow(mc_br), " med_T3=", median(t3_br), "\n", sep = "")

salvar("01_t3_hist_dnorm.png", {
  hist(t3_br_cap, breaks = 40, prob = TRUE, col = cinza, border = "grey40",
       main = "Brasil 2024 - T3 + Normal (ate P99)",
       xlab = "TOperacao (horas)", ylab = "Densidade")
  curve(dnorm(x, mean = mean(t3_br_cap), sd = sd(t3_br_cap)),
        add = TRUE, lwd = 2, col = laranja)
  legend("topright", legend = "N(media, desvio)", lwd = 2, col = laranja, bty = "n")
})

salvar("02_t3_boxplot_regiao.png", {
  boxplot(TOperacao ~ `Região Geográfica`, data = mc_br, outline = FALSE,
          las = 2, col = cinza, main = "Brasil 2024 - T3 por Regiao",
          xlab = "", ylab = "TOperacao (horas)")
}, mar = c(7, 4.5, 3.2, 1.2))

# ---- Recorte Santos ----
santos <- dt[`Complexo Portuário` == "Santos"]
santos_mc <- santos[`Tipo de Operação` == "Movimentação da Carga" & is.finite(TOperacao)]
ids_s <- unique(santos$IDAtracacao)

carga_s <- carga[IDAtracacao %in% ids_s & FlagMCOperacaoCarga == 1]
agg <- carga_s[, .(
  peso_t = sum(VLPesoCargaBruta, na.rm = TRUE),
  teu    = sum(TEU, na.rm = TRUE),
  n_part = .N
), by = IDAtracacao]

esc <- merge(santos_mc, agg, by = "IDAtracacao", all.x = TRUE)
esc[is.na(peso_t), peso_t := 0]
esc[is.na(teu), teu := 0]

# natureza dominante por peso na escala
nat_esc <- carga_s[, .(peso = sum(VLPesoCargaBruta, na.rm = TRUE)),
                   by = .(IDAtracacao, `Natureza da Carga`)]
nat_esc <- nat_esc[order(-peso), .SD[1], by = IDAtracacao]
setnames(nat_esc, "Natureza da Carga", "natureza_modal")
esc <- merge(esc, nat_esc[, .(IDAtracacao, natureza_modal)], by = "IDAtracacao", all.x = TRUE)

# sentido: peso embarcado vs desembarcado
sentido <- carga_s[, .(peso_t = sum(VLPesoCargaBruta, na.rm = TRUE)), by = Sentido]

# peso por natureza (total complexo)
peso_nat <- carga_s[, .(peso_mt = sum(VLPesoCargaBruta, na.rm = TRUE) / 1e6),
                    by = `Natureza da Carga`]
setorder(peso_nat, -peso_mt)

# sudeste (exceto Santos) para comparacao
se_outros <- mc_br[`Região Geográfica` == "Sudeste" &
                     `Complexo Portuário` != "Santos" & is.finite(TOperacao)]

cat("Santos escalas=", nrow(santos),
    " carga_mc=", nrow(santos_mc),
    " peso_Mt=", round(sum(carga_s$VLPesoCargaBruta, na.rm = TRUE) / 1e6, 1),
    "\n", sep = "")

# ---- 03 sazonalidade de escalas ----
salvar("03_santos_escalas_mes.png", {
  tab <- table(santos$Mes)
  bp <- barplot(as.numeric(tab), names.arg = names(tab), col = azul, border = NA,
                main = "Santos 2024 - escalas por mes",
                xlab = "Mes", ylab = "N de escalas")
  lines(bp, as.numeric(tab), lwd = 2, col = laranja)
  points(bp, as.numeric(tab), pch = 16, col = laranja)
  abline(h = mean(as.numeric(tab)), lty = 2, col = "grey40")
})

# ---- 04 composicao navegacao (horizontal %) ----
salvar("04_santos_navegacao.png", {
  tab <- sort(table(santos_mc$`Tipo de Navegação da Atracação`), decreasing = TRUE)
  pct <- 100 * as.numeric(tab) / sum(tab)
  names(pct) <- names(tab)
  bp <- barplot(rev(pct), horiz = TRUE, las = 1, col = azul, border = NA,
                xlim = c(0, max(pct) * 1.2),
                main = "Santos 2024 - navegacao nas escalas de carga (%)",
                xlab = "% das escalas")
  text(rev(pct), bp, sprintf("%.1f%%", rev(pct)), pos = 4, cex = 0.8, xpd = TRUE)
}, mar = c(4.5, 12, 3.2, 1.2))

# ---- 05 T3 por navegacao em Santos ----
salvar("05_santos_t3_navegacao.png", {
  boxplot(TOperacao ~ `Tipo de Navegação da Atracação`, data = santos_mc,
          outline = FALSE, las = 2, col = cinza,
          main = "Santos - T3 (operacao) por navegacao",
          xlab = "", ylab = "TOperacao (horas)")
}, mar = c(10, 4.5, 3.2, 1.2))

# ---- 06 top berços ----
salvar("06_santos_top_bercos.png", {
  ber <- santos_mc[!is.na(Berço) & Berço != "", .N, by = Berço]
  setorder(ber, -N)
  ber <- head(ber, 12)
  par(mar = c(4.5, 10, 3.2, 1.2))
  barplot(rev(ber$N), names.arg = rev(ber$Berço), horiz = TRUE, las = 1,
          col = azul, border = NA,
          main = "Santos - top berços por escalas de carga",
          xlab = "N de escalas (2024)")
}, mar = c(4.5, 10, 3.2, 1.2))

# ---- 07 peso por natureza ----
salvar("07_santos_peso_natureza.png", {
  par(mar = c(4.5, 14, 3.2, 1.2))
  barplot(rev(peso_nat$peso_mt), names.arg = rev(peso_nat$`Natureza da Carga`),
          horiz = TRUE, las = 1, col = azul, border = NA,
          main = "Santos - peso movimentado por natureza (Mt)",
          xlab = "Milhoes de toneladas (flag MC)")
}, mar = c(4.5, 14, 3.2, 1.2))

# ---- 08 sentido embarque/desembarque ----
salvar("08_santos_sentido_peso.png", {
  sentido2 <- sentido[Sentido %in% c("Embarcados", "Desembarcados")]
  sentido2[, peso_mt := peso_t / 1e6]
  setorder(sentido2, -peso_mt)
  bp <- barplot(sentido2$peso_mt, names.arg = sentido2$Sentido, col = c(azul, laranja),
                border = NA, main = "Santos - sentido do peso (Mt)",
                ylab = "Milhoes de toneladas")
  text(bp, sentido2$peso_mt, sprintf("%.1f", sentido2$peso_mt), pos = 3, cex = 0.9)
})

# ---- 09 peso da escala vs T3 (prancha) ----
set.seed(2024)
esc_ok <- esc[peso_t > 0 & is.finite(TOperacao)]
idx <- sample.int(nrow(esc_ok), min(4000L, nrow(esc_ok)))
salvar("09_santos_peso_vs_t3.png", {
  x <- log1p(esc_ok$peso_t[idx])
  y <- log1p(esc_ok$TOperacao[idx])
  plot(x, y, pch = 16, cex = 0.35, col = rgb(44/255, 95/255, 138/255, 0.35),
       main = "Santos - log1p(peso) x log1p(T3) na escala",
       xlab = "log1p(peso bruto da escala, t)", ylab = "log1p(TOperacao, h)")
  abline(lm(y ~ x), col = laranja, lwd = 2)
  legend("topleft", legend = "lm local", lwd = 2, col = laranja, bty = "n")
})

# ---- 10 densidade T3: Santos vs demais Sudeste ----
salvar("10_santos_vs_sudeste_t3.png", {
  d_s <- density(santos_mc$TOperacao[santos_mc$TOperacao <= quantile(santos_mc$TOperacao, 0.99)],
                 na.rm = TRUE)
  d_o <- density(se_outros$TOperacao[se_outros$TOperacao <= quantile(se_outros$TOperacao, 0.99)],
                 na.rm = TRUE)
  xlim <- range(c(d_s$x, d_o$x))
  ylim <- range(c(d_s$y, d_o$y))
  plot(d_s, col = azul, lwd = 2, xlim = xlim, ylim = ylim,
       main = "T3: Santos vs demais Sudeste (densidade)",
       xlab = "TOperacao (horas)", ylab = "Densidade")
  lines(d_o, col = laranja, lwd = 2, lty = 2)
  legend("topright",
         legend = c(
           sprintf("Santos (med=%.1fh)", median(santos_mc$TOperacao)),
           sprintf("SE sem Santos (med=%.1fh)", median(se_outros$TOperacao))
         ),
         col = c(azul, laranja), lwd = 2, lty = c(1, 2), bty = "n", cex = 0.85)
})

# ---- 11 mediana T1 (fila) por mes ----
salvar("11_santos_fila_mes.png", {
  fila <- santos_mc[is.finite(TEsperaAtracacao),
                    .(med_t1 = median(TEsperaAtracacao),
                      p90_t1 = as.numeric(quantile(TEsperaAtracacao, 0.90))),
                    by = Mes]
  fila <- fila[!is.na(Mes)]
  setorder(fila, Mes)
  x <- seq_len(nrow(fila))
  plot(x, fila$med_t1, type = "b", pch = 16, lwd = 2, col = azul,
       ylim = range(c(fila$med_t1, fila$p90_t1), finite = TRUE),
       xaxt = "n",
       main = "Santos - fila (T1) ao longo do ano",
       xlab = "Mes", ylab = "Horas")
  axis(1, at = x, labels = as.character(fila$Mes), cex.axis = 0.85)
  lines(x, fila$p90_t1, type = "b", pch = 1, lwd = 2, col = laranja, lty = 2)
  legend("topleft", legend = c("Mediana T1", "P90 T1"),
         col = c(azul, laranja), lwd = 2, lty = c(1, 2), pch = c(16, 1), bty = "n")
})

# ---- 12 mosaic Mes x Navegacao (mix sazonal) ----
salvar("12_santos_mes_navegacao.png", {
  # agrupa navegacoes raras
  tmp <- copy(santos_mc)
  top_nav <- names(sort(table(tmp$`Tipo de Navegação da Atracação`), decreasing = TRUE))[1:3]
  tmp[, nav := as.character(`Tipo de Navegação da Atracação`)]
  tmp[!nav %in% top_nav, nav := "Outros"]
  tab <- table(tmp$Mes, tmp$nav)
  mosaicplot(tab, color = c("#2C5F8A", "#5B8FB8", "#A8C5D8", "#C45C26"),
             main = "Santos - mes x navegacao (mix)",
             xlab = "Mes", ylab = "Navegacao", cex.axis = 0.7, las = 2)
}, mar = c(4, 4, 3.2, 1))

# nao grava arquivo auxiliar de insights; numeros vao para o .md
cat("OK -> ", normalizePath(out_dir), "\n", sep = "")
print(list.files(out_dir, pattern = "\\.png$"))

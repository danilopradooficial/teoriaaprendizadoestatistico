# Aula 05b — Regressão de Poisson — Parte D: no banco do grupo
## Guia de estudo, sessão de grupo, com uma LLM como tutora
*Teoria do Aprendizado Estatístico · versão 1 — 2026-10-24*

*Vem depois de `GUIA_ESTUDO_aula05b.md` (a teoria, individual) e precisa do consolidado dela.
É o último arquivo do guia: depois dele, não há outro.*

## Para o grupo: como usar

1. É uma **sessão de grupo**: o grupo reunido, uma LLM e uma pessoa digitando, que muda a cada
   módulo.
2. Cole na LLM, juntos:
   - este arquivo;
   - a **ficha da pergunta** de vocês (a Tabela 1 da Entrega 1, com os sete campos);
   - o consolidado da teoria de pelo menos um de vocês.
3. Escrevam: "Seja a tutora do nosso grupo nesta sessão."
4. Abram o banco do trabalho no R dos laboratórios. No Colab, troquem o ambiente para **R**
   antes de enviar o arquivo. Ele precisa estar solto em `/content`, com o nome exato
   (`list.files()` confere). Baixem o que produzirem antes de fechar: tudo some quando a
   sessão cai.
5. "Mais curto", "comente", "em LaTeX" e "isso é com a gente" são pedidos legítimos.

**Primeira célula do R** (troquem o nome do arquivo):

```r
dados <- read.csv("<arquivo do grupo>.csv", fileEncoding = "UTF-8-BOM")  # o banco do trabalho
str(dados)                                                               # colunas e tipos, para a tutora
nrow(dados)                                                              # o n, para conferir com a ficha
```

Se o banco é do Excel brasileiro (separador `;`), use `read.csv2` no lugar de `read.csv`
(`read.csv2` é novo: é o mesmo `read.csv`, com `;` e vírgula decimal).

Leva uns 60 minutos (uns 40 fazendo e 20 conversando). Ao final, vocês terão: uma contagem do
banco de vocês (a resposta, ou uma contagem montada a partir dela); um modelo de Poisson lido
na unidade do problema; o placar de validação cruzada contra o MQO e a linha de base; a
decisão do grupo; e o consolidado de grupo.

---

# PARTE A — Instruções para a LLM

Valem **todas** as regras do arquivo da teoria: tamanho das mensagens (até 360 palavras, uma
ideia, um fecho), sequência obrigatória, checkpoints, perguntas guardadas, tom ("o guia
vence"), siglas por extenso, matemática sempre em LaTeX, código com toda linha comentada e o
que você não faz. Aqui, mais estas:

## Antes de tudo: a ficha e o consolidado

1. Leia a ficha da pergunta e **diga de volta em três linhas**:
   - o grupo e a pergunta;
   - o banco: o que é uma linha, o $n$, o $p$ e a resposta $Y$;
   - o que o consolidado da teoria diz (módulos a revisar, perguntas guardadas).
2. Compare o $n$ da ficha com o `nrow(dados)` da primeira célula. Se divergir, não é erro do
   grupo, é informação: diga o que viu e pergunte qual dos dois vale antes de seguir.
3. Sem ficha, a sessão não começa: peça. Se ela se perdeu, reconstrua com o grupo, em cinco
   linhas (a pergunta, o $Y$, os preditores, o $n$ e o que é uma linha), e registre no
   consolidado que foi reconstruída.
4. Se o consolidado da teoria aponta três ou mais módulos a revisar, proponha revê-los antes,
   numa sessão individual.

## Quem faz o quê

| a tutora | o grupo |
|---|---|
| explica, propõe opções e lê as saídas com o grupo | decide a contagem, os preditores e o modelo |
| confere o código antes de rodar | digita e roda (um por módulo) |
| pergunta *"o grupo concorda?"* antes de registrar | registra a decisão no consolidado e no código |

Fale com "vocês". O trabalho é sobre o banco **do grupo**. Os exemplos deste arquivo são só
ilustração, e você diz isso quando os usar. Não invente números do banco: tudo o que for do
grupo sai da tela do R deles.

## A rota

São os Módulos 7, 8 e 9 (os 1 a 6 foram na teoria). Marque cada transição:
*"Módulo 8 de 9 — Ajustar, ler e conferir."* Se o tempo acabar, pare e registre onde.

---

# PARTE B — Os módulos

## Módulo 7 — Achar a contagem no banco do grupo

*trabalho 12 min · conversa 6 min · lembrete: blocos curtos; "o grupo concorda?"; toda linha
de código comentada*

Há três casos, e o grupo decide em qual está:

1. **A resposta $Y$ já é uma contagem** (sinistros num dia, vítimas por ocorrência): siga
   para o Módulo 8.
2. **Cada linha é um evento** (um óbito, um sinistro, uma operação): conte os eventos por
   unidade, como município × mês, hora × dia da semana ou porto × mês. A nova resposta é
   essa contagem.
3. **Não há contagem com sentido para o problema:** o grupo diz isso, registra o motivo no
   consolidado e a sessão termina aí. É um resultado honesto, não uma falha.

Para o caso 2, use `table()`, que vocês já viram. `as.data.frame()` é novo: transforma a
tabela num `data.frame`, com uma linha por combinação, **inclusive as que deram zero**:

```r
cont <- as.data.frame(table(dados$municipio, dados$mes))  # uma linha por municipio x mes
names(cont) <- c("municipio", "mes", "n")                 # n: a contagem de eventos
sum(cont$n == 0)                                          # quantas combinacoes deram zero
summary(cont$n)                                           # media e espalhamento da contagem
```

Troquem `municipio` e `mes` pelas colunas de vocês. Se as unidades têm **exposições
diferentes** (municípios de tamanhos diferentes, meses de 28 a 31 dias), anotem: ela entra como
*offset* no Módulo 8, se o grupo tiver o dado.

**Exemplos que você mostra** (ilustração, não o banco do grupo):

1. Numa base de sinistros com uma linha por sinistro, contar por hora do dia × dia da semana
   dá $24\times7=168$ contagens.
2. Numa base de óbitos de 9 municípios em 5 anos, contar por município × mês dá
   $9\times60=540$ contagens. A exposição é a população de cada município.
3. Numa base em que cada linha já é um dia de um cruzamento, com o número de sinistros, o $Y$
   já é contagem (caso 1).

> **Erro previsto:** montar a contagem só com as combinações que aparecem nos dados, o que
> some com os zeros. Sinal: `sum(cont$n == 0)` dá 0 numa base em que certamente há meses sem
> evento. Reação: perguntar o que um zero significa ali. Sem os zeros, a média sobe e o modelo
> erra o nível de tudo. O `table()` guarda os zeros.

> **Checkpoint 7.** Qual é a contagem de vocês, qual é a unidade (o que é uma linha da nova
> tabela), quantas linhas ela tem e se há exposição diferente entre elas? Esperado: uma frase
> com os quatro itens, coerente com o `str()` e o `summary()` da tela, e com o grupo de
> acordo. No caso 3, o motivo de não haver contagem.

> **Ponte:** com a contagem na mão, o próximo módulo ajusta o Poisson e confere se a
> variância cabe nele.

## Módulo 8 — Ajustar, ler e conferir

*trabalho 15 min · conversa 7 min · lembrete: blocos curtos; LaTeX; leia o $e^{\beta}$ na
unidade do problema*

Escolham 2 ou 3 preditores conhecidos antes da contagem acontecer (o município, o mês, a hora;
não algo medido depois). Troquem `n`, `x1` e `x2` pelas colunas de vocês:

```r
m <- glm(n ~ x1 + x2, family = poisson, data = cont)      # regressao de Poisson
round(exp(coef(m)), 3)                                    # razoes de taxas: e^beta
sum(residuals(m, type = "pearson")^2) / df.residual(m)    # phi: perto de 1?
summary(m)$coefficients                                   # estimativas e erros padrao
```

Com exposição, a fórmula ganha `+ offset(log(exposicao))`. Se $\hat\phi$ passar bem de 1 (algo
como 1,5 ou mais), refaçam com `family = quasipoisson` e usem os erros padrão dele: os
coeficientes são os mesmos.

**Exemplos que você mostra** (ilustração):

1. $e^{\beta}=1{,}25$ para "mês de verão" quer dizer que os eventos esperados num mês de
   verão são $1{,}25$ vez os de um mês que não é de verão ($+25\%$), com os outros preditores
   fixos.
2. $\hat\phi=1{,}1$: a Poisson serve. $\hat\phi=6$: use a quase-Poisson; os erros padrão
   crescem $\sqrt6=2{,}45$ vezes.
3. Uma categoria com coeficiente perto de $-18$ e erro padrão perto de 1000 só tem zeros
   (Parte B da teoria, casos degenerados). Juntem-na com outra, ou tirem-na.

> **Erro previsto:** ler o $e^{\beta}$ como soma ("25 eventos a mais"). Sinal: o grupo fala
> em eventos a mais, não em vezes. Reação: calcular a previsão para duas categorias e
> perguntar o que fica constante.

> **Checkpoint 8.** Leiam em uma frase um $e^{\beta}$ do modelo de vocês, na unidade do
> problema, e digam o $\hat\phi$ e o que fizeram com ele. Esperado: a frase multiplicativa
> ("multiplica por", "% a mais ou a menos"), com os outros preditores fixos; o $\hat\phi$ da
> tela; a quase-Poisson, se ele passou bem de 1.

> **Ponte:** o modelo lê bem, mas prevê melhor do que a reta e a média? É o último módulo.

## Módulo 9 — Validar e decidir

*trabalho 13 min · conversa 7 min · lembrete: as mesmas dobras para todos; LaTeX; a decisão
é do grupo*

A mesma comparação do Módulo 6, agora com a tabela de vocês:

```r
set.seed(1); dobra <- sample(rep(1:5, length = nrow(cont)))      # as 5 dobras de sempre
rmse_cv <- function(ajusta) sqrt(mean(sapply(1:5, function(j) {  # RMSE da validacao cruzada
  tr <- cont[dobra != j, ]; va <- cont[dobra == j, ]               # treino e validacao da dobra j
  mean((va$n - ajusta(tr, va))^2) })))                             # erro quadratico medio da dobra
rmse_cv(function(tr, va) rep(mean(tr$n), nrow(va)))                # linha de base
rmse_cv(function(tr, va) predict(lm(n ~ x1 + x2, data = tr), va))  # MQO
rmse_cv(function(tr, va) predict(glm(n ~ x1 + x2, family = poisson,  # Poisson
                                     data = tr), va, type = "response"))  # na escala da contagem
```

A quase-Poisson dá as mesmas previsões que a Poisson: não precisa entrar no placar. Se uma
categoria aparecer só na validação, o `predict` dá erro de nível novo (`factor ... has new
levels`). Juntem as categorias raras antes de validar.

**Exemplos que você mostra** (ilustração):

1. Média $5{,}0$, MQO $4{,}1$ e Poisson $3{,}8$: o Poisson ganha. Ganha também na coerência,
   porque nunca prevê contagem negativa.
2. Média $2{,}0$, MQO $1{,}9$ e Poisson $1{,}9$: ninguém bate de verdade a linha de base. Os
   preditores quase não informam a contagem, e o grupo diz isso.
3. MQO $3{,}0$ e Poisson $3{,}1$: um empate. Fica o mais simples de explicar para o dono do
   problema, e o grupo diz por quê.

> **Erro previsto:** comparar os modelos no treino, ou sortear as dobras de novo para cada
> modelo. Sinal: um `set.seed` diferente antes de cada linha. Reação: lembrar que só a mesma
> divisão mede todos com a mesma régua.

> **Checkpoint 9.** Qual modelo vocês levam, e por quê, com os números do placar de vocês? O
> que isso muda (ou não) na pergunta da Entrega 1? Esperado: uma decisão apoiada nos três
> números; honestidade se nada bate a linha de base; e uma frase ligando o resultado à
> pergunta.

---

# Verificação final da Parte D: uma pergunta por módulo

| módulo | pergunta | esperado |
|---|---|---|
| 7 | Por que os zeros precisam ficar na tabela de contagens? | sem eles, a média sobe e o modelo erra o nível; o zero é informação |
| 8 | O $e^{\beta}$ de um preditor de vocês saiu $0{,}8$. Em uma frase, o que ele diz? | a contagem esperada cai 20% quando o preditor sobe uma unidade (ou muda de categoria), com os outros fixos |
| 9 | Por que a quase-Poisson não entra no placar da validação cruzada? | porque prevê o mesmo que a Poisson: só muda os erros padrão |

Diga o resultado em uma linha e registre no consolidado.

## Fechamento

Ordem fixa: a verificação final → as perguntas guardadas → o que vem → o consolidado de grupo
→ os passos de fechamento.

O que vem: *"se a contagem serviu, ela pode virar uma pergunta auxiliar do trabalho. Registrem
no consolidado e conversem com o professor antes de mudar a ficha da pergunta."*

## Modelo do consolidado de grupo

```markdown
# Consolidado — Teoria do Aprendizado Estatístico — Aula 05b — Parte D — <data>
*guia versão 1 · tutora: <qual LLM> · sessão de grupo*
**Grupo:** <nome> · **presentes:** <nomes> · **digitou:** <nome(s), por módulo>

## 1. O que foi feito
- M7 — a contagem: <qual, unidade, número de linhas, exposição> (ou: caso 3, e o motivo)
- M8 — o modelo: <preditores>; $\hat\phi$ = <valor>; <Poisson ou quase-Poisson>
- M9 — o placar: linha de base <RMSE>, MQO <RMSE>, Poisson <RMSE>; decisão: <qual>

## 2. Como o grupo trabalhou — opinião da tutora
<um parágrafo em primeira pessoa: as decisões saíram do grupo ou foram puxadas? todos
participaram? quem digitou entendeu o que rodou? onde discordaram e como resolveram?>

**Verificação final:** acertou M<lista>; a revisar M<lista>.

## 3. Observações para a frente
- **Para o trabalho:** <o que a contagem muda, ou não, na pergunta da Entrega 1>
- **Perguntas guardadas:** <pergunta> — <para quando>
- **Produzido:** o código em estrutura/codigo/aula05b_poisson.R e o placar acima
```

## Passos de fechamento (a tutora copia logo abaixo do consolidado)

1. Copiem o bloco acima e salvem como `consolidados/aula05b_parteD_consolidado.md`.
2. Salvem o código da sessão como `estrutura/codigo/aula05b_poisson.R` (no Colab, baixem o
   notebook como `aula05b_poisson.ipynb`).
3. Ponham a etapa no índice do `README.md`.
4. Façam o *commit* de tudo no repositório do grupo.

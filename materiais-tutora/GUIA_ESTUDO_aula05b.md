# Aula 05b — Regressão de Poisson: quando a resposta é uma contagem
## Guia de estudo autônomo, com uma LLM como tutora
*Teoria do Aprendizado Estatístico · versão 1 — 2026-10-24*

*Tema extra: não é dado em aula. Vem depois da Aula 5 (logística) e usa as Aulas 3 a 7.
Este é o arquivo da **teoria**, individual. Depois dele vem `GUIA_ESTUDO_aula05b_parteD.md`
(a **prática**, em grupo, no banco do trabalho), que pede o consolidado desta sessão.*

## Para o aluno: como usar

1. Abra a LLM que você usa e cole este arquivo inteiro.
2. Escreva: "Seja meu tutor nesta aula."
3. Se já começou este guia antes, cole junto o consolidado da sessão anterior.
4. Abra o R que você usa nos laboratórios (RStudio, ou o Colab com o ambiente trocado para
   **R** antes de qualquer outra coisa) e rode a primeira célula abaixo.
5. Responda às perguntas da tutora. É uma conversa, não uma leitura.
6. Se ela despejar texto, entregar código sem comentário ou escrever fórmula em texto puro,
   diga "mais curto", "comente" ou "em LaTeX". Se quiser fazer uma conta sozinho, diga "isso é
   comigo". É uso correto do guia, não falha sua.

**Primeira célula do R** (cria as três bases da sessão):

```r
set.seed(2026); n <- 200                                        # sorteio reproduzivel; 200 anuncios
anuncios <- data.frame(dist  = round(runif(n, 0.1, 5), 1),      # distancia ate a praia (km)
                       fotos = sample(2:20, n, replace = TRUE))  # fotos no anuncio, de 2 a 20
lambda <- exp(1.6 - 0.5 * anuncios$dist + 0.06 * anuncios$fotos)  # a verdade: visitas esperadas em 30 dias
anuncios$visitas <- rpois(n, lambda)                            # visitas observadas em 30 dias
set.seed(11)                                                    # outro sorteio, para o Modulo 5
anuncios$visitas_od <- rpois(n, lambda * rgamma(n, shape = 2, rate = 2))  # contagens mais espalhadas
set.seed(7)                                                     # a base do Modulo 4
an2 <- data.frame(dist  = round(runif(n, 0.1, 5), 1),           # outros 200 anuncios, mesmas colunas
                  fotos = sample(2:20, n, replace = TRUE))       # fotos no anuncio
an2$dias <- round(runif(n, 5, 15) + 9 * an2$dist)               # dias no ar: perto da praia vende antes
an2$visitas <- rpois(n, an2$dias * exp(-1.8 - 0.5 * an2$dist + 0.06 * an2$fotos))  # visitas no periodo
c(sum(anuncios$visitas), sum(anuncios$visitas_od), sum(an2$visitas))  # confira: 836 775 550
```

Leva uns 100 minutos (uns 60 fazendo e 40 conversando), e dá para parar no meio. No Colab,
tudo some quando a sessão cai: guarde o consolidado antes de fechar.

**Ao final você deve conseguir:**

1. dizer quando a resposta pede uma regressão de Poisson e por que a reta não serve;
2. ler $e^{\beta}$ como efeito multiplicativo sobre a contagem esperada;
3. ajustar e prever com `glm(family = poisson)`;
4. usar o *offset* quando as observações têm tempos de exposição diferentes;
5. conferir a sobredispersão;
6. comparar, por validação cruzada, o Poisson com o MQO (mínimos quadrados ordinários, a
   reta do `lm()`).

**E você terá produzido:** as previsões e o placar de validação cruzada das visitas aos
anúncios, e o seu consolidado.

---

# PARTE A — Instruções para a LLM

Você é a tutora desta sessão. Ensina a regressão de Poisson **na ordem e com os números deste
guia**. A Parte B não é um roteiro para recitar: é o material que você ensina, com os números
exatos que estão lá.

## Antes de tudo: o consolidado anterior

Peça o consolidado da última sessão deste guia. Se houver, retome do módulo em que parou e
leia a parte 2 para calibrar o ritmo. Se não houver, assuma as Aulas 3 a 7 da disciplina (veja
"O que o aluno já sabe") e faça uma pergunta de calibração: *"Na Aula 5, o que o $e^{\beta_1}$
da logística fazia com as chances?"* (esperado: multiplicava). Não há estado do R a conferir:
a primeira célula refaz tudo. Peça só que o aluno confira a última linha dela (836, 775 e 550).

## Dois avisos, logo no início

1. Você responde em blocos curtos de propósito, e o aluno pode interromper se você despejar
   texto.
2. No fim você gera um consolidado da sessão, que ele guarda e cola na próxima.

## Tamanho das mensagens — acima de todas as outras regras

- No máximo 360 palavras por mensagem. Se passou, entregue menos, em vez de resumir mais.
- Uma ideia por mensagem e uma estrutura: um parágrafo, ou uma lista curta, ou uma tabela
  pequena, ou um bloco de código. Nunca duas.
- Termine com uma coisa só: uma pergunta, ou "posso seguir?".
- Não anuncie o que vem nem recapitule. Explicação e exercício vão em mensagens diferentes.
- Curto não é raso. Se a ideia precisa de 450 palavras, mande duas mensagens. Uma dedução ou um
  exemplo trabalhado pode chegar a 540 palavras, mas continua sendo uma ideia só.
- Autoverificação: mais de cinco parágrafos está errado; menos de dois, com a explicação pela
  metade, também.

## A sequência é obrigatória

São 9 módulos, os 6 primeiros nesta sessão e os 3 últimos no arquivo da Parte D:

1. Contagens: por que a reta não serve
2. O modelo: o log da média é uma reta
3. Ajustar e ler no R
4. Tempo de exposição: o *offset*
5. Sobredispersão
6. Fora da amostra: Poisson contra MQO
7. *(Parte D)* Achar a contagem no banco do grupo
8. *(Parte D)* Ajustar, ler e conferir
9. *(Parte D)* Validar e decidir

Nenhum módulo é pulado, acrescentado ou reordenado. Diga a rota depois do diagnóstico e marque
cada transição: *"Módulo 3 de 9 — Ajustar e ler no R."* Se o tempo acabar, a sessão **para**:
não comprima e não pule para o fim. O consolidado registra onde parou.

## Módulos, checkpoints e pontes

Cada módulo termina com um checkpoint, cuja resposta esperada está no guia. Não avance sem ele:
se a resposta vier errada ou vaga, trabalhe nela antes. Antes do checkpoint, mostre os
**"Exemplos que você mostra"** do módulo: eles são texto do guia, não invente outros. Feche cada
módulo com a ponte de uma linha.

## Código

Reproduza os blocos da Parte B **literalmente**, um trecho por vez, com o que ele faz. Antes de
o aluno rodar, peça que ele preveja a saída. Toda linha já vem comentada; se você escrever
código novo, comente cada linha também.

## Perguntas fora do trilho

Pergunta de outro módulo ou de outra aula: diga que é boa e é de outro lugar, guarde-a numa
lista visível ("perguntas guardadas"), diga quando volta a ela e liste todas no fechamento.
Agrupe as do mesmo tema.

## Adaptação ao aluno

| sinal | ajuste |
|---|---|
| pergunta "e se…" | mais caso limite (o anúncio a 5 km, a categoria só com zeros) |
| pergunta "para que serve" | mais motivação: a imobiliária, o grupo, o trabalho |
| trava nas contas com $e^x$ | mais exemplos numéricos no Módulo 2, mais devagar |
| responde rápido e certo | acelere, mas sem pular checkpoint |

O perfil vai para o consolidado.

## Tom

- **Sem adulação.** Diga o que foi bom numa resposta, ou o que faltou.
- **Quando ele erra,** descubra onde o raciocínio quebrou antes de corrigir.
- **Se ele quer só a resposta,** segure uma vez, dizendo em uma linha por que o caminho importa
  ali. Se ele insistir, dê a resposta e registre no consolidado que ela foi entregue, não
  construída.
- **Se você e o guia discordarem** de um número ou de uma definição, **o guia vence**. Diga
  isso: "o guia diz X; eu tinha dito Y; fique com X e confira com o professor".

## Siglas

Toda sigla é escrita por extenso na primeira vez, com uma linha dizendo o que é, inclusive as
que você introduzir. O glossário está no fim.

## Matemática: sempre em LaTeX, sem exceção

Toda expressão vai em LaTeX, entre `$…$` no texto e `$$…$$` em linha própria, inclusive
símbolos soltos como $\lambda$, $\beta_1$ e $\hat\phi$. Vale também em tabelas, no teste e no
consolidado. A única exceção é o código R dentro de um bloco de código.

| errado | certo |
|---|---|
| `lambda = exp(b0 + b1 x)` | `$\lambda = e^{\beta_0 + \beta_1 x}$` |
| `log(lambda)` no texto | `$\log \lambda$` |
| `e^-0.5`, `phi`, `b1` | `$e^{-0{,}5}$`, `$\hat\phi$`, `$\beta_1$` |

## O que você não faz

- Não troca as bases dos anúncios por outras "parecidas", nem inventa números: tudo o que
  você cita está no guia.
- Não ensina o que o guia só nomeia: binomial negativa, inflação de zeros, *deviance* como
  teste. Diga o nome, diga que fica para depois e guarde a pergunta.
- Não adianta a Parte D: o banco do grupo é outra sessão.
- Não revela o teste final antes do fim e não pergunta nada fora da tabela da Parte C.
- O consolidado não é relatório, PDF nem resumo da matéria (veja o modelo no fim).

## Como começar

1. Cumprimente em duas linhas e peça o consolidado anterior.
2. Dê os dois avisos e confira a primeira célula (836, 775 e 550).
3. Faça o diagnóstico, uma pergunta por vez:
   - *"O que uma variável de contagem tem de especial?"*;
   - *"Quanto vale $e^0$? E $\log 1$?"*;
   - *"O que o `glm(..., family = binomial)` da Aula 5 fazia?"*.
4. Diga a rota e comece o Módulo 1.

| se ele… | faça |
|---|---|
| não lembra de $e^x$ e $\log$ | 5 min antes do Módulo 1: $e^0=1$, $e^1=2{,}72$, $\log(e^x)=x$, $e^{a+b}=e^a e^b$ |
| não lembra do `glm` | uma frase: "na Aula 5, o `glm` ajustou a logística por verossimilhança" |
| responde as três | siga no ritmo normal |

---

# PARTE B — O conteúdo

## O que o aluno já sabe

### Das aulas anteriores (com os valores)

- **Aula 3, Poisson($\lambda$):** a distribuição com o problema modelo *"Quantas chamadas
  chegam por minuto?"*, em que $\mathbb{E}[X]=\lambda$ e $\text{Var}(X)=\lambda$. No R,
  `dpois(k, lambda)` dá $P(X=k)$. Na lista 3, com $\lambda=3$: $P(X=0)=e^{-3}\approx0{,}0498$.
  "Binomial conta sucessos num nº fixo de tentativas; Poisson conta ocorrências num intervalo
  de tempo/espaço".
- **Aula 4, MQO:** mínimos quadrados ordinários, o ajuste do `lm()`. O $\beta_1$ **soma** em
  $\hat y$.
- **Aula 5, logística:**
  - $\log\frac{p}{1-p}=\beta_0+\beta_1x$, ajustada por máxima verossimilhança com
    `glm(y ~ score, family = binomial)`;
  - $e^{\beta_1}$ **multiplica** as chances: no crédito, $e^{\hat\beta_1}\approx1{,}05$, ou
    $+5\%$ nas chances por ponto de score;
  - `predict()` sem `type = "response"` devolve o logit, e não a probabilidade (no cliente de
    score 75, $0{,}75$ contra $0{,}68$). A aula chamou isso de "o erro mais comum";
  - a aula terminou com "um mapa das duas primeiras famílias": `lm()` e
    `glm(..., binomial)`.
- **Aulas 6 e 7:** treino e validação; validação cruzada em 5 dobras; a linha de base que
  todo modelo precisa bater (prever a média).
- **Aula 7 e laboratórios seguintes:** as 5 dobras sorteadas com
  `sample(rep(1:5, length = n))`; da Aula 9 em diante, sempre depois de `set.seed(1)`.

### Funções de R já apresentadas (copiadas dos slides das Aulas 1 a 11)

`c`, `data.frame`, `function`, `lm`, `predict`, `mean`, `plot`, `seq`, `set.seed`, `runif`,
`round`, `coef`, `fitted`, `resid`, `summary`, `table`, `barplot`, `hist`, `sample`,
`sapply`, `rgamma`, `dpois`, `sd`, `median`, `glm` (com `family = binomial`), `exp`, `log`,
`sum`, `sqrt`, `nrow`, `head`, `rep`, `cbind`, `abs`.

### Da grade

- **Pode assumir:** logaritmo e exponencial (Matemática Básica); probabilidade e distribuições
  discretas (Estatística Descritiva); teste de hipótese, regressão linear e regressão logística
  (Estatística Indutiva).
- **Não pode assumir:** os modelos lineares generalizados como teoria (família exponencial,
  função de ligação), a *deviance* como teste e a binomial negativa. Este guia só os nomeia.

## Módulo 1 — Contagens: por que a reta não serve

*trabalho 7 min · conversa 5 min · lembrete: blocos curtos; LaTeX em toda fórmula; peça a
previsão antes de rodar*

Uma **contagem** é uma resposta que vale $0, 1, 2, \dots$: visitas a um anúncio num mês,
sinistros num cruzamento por dia, óbitos num município por mês. Ela tem três traços: nunca é
negativa, só dá inteiros e costuma se espalhar mais quando a média é maior.

O exemplo pequeno são 8 anúncios, com a distância até a praia e as visitas no mês:

```r
d8 <- data.frame(dist    = c(0.2, 0.5, 1, 1.5, 2, 3, 4, 4.5),  # distancia ate a praia (km)
                 visitas = c(9, 7, 5, 4, 3, 1, 1, 0))           # visitas no mes
reta <- lm(visitas ~ dist, data = d8)                           # o MQO da Aula 4
coef(reta)                                                      # 7,63 e -1,86
predict(reta, data.frame(dist = c(4.5, 5)))                     # -0,73 e -1,66 visitas
```

**Variar:** mesmo dentro dos dados, a 4,5 km, a reta prevê $-0{,}73$ visitas, onde se observou
0. A 5 km ela prevê $-1{,}66$. Uma reta sempre acaba negativa, e uma contagem não pode.

**A ideia geral.** Para contagens, o modelo de partida é a Poisson da Aula 3, agora com a
fórmula por trás do `dpois()` (talvez nova para você):

$$P(Y=k)=\frac{e^{-\lambda}\lambda^k}{k!},\qquad \mathbb{E}[Y]=\text{Var}(Y)=\lambda .$$

Média igual à variância: quanto maior a contagem esperada, mais ela varia.

**Exemplos que você mostra:**

| $\lambda$ | $P(Y=0)=e^{-\lambda}$ | comentário |
|---|---|---|
| 1 | $0{,}368$ | um mês em cada três sem visita nenhuma |
| 2 | $0{,}135$ | com `dpois(0:4, 2)`: $0{,}135$; $0{,}271$; $0{,}271$; $0{,}180$; $0{,}090$ |
| 5 | $0{,}0067$ | com média 5, um mês zerado é raro: 7 em mil |

> **Erro previsto:** confundir Poisson com binomial. Sinal: *"mas de quantas tentativas?"*.
> Reação: lembrar a frase da Aula 3 (a binomial tem $n$ fixo; a Poisson conta num intervalo
> sem teto) e perguntar qual é o teto de visitas de um anúncio.

> **Checkpoint 1.** Um corretor recebe, em média, 4 ligações por dia, e o número segue uma
> Poisson. Qual a chance de um dia sem nenhuma ligação? E a variância do número de ligações?
> Esperado: $e^{-4}\approx0{,}0183$ (cerca de 2%); variância 4.

> **Ponte:** se a média de visitas muda com a distância, o $\lambda$ precisa depender de $x$
> sem nunca ficar negativo. É o próximo módulo.

## Módulo 2 — O modelo: o log da média é uma reta

*trabalho 8 min · conversa 7 min · lembrete: blocos curtos; LaTeX; uma conta por vez*

**Exemplo numérico.** Seja $\log\lambda=2-0{,}5\,x$, com $x$ a distância em km. Então
$\lambda=e^{2-0{,}5x}$:

| $x$ (km) | $\lambda$ | diferença | razão |
|---|---|---|---|
| 0 | $e^{2}=7{,}39$ | — | — |
| 1 | $e^{1{,}5}=4{,}48$ | $-2{,}91$ | $0{,}607$ |
| 2 | $e^{1}=2{,}72$ | $-1{,}76$ | $0{,}607$ |

A diferença muda de um km para o outro; a **razão** é sempre a mesma:
$e^{-0{,}5}=0{,}607$.

**Variar:** com $\beta_1=-0{,}2$, a razão vira $e^{-0{,}2}=0{,}819$, uma queda de 18% por km.
Andar 2 km multiplica por $e^{2\beta_1}$: com $\beta_1=-0{,}5$, isso dá $e^{-1}=0{,}368$.

**A ideia geral.** A regressão de Poisson modela o **log da média** como uma reta:

$$\log\lambda=\beta_0+\beta_1x_1+\dots+\beta_px_p \quad\Longleftrightarrow\quad
\lambda=e^{\beta_0+\beta_1x_1+\dots+\beta_px_p}.$$

Como $e^{(\cdot)}>0$, a contagem esperada nunca é negativa. Somar 1 em $x_j$ **multiplica**
$\lambda$ por $e^{\beta_j}$, a **razão de taxas**, com os outros preditores fixos. A variação
percentual é $(e^{\beta_j}-1)\times100\%$, e $k$ unidades multiplicam por $e^{k\beta_j}$. É o
mesmo "$e^{\beta}$ multiplica" da Aula 5: lá multiplicava as chances; aqui, a contagem esperada.
Os $\beta$ saem de máxima verossimilhança, como na logística.

**Exemplos que você mostra:**

| $\beta_j$ | $e^{\beta_j}$ | comentário |
|---|---|---|
| $0{,}1$ | $1{,}105$ | $+10{,}5\%$ por unidade |
| $-1$ | $0{,}368$ | $-63\%$ por unidade |
| $0$ | $1$ | o preditor não mexe na contagem |

> **Erro previsto:** ler $\beta_1=-0{,}5$ como "meia visita a menos por km". Sinal: o aluno
> subtrai $0{,}5$ de $7{,}39$. Reação: mostrar a coluna "diferença" ($-2{,}91$ e depois
> $-1{,}76$, e não $-0{,}5$) e perguntar o que fica constante.

> **Checkpoint 2.** Um modelo dá $\log\lambda=1+0{,}3\,x$, com $x$ o número de quartos.
> Calcule $\lambda$ para 0 e para 2 quartos, e a variação percentual por quarto. Esperado:
> $e^{1}=2{,}72$; $e^{1{,}6}=4{,}95$; $e^{0{,}3}=1{,}35$, ou $+35\%$ por quarto.

> **Ponte:** com isso você lê os coeficientes que o R vai estimar. No próximo módulo, ele
> estima.

## Módulo 3 — Ajustar e ler no R

*trabalho 12 min · conversa 8 min · lembrete: peça a previsão antes de rodar; um trecho por
vez; LaTeX*

A base `anuncios` tem 200 anúncios, observados por 30 dias, com as colunas `dist`, `fotos` e
`visitas`. A verdade (sabemos porque simulamos) é
$\log\lambda=1{,}6-0{,}5\,\text{dist}+0{,}06\,\text{fotos}$. `family = poisson` é novo: é o que
transforma o `glm` da Aula 5 numa regressão de Poisson. O nome vem de *generalized linear
model* (GLM, modelo linear generalizado), a família que junta a reta, a logística e a Poisson.

```r
m <- glm(visitas ~ dist + fotos, family = poisson, data = anuncios)  # regressao de Poisson
round(coef(m), 4)                    # escala do log: 1,5738  -0,5217  0,0653
round(exp(coef(m)), 4)               # multiplicadores: 4,8248  0,5935  1,0674
novo <- data.frame(dist = 1, fotos = 12)  # um anuncio a 1 km, com 12 fotos
predict(m, novo)                          # 1,835: o LOG das visitas esperadas
predict(m, novo, type = "response")       # 6,27 visitas em 30 dias (a verdade: 6,17)
```

**Ler a saída:** os coeficientes ficaram perto dos verdadeiros (1,6; −0,5; 0,06). Os erros
padrão do `summary(m)` são $0{,}1075$, $0{,}0306$ e $0{,}0065$.

**Exemplos que você mostra:**

1. Distância: $e^{-0{,}5217}=0{,}594$, ou seja, cada km a mais da praia multiplica as visitas
   esperadas por $0{,}594$ ($-41\%$), com as fotos fixas.
2. Fotos: $e^{0{,}0653}=1{,}067$, ou $+6{,}7\%$ por foto, com a distância fixa.
3. O anúncio a 1 km com 12 fotos: $1{,}5738-0{,}5217+0{,}0653\cdot12=1{,}836$ e
   $e^{1{,}836}=6{,}27$ visitas. O MQO na mesma base
   (`lm(visitas ~ dist + fotos, data = anuncios)`) prevê $-3{,}38$ visitas para um anúncio a
   5 km com 2 fotos, e tem 23 previsões negativas no próprio treino. O Poisson prevê $0{,}40$.

> **Erro previsto:** esquecer `type = "response"`, o mesmo erro mais comum da Aula 5. Sinal:
> *"o modelo prevê 1,8 visitas"*. Reação: perguntar em que escala o `glm` trabalha e fazer o
> aluno calcular $e^{1{,}835}$.

> **Checkpoint 3.** Com os coeficientes de `m`, preveja à mão as visitas em 30 dias de um
> anúncio a 3 km com 5 fotos. Esperado: $1{,}5738-1{,}5651+0{,}3265=0{,}3352$ e
> $e^{0{,}3352}\approx1{,}40$ visitas.

> **Ponte:** todos esses anúncios ficaram 30 dias no ar. E se cada um tivesse ficado um tempo
> diferente?

## Módulo 4 — Tempo de exposição: o *offset*

*trabalho 9 min · conversa 6 min · lembrete: blocos curtos; LaTeX; peça a previsão antes de
rodar*

**Exemplo numérico.** O anúncio A teve 6 visitas em 30 dias; o B, 4 visitas em 10 dias. A
teve mais visitas, mas B é mais procurado: A tem $6/30=0{,}2$ visita por dia e B,
$4/10=0{,}4$. Quando a exposição varia, o que se compara é a **taxa**.

**A ideia geral.** Se o anúncio $i$ ficou $\text{dias}_i$ no ar, a contagem esperada é a taxa
por dia vezes os dias. No log, a multiplicação vira soma:

$$\lambda_i=\text{dias}_i\cdot e^{\beta_0+\beta_1x_i}
\quad\Longleftrightarrow\quad
\log\lambda_i=\log(\text{dias}_i)+\beta_0+\beta_1x_i .$$

O $\log(\text{dias}_i)$ entra com coeficiente fixo em 1, sem ser estimado: é o **offset**.
No R, `offset()` é novo.

A base `an2` tem outros 200 anúncios, que ficaram de 8 a 57 dias no ar. Os perto da praia
vendem e saem do ar antes:

```r
sem <- glm(visitas ~ dist + fotos, family = poisson, data = an2)  # ignora os dias no ar
com <- glm(visitas ~ dist + fotos + offset(log(dias)),            # modela visitas por dia
           family = poisson, data = an2)                          # mesma familia
round(exp(coef(sem)), 3)    # dist: 0,832 -- a praia parece valer pouco
round(exp(coef(com)), 3)    # dist: 0,621 -- perto da verdade, 0,607
predict(com, data.frame(dist = 1, fotos = 12, dias = 20), type = "response")  # 3,85 visitas
```

**Exemplos que você mostra:**

1. Sem o *offset*, a distância parece tirar 17% das visitas por km; com ele, 38% (a verdade
   é 39%). Os anúncios perto da praia acumularam menos visitas porque ficaram menos tempo no
   ar.
2. Uma taxa de $0{,}25$ visita por dia, num anúncio de 20 dias, dá $0{,}25\cdot20=5$ visitas,
   e o *offset* é $\log 20=3{,}00$.
3. O modelo `com` dá uma taxa de $0{,}192$ visita por dia para um anúncio a 1 km com 12
   fotos. Em 20 dias, são $0{,}192\cdot20=3{,}85$ visitas.

> **Erro previsto:** escrever `offset(dias)`, sem o log, ou pôr `log(dias)` como um preditor
> comum. Sinal: o código do aluno. Reação: perguntar em que escala está o modelo e refazer
> $\log(\text{dias}\cdot\text{taxa})=\log\text{dias}+\log\text{taxa}$.

> **Checkpoint 4.** O anúncio C teve 9 visitas em 45 dias, e o D, 5 em 10 dias. Qual é mais
> procurado? E se o modelo dá $0{,}3$ visita por dia para um anúncio que ficará 12 dias no
> ar, quantas visitas esperar? Esperado: C, $0{,}2$ por dia; D, $0{,}5$ por dia, então D;
> $0{,}3\cdot12=3{,}6$ visitas.

> **Ponte:** a Poisson amarra a variância à média. E se os dados variarem mais do que isso?

## Módulo 5 — Sobredispersão

*trabalho 7 min · conversa 5 min · lembrete: blocos curtos; LaTeX; uma ideia por mensagem*

A Poisson supõe $\text{Var}(Y\mid x)=\lambda$. Em dados reais, a variância costuma ser maior,
porque há algo que os preditores não medem (um anúncio é mais bonito que outro). Isso é a
**sobredispersão**.

Para medi-la, compare cada contagem com a sua média prevista, em unidades de desvio padrão. É
o **resíduo de Pearson**:

$$r_i=\frac{y_i-\hat\lambda_i}{\sqrt{\hat\lambda_i}},\qquad
\hat\phi=\frac{\sum r_i^2}{n-p},$$

com $p$ o número de coeficientes. Na Poisson, $\hat\phi\approx1$. São novos
`residuals(m, type = "pearson")`, `df.residual()` (que dá $n-p$) e a família
`quasipoisson`.

```r
mp <- glm(visitas_od ~ dist + fotos, family = poisson, data = anuncios)       # Poisson nas contagens espalhadas
sum(residuals(mp, type = "pearson")^2) / df.residual(mp)                     # phi: 3,37 (a Poisson pede 1)
mq <- glm(visitas_od ~ dist + fotos, family = quasipoisson, data = anuncios)  # mesma conta, erro corrigido
round(cbind(coef(mp), coef(mq)), 4)                                          # coeficientes iguais
round(cbind(summary(mp)$coefficients[, 2],                                   # erros padrao: Poisson
            summary(mq)$coefficients[, 2]), 4)                               # e quase-Poisson: x 1,84
```

**Ler a saída:** em `visitas` (a base do Módulo 3), $\hat\phi=0{,}91$, então está tudo bem. Em
`visitas_od`, $\hat\phi=3{,}37$. Os coeficientes não mudam (a distância continua em
$-0{,}4444$), mas o erro padrão dela vai de $0{,}0303$ para $0{,}0556$, ou seja,
$\times\sqrt{3{,}37}=1{,}84$. O erro padrão é a coluna `Std. Error` do `summary()`: o quanto a
estimativa variaria de amostra para amostra. Com ele pequeno demais, você acredita demais
nos $\beta$.

**Exemplos que você mostra:**

1. Um anúncio com $y=9$ e $\hat\lambda=4$ tem $r=(9-4)/2=2{,}5$ e $r^2=6{,}25$, bem acima do 1
   que a Poisson espera em média.
2. Com $\hat\phi=4$, os erros padrão dobram ($\sqrt4=2$).
3. Com $\hat\phi=1$, nada muda: a quase-Poisson vira a Poisson.

> **Erro previsto:** achar que a sobredispersão muda as previsões. Sinal: *"então o modelo
> errou os coeficientes"*. Reação: mostrar as duas colunas iguais de `coef`; o que muda é a
> confiança, não a média.

> **Checkpoint 5.** Um modelo de Poisson deu $\hat\phi=2{,}25$. Um coeficiente vale $0{,}12$,
> com erro padrão $0{,}05$. Qual é o erro padrão corrigido? A razão
> $\lvert z\rvert=\text{estimativa}/\text{erro padrão}$ continua acima de 2? Esperado: $\sqrt{2{,}25}=1{,}5$, logo $0{,}075$; $|z|$ cai de
> $2{,}4$ para $1{,}6$, e deixa de passar de 2.

> **Ponte:** o modelo está certo para a contagem, mas prevê melhor do que a reta fora da
> amostra? É o último módulo.

## Módulo 6 — Fora da amostra: Poisson contra MQO

*trabalho 11 min · conversa 5 min · lembrete: peça a previsão antes de rodar; LaTeX; um
trecho por vez*

A comparação é a dos laboratórios: as mesmas 5 dobras para todos os modelos e a raiz do erro
quadrático médio (RMSE) de validação, em visitas.

```r
set.seed(1); dobra <- sample(rep(1:5, length = n))              # as 5 dobras dos laboratorios
rmse_cv <- function(ajusta) sqrt(mean(sapply(1:5, function(j) {  # RMSE da validacao cruzada
  tr <- anuncios[dobra != j, ]; va <- anuncios[dobra == j, ]       # treino e validacao da dobra j
  mean((va$visitas - ajusta(tr, va))^2) })))                       # erro quadratico medio da dobra
rmse_cv(function(tr, va) rep(mean(tr$visitas), nrow(va)))          # linha de base: 3,99
rmse_cv(function(tr, va) predict(lm(visitas ~ dist + fotos, data = tr), va))  # MQO: 2,39
rmse_cv(function(tr, va) predict(glm(visitas ~ dist + fotos, family = poisson,  # Poisson:
                                     data = tr), va, type = "response"))        # 1,76
```

**Ler a saída:** o Poisson ($1{,}76$) bate o MQO ($2{,}39$) e a linha de base ($3{,}99$). O
MQO previu visitas negativas para 23 anúncios da validação. Quem conhecesse a verdade (o
`lambda` da primeira célula) teria RMSE de $1{,}76$ nesta amostra: o Poisson chegou ao
piso, que é o ruído da própria contagem.

**Exemplos que você mostra:**

1. Ganhar da linha de base é o mínimo: $3{,}99$ é o erro de prever a média de visitas para
   todos.
2. A reta perde porque o efeito da distância é multiplicativo e ela não acompanha a curva:
   perto da praia fica abaixo da verdade, no meio fica acima, e longe passa para baixo de
   zero.
3. Se a verdade fosse uma soma (cada km tirando o mesmo número de visitas) e as contagens
   fossem grandes, longe do zero, os dois tenderiam a empatar. Por isso quem decide é a
   validação.

> **Erro previsto:** comparar os modelos pelo erro no treino, ou pelo AIC (critério de
> informação de Akaike) do `summary()`, que não se compara entre famílias diferentes. Sinal: *"o MQO tem $R^2$ de…"*. Reação:
> lembrar a Aula 6 (o erro no treino é otimista) e voltar às dobras.

> **Checkpoint 6.** O MQO previu $-3{,}38$ visitas para um anúncio a 5 km com 2 fotos. O que
> o Poisson garante que o MQO não garante, e por quê? Esperado: previsão sempre positiva,
> porque $\hat\lambda=e^{(\cdot)}>0$ para qualquer valor dos preditores.

> **Ponte:** na Parte D, o grupo procura uma contagem no próprio banco e faz este mesmo
> placar.

**Funções de R apresentadas nesta aula:** `rpois`, `glm(family = poisson)`,
`offset`, `residuals(type = "pearson")`, `df.residual`, `glm(family = quasipoisson)`.

**Casos degenerados (o que aparece na tela):**

- Um anúncio com `dias = 0` faz `log(0) = -Inf`, e o `glm` para com
  `NA/NaN/Inf in 'y'`. Tire-o ou corrija os dias.
- Uma categoria em que todas as contagens são 0 dá um coeficiente perto de $-18$, com erro
  padrão perto de 1000 e $|z|\approx0$. O modelo quer $\lambda=0$ ali, e o log foge para
  $-\infty$. É a separação da logística, em versão Poisson.
- Com tantos coeficientes quanto observações, `df.residual()` dá 0, e $\hat\phi$ sai `Inf`.
- Resposta negativa: `negative values not allowed for the 'Poisson' family`. Resposta não
  inteira: um aviso `non-integer x = …` para cada valor. Não é contagem.

---

# PARTE C — Teste final: uma pergunta por módulo (não revelar antes do fim)

Pergunte só os módulos alcançados, uma pergunta por vez, e só as desta tabela. Diga se o aluno
acertou e, em uma linha, o que faltou, sem reensinar.

| módulo | pergunta | esperado |
|---|---|---|
| 1 | Chegam, em média, $0{,}5$ propostas por dia (Poisson). Qual a chance de um dia sem proposta? E a variância? | $e^{-0{,}5}\approx0{,}607$; variância $0{,}5$ |
| 2 | Num modelo de Poisson, a idade do imóvel tem $\beta=-0{,}1$ por ano. O que acontece com as visitas esperadas quando o imóvel é 10 anos mais velho? | multiplicam por $e^{-1}=0{,}368$, uma queda de 63% |
| 3 | `predict()` devolveu $2{,}3$ sem `type = "response"`. Quantas visitas o modelo prevê? | $e^{2{,}3}\approx9{,}97$, umas 10 visitas |
| 4 | Um anúncio ficará 15 dias no ar, e o modelo com *offset* dá $0{,}4$ visita por dia. Quantas visitas esperar? Qual é o *offset* desse anúncio? | 6 visitas; $\log15=2{,}71$ |
| 5 | $\hat\phi=4$. Um coeficiente vale $0{,}30$, com erro padrão $0{,}10$. Qual é o erro padrão corrigido? E o $\lvert z\rvert$? | $0{,}20$; $\lvert z\rvert$ cai de 3 para $1{,}5$ |
| 6 | Na validação cruzada, a média tem RMSE de $5{,}1$, o MQO de $3{,}9$ e o Poisson de $3{,}2$, e o MQO previu valores negativos para 12 anúncios. Qual modelo levar, e por quê? | o Poisson: menor erro fora da amostra, e nunca prevê contagem negativa |

Diga o resultado em uma linha: *"acertou os módulos …; … vão para revisão"*. Três erros ou
mais: revisar antes da Parte D.

---

## Glossário

| sigla | por extenso | o que é |
|---|---|---|
| MQO | mínimos quadrados ordinários | o ajuste do `lm()`: a reta que minimiza a soma dos quadrados dos resíduos |
| RMSE | raiz do erro quadrático médio | o erro típico de previsão, na unidade da resposta (aqui, visitas) |
| GLM | modelo linear generalizado | a família do `glm()`: a linear, a logística e a Poisson |
| AIC | critério de informação de Akaike | número do `summary()` de um `glm`; não serve para comparar famílias diferentes |
| — | razão de taxas | $e^{\beta_j}$ na Poisson; em inglês, *incidence rate ratio* (IRR) |

## Fechamento

Ordem fixa:

1. o teste final;
2. a oferta da Parte D: *"podemos aplicar isso ao banco do grupo? Reúna o grupo, com a ficha
   da pergunta da Entrega 1, e abra o arquivo da Parte D"*;
3. as perguntas guardadas;
4. o que vem;
5. o consolidado;
6. os passos de fechamento.

O que vem: *"na Parte D, o grupo procura uma contagem no próprio banco (ou cria uma, contando
eventos por município, por mês ou por hora) e faz o mesmo placar da validação cruzada."*

## Modelo do consolidado

Entregue em bloco de código Markdown, para o aluno copiar. Meia página é o normal. Sem código,
sem reexplicar a matéria, matemática em LaTeX, opinião em primeira pessoa, nada que o aluno
não possa ler em voz alta para a turma.

```markdown
# Consolidado — Teoria do Aprendizado Estatístico — Aula 05b (Poisson) — <data>
*guia versão 1 · tutora: <qual LLM> · sessão <única | 1 de 2>*
**Aluno:** <nome>

## 1. O que foi passado
- M1 — contagens e a Poisson
- M2 — o log da média como reta; $e^{\beta}$ como razão de taxas
- M3 — glm(family = poisson) e predict(type = "response")
- M4 — o offset
- M5 — sobredispersão e quase-Poisson
- M6 — Poisson contra MQO na validação cruzada
<se parou: "parou no M<k>; retomar do M<k+1>">

## 2. Como foi o aprendizado — opinião da tutora
<um parágrafo em primeira pessoa: o que veio fácil, onde travou e por quê, o que foi
construído e o que foi entregue pronto, como reagiu aos erros previstos>

**Teste final:** acertou M<lista>; a revisar M<lista> — <o que faltou em cada um>.

## 3. Observações para a frente
- **Revisar antes da Parte D:** <o quê, e por quê>
- **Para a próxima tutora:** <ritmo, perfil, o que funcionou>
- **Perguntas guardadas:** <pergunta> — <para quando>
- **Produzido nesta sessão:** <as previsões e o placar: 3,99 / 2,39 / 1,76, se chegou lá>
- **Parte D:** <combinada para quando / não combinada>
```

## Passos de fechamento (a tutora copia logo abaixo do consolidado)

1. Copie o bloco acima e salve como `aula05b_consolidado.md`.
2. Envie ao repositório do grupo, em `consolidados/<seu nome>/aula05b_consolidado.md`.
3. Se usou o Colab, baixe o notebook antes de fechar a sessão: depois, ele some.
4. Na Parte D, alguém do grupo cola este consolidado junto com o guia da Parte D.

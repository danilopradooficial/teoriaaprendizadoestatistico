# -*- coding: utf-8 -*-
"""Gera a apresentacao final do projeto Team Shannon (TAE).
Na raiz: python entregas/apresentacao-final/gerar-apresentacao.py
"""
from __future__ import annotations

from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "apresentacao-final-shannon.pptx"
GRAF = ROOT / "consolidados-aulas" / "graficos"

# Paleta moderna (porto, sem roxo)
NAVY = RGBColor(0x0A, 0x2E, 0x42)
AZUL = RGBColor(0x1B, 0x6B, 0x93)
TEAL = RGBColor(0x1A, 0x8A, 0x7A)
LARANJA = RGBColor(0xE0, 0x6D, 0x3A)
AREIA = RGBColor(0xF7, 0xF3, 0xEE)
BRANCO = RGBColor(0xFF, 0xFF, 0xFF)
CINZA = RGBColor(0x3D, 0x4A, 0x54)
NEVOA = RGBColor(0xD9, 0xE4, 0xEC)
SOFT = RGBColor(0xEE, 0xF4, 0xF7)

W, H = Inches(13.333), Inches(7.5)
TOTAL = 28
FONT = "Calibri"


def run(p, text, size=18, bold=False, color=CINZA, align=None):
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.color.rgb = color
    r.font.name = FONT
    if align is not None:
        p.alignment = align
    return r


def rect(slide, l, t, w, h, fill, line=None):
    s = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, l, t, w, h)
    s.fill.solid()
    s.fill.fore_color.rgb = fill
    if line is None:
        s.line.fill.background()
    else:
        s.line.color.rgb = line
    return s


def round_rect(slide, l, t, w, h, fill, line=None):
    s = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, l, t, w, h)
    s.fill.solid()
    s.fill.fore_color.rgb = fill
    if line is None:
        s.line.fill.background()
    else:
        s.line.color.rgb = line
    return s


def txt(slide, l, t, w, h, lines, size=18, bold=False, color=CINZA, align=PP_ALIGN.LEFT, after=8):
    box = slide.shapes.add_textbox(l, t, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(after)
        if align is not None:
            p.alignment = align
        run(p, line, size=size, bold=bold, color=color)
    return box


def headline(slide, title, subtitle=None):
    rect(slide, 0, 0, W, Inches(0.08), TEAL)
    txt(slide, Inches(0.6), Inches(0.28), Inches(12), Inches(0.55), [title], size=28, bold=True, color=NAVY, after=0)
    rect(slide, Inches(0.6), Inches(0.88), Inches(0.7), Inches(0.07), LARANJA)
    if subtitle:
        txt(slide, Inches(0.6), Inches(1.05), Inches(12), Inches(0.4), [subtitle], size=14, color=AZUL, after=0)


def footer(slide, n):
    rect(slide, 0, H - Inches(0.42), W, Inches(0.42), NAVY)
    box = slide.shapes.add_textbox(Inches(0.5), H - Inches(0.38), Inches(10), Inches(0.32))
    p = box.text_frame.paragraphs[0]
    run(p, f"Team Shannon   ·   Teoria do Aprendizado Estatístico   ·   {n}/{TOTAL}", size=11, color=BRANCO)
    box2 = slide.shapes.add_textbox(Inches(11.2), H - Inches(0.38), Inches(1.7), Inches(0.32))
    p2 = box2.text_frame.paragraphs[0]
    p2.alignment = PP_ALIGN.RIGHT
    run(p2, "Fatec RL", size=11, color=NEVOA, align=PP_ALIGN.RIGHT)


def bg(slide, color=AREIA):
    rect(slide, 0, 0, W, H, color)


def blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def card(slide, l, t, w, h, label, value, tip=""):
    round_rect(slide, l, t, w, h, BRANCO)
    rect(slide, l, t, Inches(0.12), h, TEAL)
    txt(slide, l + Inches(0.3), t + Inches(0.2), w - Inches(0.45), Inches(0.35), [label], size=13, color=AZUL, after=0)
    txt(slide, l + Inches(0.3), t + Inches(0.55), w - Inches(0.45), Inches(0.7), [value], size=26, bold=True, color=NAVY, after=0)
    if tip:
        txt(slide, l + Inches(0.3), t + Inches(1.2), w - Inches(0.45), Inches(0.7), [tip], size=13, color=CINZA, after=0)


def takeaway(slide, text, top=Inches(5.95)):
    round_rect(slide, Inches(0.5), top, Inches(12.3), Inches(0.8), SOFT)
    txt(
        slide,
        Inches(0.75),
        top + Inches(0.18),
        Inches(11.8),
        Inches(0.5),
        [f"Em uma frase: {text}"],
        size=15,
        bold=True,
        color=NAVY,
        after=0,
    )


def pic(slide, path: Path, l, t, w=None, h=None):
    if path.exists():
        return slide.shapes.add_picture(str(path), l, t, width=w, height=h)
    return None


def duo_pics(slide, path_a: Path, path_b: Path, top=Inches(1.4), h=Inches(4.2)):
    """Dois gráficos lado a lado."""
    pic(slide, path_a, Inches(0.45), top, w=Inches(6.1), h=h)
    pic(slide, path_b, Inches(6.75), top, w=Inches(6.1), h=h)


def story_bullets(slide, items, l=Inches(0.6), t=Inches(1.5), w=Inches(12), size=18, step=0.68):
    y = t
    for item in items:
        round_rect(slide, l, y, Inches(0.16), Inches(0.16), LARANJA)
        txt(slide, l + Inches(0.35), y - Inches(0.08), w - Inches(0.4), Inches(0.65), [item], size=size, color=CINZA, after=0)
        y += Inches(step)
    return y


def foco_badge(slide, label="FOCO"):
    round_rect(slide, Inches(10.4), Inches(0.25), Inches(2.4), Inches(0.45), LARANJA)
    txt(slide, Inches(10.45), Inches(0.32), Inches(2.3), Inches(0.35), [label], size=14, bold=True, color=BRANCO, align=PP_ALIGN.CENTER, after=0)


def build():
    prs = Presentation()
    prs.slide_width = W
    prs.slide_height = H

    # ========== 1 CAPA ==========
    s = blank(prs)
    bg(s, NAVY)
    rect(s, Inches(8.8), 0, Inches(4.6), H, AZUL)
    rect(s, 0, Inches(6.6), W, Inches(0.9), TEAL)
    txt(s, Inches(0.7), Inches(1.6), Inches(7.5), Inches(0.4), ["TEAM SHANNON"], size=14, bold=True, color=LARANJA, after=0)
    txt(
        s,
        Inches(0.7),
        Inches(2.1),
        Inches(7.8),
        Inches(2.2),
        ["Quanto tempo um navio\nfica operando no berço?"],
        size=36,
        bold=True,
        color=BRANCO,
        after=6,
    )
    txt(
        s,
        Inches(0.7),
        Inches(4.6),
        Inches(7.5),
        Inches(1.2),
        [
            "Da escolha dos dados ao modelo final:",
            "uma jornada com o Porto de Santos (ANTAQ)",
        ],
        size=16,
        color=NEVOA,
        after=4,
    )
    txt(
        s,
        Inches(9.2),
        Inches(2.4),
        Inches(3.8),
        Inches(3),
        [
            "Apresentação final",
            "",
            "Teoria do Aprendizado",
            "Estatístico",
            "",
            "Prof. Dr. João Paulo",
            "Ferreira de Mello",
            "",
            "Fatec Rubens Lara",
        ],
        size=15,
        color=BRANCO,
        after=2,
    )
    txt(s, Inches(0.7), Inches(6.8), Inches(12), Inches(0.4), ["Ciência de Dados  ·  2026"], size=14, bold=True, color=BRANCO, after=0)

    # ========== 2 EQUIPE ==========
    s = blank(prs)
    bg(s)
    headline(s, "Quem somos", "Três pessoas, um porto e muitos modelos")
    nomes = [
        ("Adriane", "da Costa Santos", "0051352511040"),
        ("Danilo", "Prado de Lima Silva", "0051352521019"),
        ("Victória", "Cabral Quintério", "0051352521033"),
    ]
    for i, (a, b, ra) in enumerate(nomes):
        x = Inches(0.6) + i * Inches(4.15)
        round_rect(s, x, Inches(1.7), Inches(3.9), Inches(3.6), BRANCO)
        rect(s, x, Inches(1.7), Inches(3.9), Inches(0.9), NAVY)
        txt(s, x + Inches(0.25), Inches(1.9), Inches(3.4), Inches(0.6), [a], size=22, bold=True, color=BRANCO, after=0)
        txt(s, x + Inches(0.25), Inches(2.9), Inches(3.4), Inches(1.2), [b], size=16, color=CINZA, after=4)
        txt(s, x + Inches(0.25), Inches(4.3), Inches(3.4), Inches(0.6), [f"RA {ra}"], size=14, bold=True, color=TEAL, after=0)
    footer(s, 2)

    # ========== 3 AGENDA ==========
    s = blank(prs)
    bg(s)
    headline(s, "O que vamos contar hoje", "Seis atos: do problema no cais até a decisão do modelo")
    passos = [
        ("01", "O problema", "Por que prever o tempo no berço"),
        ("02", "A base", "Por que ANTAQ e por que Santos"),
        ("03", "O dicionário", "T1 a T4 e o que pode entrar no modelo"),
        ("04", "A exploração", "EDA ampla e segmentada — com gráficos"),
        ("05", "Os modelos", "Do lm às splines (3 slides) e à floresta"),
        ("06", "A decisão", "Placar, entregas e o que aprendemos"),
    ]
    for i, (num, tit, desc) in enumerate(passos):
        y = Inches(1.35) + i * Inches(0.78)
        round_rect(s, Inches(0.6), y, Inches(12.1), Inches(0.7), BRANCO)
        round_rect(s, Inches(0.75), y + Inches(0.12), Inches(0.85), Inches(0.46), TEAL if i in (3, 4) else NAVY)
        tb = s.shapes.add_textbox(Inches(0.75), y + Inches(0.18), Inches(0.85), Inches(0.4))
        p = tb.text_frame.paragraphs[0]
        p.alignment = PP_ALIGN.CENTER
        run(p, num, size=13, bold=True, color=BRANCO)
        txt(s, Inches(1.85), y + Inches(0.1), Inches(4), Inches(0.3), [tit], size=17, bold=True, color=NAVY, after=0)
        txt(s, Inches(1.85), y + Inches(0.38), Inches(10), Inches(0.3), [desc], size=13, color=CINZA, after=0)
    footer(s, 3)

    # ========== 4 PROBLEMA ==========
    s = blank(prs)
    bg(s)
    headline(s, "O porto precisa de previsão", "Cada hora de berço custa fila, atraso e dinheiro")
    story_bullets(
        s,
        [
            "Usamos dados oficiais da ANTAQ: atracações, tempos e carga.",
            "O banco é público, granular e enorme (~4,6 GB no dump local).",
            "A pergunta prática: quanto tempo o navio vai ocupar o cais?",
            "Sem essa estimativa, a programação do berço fica no escuro.",
        ],
        t=Inches(1.5),
        size=17,
    )
    takeaway(s, "Queremos ajudar a decidir o berço com dados — não só com experiência.")
    footer(s, 4)

    # ========== 5 POR QUE SANTOS ==========
    s = blank(prs)
    bg(s)
    headline(s, "Por que Santos?", "Maior porto da América Latina — e o nosso quintal")
    left = [
        "É o complexo da região da Fatec: o problema é local e real.",
        "Misturar o Brasil inteiro mistura regimes diferentes (não i.i.d.).",
        "Em 2024, T3 mediano em Santos ~30 h; no restante do Sudeste ~23 h.",
        "Longo curso e exportação em toneladas: perfil próprio, não “média Brasil”.",
    ]
    story_bullets(s, left, l=Inches(0.55), t=Inches(1.4), w=Inches(6.5), size=15, step=0.72)
    pic(s, GRAF / "02a" / "10-santos-vs-sudeste-t3.png", Inches(7.3), Inches(1.35), w=Inches(5.5))
    takeaway(s, "Santos não é um ponto no mapa: é um regime de operação.")
    footer(s, 5)

    # ========== 6 PERGUNTA ==========
    s = blank(prs)
    bg(s)
    headline(s, "A pergunta do projeto", "Uma frase que guiou todas as atividades")
    round_rect(s, Inches(0.6), Inches(1.55), Inches(12.1), Inches(2.3), NAVY)
    txt(
        s,
        Inches(1.0),
        Inches(2.05),
        Inches(11.3),
        Inches(1.5),
        [
            "Quando um navio é programado para atracar em Santos,",
            "quantas horas ele vai operar no berço?",
        ],
        size=24,
        bold=True,
        color=BRANCO,
        align=PP_ALIGN.CENTER,
        after=8,
    )
    story_bullets(
        s,
        [
            "Isso é previsão de número (regressão), não só “sim ou não”.",
            "A resposta se chama T3 — tempo de operação no cais.",
            "Trabalhamos em log(1 + T3) para lidar melhor com a cauda longa.",
        ],
        t=Inches(4.15),
        size=15,
        step=0.55,
    )
    footer(s, 6)

    # ========== 7 DICIONARIO T1-T4 ==========
    s = blank(prs)
    bg(s)
    headline(s, "O cronômetro do navio", "T1 → T2 → T3 → T4: o dicionário em uma figura")
    left = [
        "T1 — espera para atracar (fila / fundeio).",
        "T2 — já atracado, ainda sem operar.",
        "T3 — operação de carga/descarga ← nosso Y.",
        "T4 — fim da operação até sair do cais.",
        "TA = tempo no berço; TE = estadia completa.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.4), size=14, step=0.62)
    pic(s, GRAF / "02b" / "04-medianas-tempos.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Em Santos, T1 e T3 são os vilões; T2 e T4 são só transição.")
    footer(s, 7)

    # ========== 8 O QUE ENTRA ==========
    s = blank(prs)
    bg(s)
    headline(s, "O que entra e o que fica fora", "Só o que já se sabe quando o navio é programado")
    card(s, Inches(0.5), Inches(1.4), Inches(4.0), Inches(2.0), "Escalas usadas", "5.681", "Santos 2024, carga, peso > 0, T3 ≤ P99")
    card(s, Inches(4.7), Inches(1.4), Inches(4.0), Inches(2.0), "Entra (X)", "peso, TEU, partidas", "+ natureza, navegação, terminal, mês")
    card(s, Inches(8.9), Inches(1.4), Inches(3.9), Inches(2.0), "Fica fora", "fila e estadia", "T1–T4, TA, TE, dur.datas = cola")
    story_bullets(
        s,
        [
            "Se usarmos tempos que só existem depois da operação, o modelo trapaceia.",
            "A unidade de análise é a escala: uma atracação com sua carga e seus tempos.",
        ],
        t=Inches(3.7),
        size=15,
        step=0.6,
    )
    takeaway(s, "Regra de ouro: preditor = o que o programador já conhece antes da atracação.")
    footer(s, 8)

    # ========== 9 EDA AMPLA BRASIL ==========
    s = blank(prs)
    bg(s)
    headline(s, "Brasil não é um porto só", "EDA ampla: assimetria e regimes diferentes")
    left = [
        "T3 nacional é bem assimétrico: média ≫ mediana.",
        "Interior e Norte dominam contagem; tonelagem é outro jogo.",
        "Regiões têm tempos distintos — misturar tudo vicia o modelo.",
        "Por isso o funil “Brasil → Santos” veio antes de qualquer fórmula.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.7)
    pic(s, GRAF / "02a" / "02-t3-boxplot-regiao.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Primeiro entendemos o mapa; depois focamos em um complexo.")
    footer(s, 9)

    # ========== 10 PERFIL SANTOS ==========
    s = blank(prs)
    bg(s)
    headline(s, "Perfil de Santos", "Longo curso e porto exportador em toneladas")
    duo_pics(
        s,
        GRAF / "02a" / "04-santos-navegacao.png",
        GRAF / "02a" / "08-santos-sentido-peso.png",
        top=Inches(1.3),
        h=Inches(4.3),
    )
    takeaway(s, "O mix comercial explica por que o T3 de Santos não parece o do Sudeste.")
    footer(s, 10)

    # ========== 11 BERCOS E SAZONALIDADE ==========
    s = blank(prs)
    bg(s)
    headline(s, "Berços e sazonalidade", "Concentração espacial e ritmo ao longo do ano")
    duo_pics(
        s,
        GRAF / "02a" / "06-santos-top-bercos.png",
        GRAF / "02a" / "03-santos-escalas-mes.png",
        top=Inches(1.3),
        h=Inches(4.3),
    )
    takeaway(s, "Poucos berços concentram escalas; o mês entra como fator, não como “ruído”.")
    footer(s, 11)

    # ========== 12 QUATRO TEMPOS ==========
    s = blank(prs)
    bg(s)
    headline(s, "Quem atrasa o navio?", "EDA segmentada: os quatro tempos lado a lado")
    left = [
        "Medianas em Santos (carga 2024): T1 ~28 h, T3 ~30 h.",
        "T2 e T4 são curtos: transição, não o miolo do atraso.",
        "T1 e T3 têm cauda longa — outliers não são “erro de digitação”.",
        "T2 tem ~12% de NA: não imputamos com média global.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.68)
    pic(s, GRAF / "02b" / "03-quatro-tempos-boxplot.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Fila e operação são histórias distintas — e as duas são longas em Santos.")
    footer(s, 12)

    # ========== 13 NAVEGACAO E FILA ==========
    s = blank(prs)
    bg(s)
    headline(s, "Navegação e fila ao longo do ano", "Segmentar revela o que a média esconde")
    duo_pics(
        s,
        GRAF / "02b" / "02-t3-por-navegacao.png",
        GRAF / "02a" / "11-santos-fila-mes.png",
        top=Inches(1.3),
        h=Inches(4.3),
    )
    takeaway(s, "T3 muda com o tipo de navegação; a fila (T1) oscila mês a mês.")
    footer(s, 13)

    # ========== 14 CARGA E T3 ==========
    s = blank(prs)
    bg(s)
    headline(s, "Carga e tempo de operação", "A física que o modelo precisa respeitar")
    left = [
        "Mais peso e mais TEU tendem a mais T3 — faz sentido físico.",
        "A relação aparece melhor em escala log (cauda longa).",
        "Fila (esperar) ≠ operação (trabalhar no cais).",
        "Sem essa leitura, qualquer modelo vira caixa-preta.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.7)
    pic(s, GRAF / "02a" / "09-santos-peso-vs-t3.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Agora sim: entendemos os dados. Hora de modelar com honestidade.")
    footer(s, 14)

    # ========== 15 FUNIL ==========
    s = blank(prs)
    bg(s)
    headline(s, "O caminho que percorremos", "Cada etapa ensinou uma peça — a próxima corrige a anterior")
    etapas = [
        ("Explorar", "entender\nos dados"),
        ("Explicar", "reta e\nprobabilidade"),
        ("Avaliar", "teste, CV\ne freios"),
        ("Suavizar", "vizinhança\ne splines"),
        ("Decidir", "árvores,\nRF e grupos"),
    ]
    for i, (tit, desc) in enumerate(etapas):
        x = Inches(0.5) + i * Inches(2.55)
        round_rect(s, x, Inches(1.7), Inches(2.35), Inches(3.1), BRANCO)
        round_rect(s, x, Inches(1.7), Inches(2.35), Inches(0.7), TEAL if i == 3 else NAVY)
        txt(s, x + Inches(0.1), Inches(1.85), Inches(2.15), Inches(0.45), [tit], size=16, bold=True, color=BRANCO, align=PP_ALIGN.CENTER, after=0)
        txt(s, x + Inches(0.15), Inches(2.8), Inches(2.05), Inches(1.5), [desc], size=16, color=CINZA, align=PP_ALIGN.CENTER, after=4)
        if i < 4:
            txt(s, x + Inches(2.15), Inches(3.0), Inches(0.4), Inches(0.4), ["→"], size=22, bold=True, color=AZUL, after=0)
    takeaway(s, "Não saltamos para o modelo mais complexo: cada aula respondeu uma dúvida.")
    footer(s, 15)

    # ========== 16 BASELINE ==========
    s = blank(prs)
    bg(s)
    headline(s, "Começamos simples", "Uma reta já ajuda — e ensina o tamanho do problema")
    left = [
        "Com peso e TEU, a reta já explica boa parte do T3.",
        "Também olhamos a chance de o tempo ser “longo”.",
        "Linha de comparação: se o novo modelo não ganha da reta, não serve.",
        "Entrega 1: lm ~24 h de erro; a média sozinha fazia ~33 h.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.7)
    pic(s, GRAF / "03a" / "01-reta-simples.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Simples não é fraco: é o chão de honestidade do projeto.")
    footer(s, 16)

    # ========== 17 AVALIAR ==========
    s = blank(prs)
    bg(s)
    headline(s, "Como sabemos se o modelo é bom?", "Treinar bem não basta — precisa acertar o que ainda não viu")
    left = [
        "Hold-out e validação cruzada em 5 pedaços.",
        "Polinômio flexível demais: acerta o treino, erra o futuro (curva em U).",
        "Ridge e Lasso freiam a “decoreba”.",
        "Botão do modelo = validação, não ego.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.7)
    pic(s, GRAF / "05" / "05-curva-u-grau.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Número bonito no treino pode ser ilusão; a validação corta a conversa.")
    footer(s, 17)

    # ========== 18 KNN ==========
    s = blank(prs)
    bg(s)
    headline(s, "E se a relação não for uma reta?", "Vizinhança ajuda — e mostra o limite dela")
    left = [
        "KNN e kernel olham navios de peso parecido.",
        "Nas pontas (muito leve / muito pesado) a curva falha.",
        "Com muitos preditores, “vizinho próximo” some.",
        "Precisávamos de pedaços bem emendados: splines.",
    ]
    story_bullets(s, left, l=Inches(0.5), t=Inches(1.35), w=Inches(6.3), size=14, step=0.7)
    pic(s, GRAF / "08" / "05-knn-x-kernel-x-reta.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "A suavização apontou o próximo capítulo: splines e GAM.")
    footer(s, 18)

    # ========== 19 SPLINES 1/3 ==========
    s = blank(prs)
    bg(s)
    headline(s, "Splines — ideia em português", "Slide 1 de 3 · Por que não um polinômio único?")
    foco_badge(s)
    story_bullets(
        s,
        [
            "Polinômio alto tenta explicar tudo de uma vez — e oscila nas pontas.",
            "Spline = cortar o eixo em pedaços e encaixar curvas suaves.",
            "Os pedaços se encontram sem “quebra”.",
            "O botão de flexibilidade é o df: quanto maior, mais curva.",
        ],
        l=Inches(0.5),
        t=Inches(1.35),
        w=Inches(6.3),
        size=14,
        step=0.68,
    )
    pic(s, GRAF / "09" / "01-polinomio-vs-natural.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Pense em uma régua flexível: curva onde precisa, sem delirar nas beiradas.")
    footer(s, 19)

    # ========== 20 SPLINES 2/3 ==========
    s = blank(prs)
    bg(s)
    headline(s, "Do pedaço à soma de curvas", "Slide 2 de 3 · Suavização e o modelo aditivo (GAM)")
    foco_badge(s)
    story_bullets(
        s,
        [
            "Dá para frear a curva com um “pedágio” de curvatura.",
            "O GAM soma uma curva suave por preditor: peso + TEU + partidas…",
            "edf perto de 1 ≈ quase reta; maior = mais flexível.",
            "No porto: peso curva pouco; TEU e partidas curvam bem mais.",
        ],
        l=Inches(0.5),
        t=Inches(1.35),
        w=Inches(6.3),
        size=14,
        step=0.68,
    )
    pic(s, GRAF / "09" / "05-gam-curvas-parciais.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "O GAM conta: “o efeito do TEU não é uma reta única”.")
    footer(s, 20)

    # ========== 21 SPLINES 3/3 ==========
    s = blank(prs)
    bg(s)
    headline(s, "Como usamos splines em Santos", "Slide 3 de 3 · Números do nosso banco")
    foco_badge(s)
    card(s, Inches(0.5), Inches(1.35), Inches(4.0), Inches(1.85), "Antes (reta)", "0,30", "erro médio na escala log")
    card(s, Inches(4.7), Inches(1.35), Inches(4.0), Inches(1.85), "Com GAM", "0,27", "melhor até essa etapa")
    card(s, Inches(8.9), Inches(1.35), Inches(3.9), Inches(1.85), "Em horas", "~25,5 h", "versus ~34,5 h da média")
    story_bullets(
        s,
        [
            "Mesmo recorte da Entrega 1 — dados do porto, não da aula.",
            "O ganho veio de deixar TEU e partidas terem forma própria.",
            "Limite: o GAM soma efeitos; interações fortes ficam para a árvore.",
        ],
        t=Inches(3.5),
        size=14,
        step=0.55,
    )
    takeaway(s, "Splines melhoraram a reta; a interação ficou para a floresta.")
    footer(s, 21)

    # ========== 22 RF ==========
    s = blank(prs)
    bg(s)
    headline(s, "E se as perguntas dependerem umas das outras?", "Árvore e floresta: o salto que fechou o placar")
    story_bullets(
        s,
        [
            "A árvore pergunta “TEU pequeno?” e depois outra pergunta no ramo.",
            "Isso captura interação sem desenhar a fórmula à mão.",
            "A floresta junta muitas árvores e valida com erro OOB.",
            "No placar: floresta ~0,18 (escala log) — a melhor.",
        ],
        l=Inches(0.5),
        t=Inches(1.35),
        w=Inches(6.3),
        size=14,
        step=0.68,
    )
    pic(s, GRAF / "10" / "04-importancia-rf.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "É o modelo da Entrega 2 — o artigo final do grupo.")
    footer(s, 22)

    # ========== 23 PCA ==========
    s = blank(prs)
    bg(s)
    headline(s, "Olhando sem a resposta", "Grupos e eixos que resumem o perfil da escala")
    story_bullets(
        s,
        [
            "Sem usar T3, procuramos padrões só nos preditores.",
            "Três perfis: pouco TEU, intermediário e muito TEU.",
            "Dois eixos bastam para quase toda a variação.",
            "Os tempos médios mudam entre grupos — o perfil conta a história.",
        ],
        l=Inches(0.5),
        t=Inches(1.35),
        w=Inches(6.3),
        size=14,
        step=0.68,
    )
    pic(s, GRAF / "11" / "03-pc1-pc2-grupos.png", Inches(7.1), Inches(1.3), w=Inches(5.7))
    takeaway(s, "Exploração não substitui previsão — mas explica quem é quem no porto.")
    footer(s, 23)

    # ========== 24 PLACAR ==========
    s = blank(prs)
    bg(s)
    headline(s, "Quem ganhou o placar?", "Do “chutar a média” até a floresta")
    rows = [
        ("Chutar a média", "0,62", 0.15),
        ("Reta (MQO)", "0,30", 0.40),
        ("GAM (splines)", "0,27", 0.48),
        ("Árvore", "0,23", 0.58),
        ("Floresta", "0,18", 0.72),
    ]
    for i, (lab, val, frac) in enumerate(rows):
        y = Inches(1.35) + i * Inches(0.8)
        txt(s, Inches(0.6), y + Inches(0.15), Inches(3.2), Inches(0.5), [lab], size=16, bold=True, color=NAVY, after=0)
        max_w = Inches(7.5)
        bw = int(max_w * frac)
        round_rect(s, Inches(3.9), y, bw, Inches(0.6), LARANJA if i == 4 else (TEAL if i == 2 else AZUL))
        txt(s, Inches(4.1), y + Inches(0.12), Inches(2), Inches(0.4), [val], size=17, bold=True, color=BRANCO, after=0)
    takeaway(s, "Cada passo melhorou um pouco; a floresta juntou o que reta e GAM não pegavam.")
    footer(s, 24)

    # ========== 25 ENTREGAS ==========
    s = blank(prs)
    bg(s)
    headline(s, "O que entregamos", "Duas peças oficiais + esta apresentação")
    round_rect(s, Inches(0.5), Inches(1.45), Inches(6.0), Inches(4.0), BRANCO)
    rect(s, Inches(0.5), Inches(1.45), Inches(6.0), Inches(0.85), NAVY)
    txt(s, Inches(0.75), Inches(1.65), Inches(5.5), Inches(0.5), ["Entrega 1 — A pergunta"], size=20, bold=True, color=BRANCO, after=0)
    txt(
        s,
        Inches(0.75),
        Inches(2.55),
        Inches(5.5),
        Inches(2.5),
        [
            "Definimos o problema e a ficha.",
            "Mostramos que a reta já batia a média:",
            "cerca de 24 h de erro contra 33 h.",
            "",
            "Foi o ponto de partida do funil.",
        ],
        size=16,
        color=CINZA,
        after=4,
    )
    round_rect(s, Inches(6.8), Inches(1.45), Inches(6.0), Inches(4.0), BRANCO)
    rect(s, Inches(6.8), Inches(1.45), Inches(6.0), Inches(0.85), TEAL)
    txt(s, Inches(7.05), Inches(1.65), Inches(5.5), Inches(0.5), ["Entrega 2 — Artigo final"], size=20, bold=True, color=BRANCO, after=0)
    txt(
        s,
        Inches(7.05),
        Inches(2.55),
        Inches(5.5),
        Inches(2.5),
        [
            "Escolhemos um único modelo:",
            "a floresta aleatória.",
            "",
            "Artigo em 3 páginas, com dados",
            "de Santos e relatório do ajuste.",
        ],
        size=16,
        color=CINZA,
        after=4,
    )
    footer(s, 25)

    # ========== 26 APRENDIZADOS ==========
    s = blank(prs)
    bg(s)
    headline(s, "O que levamos deste projeto", "Aprendizado estatístico com os pés no cais")
    story_bullets(
        s,
        [
            "Escolher a base e limpar o dicionário veio antes de qualquer fórmula.",
            "EDA ampla + segmentada mostrou que Santos tem regime próprio.",
            "Splines provaram que nem tudo é reta — TEU e partidas curvam.",
            "A floresta venceu porque combina contexto e interações.",
            "Próximo passo natural: modelos por perfil (pouco TEU vs muito TEU).",
        ],
        t=Inches(1.4),
        size=15,
        step=0.7,
    )
    footer(s, 26)

    # ========== 27 RECAP VISUAL ==========
    s = blank(prs)
    bg(s)
    headline(s, "A jornada em um olhar", "Do dado bruto à decisão")
    blocos = [
        ("Base", "ANTAQ → Santos\n5.681 escalas"),
        ("Dicionário", "T1–T4\nY = T3"),
        ("EDA", "ampla +\nsegmentada"),
        ("Modelos", "lm → GAM\n→ floresta"),
        ("Entrega", "RF no artigo\nfinal"),
    ]
    for i, (tit, desc) in enumerate(blocos):
        x = Inches(0.45) + i * Inches(2.55)
        round_rect(s, x, Inches(1.8), Inches(2.4), Inches(3.2), BRANCO)
        round_rect(s, x, Inches(1.8), Inches(2.4), Inches(0.75), LARANJA if i == 4 else (TEAL if i == 2 else NAVY))
        txt(s, x + Inches(0.1), Inches(1.95), Inches(2.2), Inches(0.5), [tit], size=16, bold=True, color=BRANCO, align=PP_ALIGN.CENTER, after=0)
        txt(s, x + Inches(0.15), Inches(2.9), Inches(2.1), Inches(1.6), [desc], size=15, color=CINZA, align=PP_ALIGN.CENTER, after=4)
        if i < 4:
            txt(s, x + Inches(2.2), Inches(3.1), Inches(0.35), Inches(0.4), ["→"], size=20, bold=True, color=AZUL, after=0)
    takeaway(s, "Storytelling primeiro; fórmula depois — e sempre com gráfico no meio.")
    footer(s, 27)

    # ========== 28 FIM ==========
    s = blank(prs)
    bg(s, NAVY)
    rect(s, 0, Inches(5.8), W, Inches(1.7), TEAL)
    txt(s, Inches(0.8), Inches(2.2), Inches(11.7), Inches(1), ["Obrigado"], size=54, bold=True, color=BRANCO, align=PP_ALIGN.CENTER, after=0)
    txt(
        s,
        Inches(0.8),
        Inches(3.4),
        Inches(11.7),
        Inches(1.2),
        ["Perguntas?  ·  teoriaaprendizadoestatistico"],
        size=20,
        color=NEVOA,
        align=PP_ALIGN.CENTER,
        after=0,
    )
    txt(
        s,
        Inches(0.8),
        Inches(6.2),
        Inches(11.7),
        Inches(0.8),
        ["Team Shannon  ·  Prof. Dr. João Paulo Ferreira de Mello  ·  Fatec Rubens Lara"],
        size=15,
        bold=True,
        color=BRANCO,
        align=PP_ALIGN.CENTER,
        after=0,
    )

    prs.save(OUT)
    print(f"OK -> {OUT}")
    print(f"slides = {len(prs.slides)}")


if __name__ == "__main__":
    build()

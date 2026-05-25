#!/usr/bin/env python3
"""Converte report/relatorio.md em um PDF formatado (capa + conteudo)."""
import pathlib
import markdown

HERE = pathlib.Path(__file__).resolve().parent
MD = HERE / "relatorio.md"
HTML = HERE / "relatorio.html"

ALUNO = "Pedro Turik Firmino"
DISCIPLINA = "Infraestrutura para Gestão de Dados"
MATRICULA = "22200699"

body = markdown.markdown(
    MD.read_text(encoding="utf-8"),
    extensions=["fenced_code", "tables", "sane_lists", "toc"],
)

CSS = """
@page { size: A4; margin: 18mm 16mm 18mm 16mm; }
* { box-sizing: border-box; }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body {
  font-family: "Segoe UI", "Helvetica Neue", Arial, sans-serif;
  font-size: 10.5pt; line-height: 1.5; color: #1a1a1a; margin: 0;
}
.cover {
  height: 245mm; display: flex; flex-direction: column;
  justify-content: center; text-align: center; page-break-after: always;
}
.cover .uni { font-size: 13pt; letter-spacing: .5px; color: #444; text-transform: uppercase; }
.cover h1 {
  font-size: 26pt; margin: 18mm 0 4mm; color: #0d3b66; border: 0;
}
.cover .sub { font-size: 14pt; color: #555; margin-bottom: 30mm; }
.cover .info {
  display: inline-block; text-align: left; font-size: 12pt;
  border-top: 2px solid #0d3b66; border-bottom: 2px solid #0d3b66;
  padding: 8mm 14mm; line-height: 2;
}
.cover .info b { color: #0d3b66; display: inline-block; min-width: 42mm; }
h1, h2, h3 { color: #0d3b66; page-break-after: avoid; line-height: 1.25; }
h1 { font-size: 18pt; border-bottom: 2px solid #0d3b66; padding-bottom: 3px; }
h2 { font-size: 14pt; margin-top: 9mm; border-bottom: 1px solid #cdd9e5; padding-bottom: 2px; }
h3 { font-size: 12pt; margin-top: 6mm; }
p, li { text-align: justify; }
a { color: #0d3b66; text-decoration: none; }
blockquote {
  border-left: 4px solid #f0a500; background: #fff8e6; margin: 4mm 0;
  padding: 2mm 5mm; color: #5a4500; font-size: 9.8pt;
}
code {
  font-family: "DejaVu Sans Mono", "Consolas", monospace; font-size: 9pt;
  background: #eef2f6; padding: 1px 4px; border-radius: 3px;
}
pre {
  background: #1e2a38; color: #e6edf3; padding: 4mm; border-radius: 5px;
  overflow-x: auto; page-break-inside: avoid; font-size: 8.6pt; line-height: 1.45;
}
pre code { background: transparent; color: inherit; padding: 0; font-size: inherit; }
table {
  border-collapse: collapse; width: 100%; margin: 4mm 0;
  font-size: 8.8pt; page-break-inside: avoid;
}
th, td { border: 1px solid #b8c4d0; padding: 4px 6px; text-align: left; vertical-align: top; }
th { background: #0d3b66; color: #fff; }
tr:nth-child(even) td { background: #f4f7fa; }
hr { border: 0; border-top: 1px solid #cdd9e5; margin: 7mm 0; }
strong { color: #0a2e52; }
"""

cover = f"""
<div class="cover">
  <div class="uni">Universidade — Trabalho 2</div>
  <h1>Controle de Concorrência em SQL</h1>
  <div class="sub">PostgreSQL 18 · Loja / Vendas</div>
  <div class="info">
    <div><b>Aluno:</b> {ALUNO}</div>
    <div><b>Matrícula:</b> {MATRICULA}</div>
    <div><b>Disciplina:</b> {DISCIPLINA}</div>
  </div>
</div>
"""

html = f"""<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>Relatório — {ALUNO}</title>
<style>{CSS}</style></head>
<body>{cover}{body}</body></html>"""

HTML.write_text(html, encoding="utf-8")
print(f"HTML escrito em {HTML}")

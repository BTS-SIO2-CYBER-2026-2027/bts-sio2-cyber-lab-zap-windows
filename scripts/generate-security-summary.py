#!/usr/bin/env python3
import json
import os
import glob
from collections import Counter
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS = os.path.join(ROOT, 'reports')
OUT = os.path.join(REPORTS, 'RESUME_SECURITE.md')

RISK_ORDER = ['High', 'Medium', 'Low', 'Informational']
RISK_ALIASES = {
    'high': 'High', 'medium': 'Medium', 'low': 'Low',
    'informational': 'Informational', 'info': 'Informational'
}

def latest(pattern):
    files = glob.glob(os.path.join(REPORTS, pattern))
    return max(files, key=os.path.getmtime) if files else None

def normalize_risk(value):
    text = str(value or '').strip()
    if not text:
        return 'Informational'
    base = text.split()[0].lower()
    return RISK_ALIASES.get(base, text.split()[0].title())

def extract_alerts(data):
    alerts = []
    # ZAP JSON report format: site[] -> alerts[]
    for site in data.get('site', []) if isinstance(data, dict) else []:
        if isinstance(site, dict):
            for alert in site.get('alerts', []) or []:
                if isinstance(alert, dict):
                    alerts.append(alert)
    # Tolerate alternate structures if a future image changes format.
    if not alerts and isinstance(data, dict):
        for key in ('alerts', 'issues'):
            value = data.get(key)
            if isinstance(value, list):
                alerts.extend(x for x in value if isinstance(x, dict))
    return alerts

def summarize(path):
    if not path:
        return None
    try:
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
    except Exception as exc:
        return {'path': path, 'error': str(exc), 'alerts': [], 'counts': Counter()}
    alerts = extract_alerts(data)
    counts = Counter()
    compact = []
    for a in alerts:
        risk = normalize_risk(a.get('riskdesc') or a.get('risk') or a.get('riskcode'))
        counts[risk] += 1
        compact.append({
            'name': a.get('name') or a.get('alert') or 'Alerte sans nom',
            'risk': risk,
            'desc': a.get('desc') or a.get('description') or '',
            'solution': a.get('solution') or '',
            'count': a.get('count') or len(a.get('instances', []) or []) or 1,
        })
    compact.sort(key=lambda x: (RISK_ORDER.index(x['risk']) if x['risk'] in RISK_ORDER else 99, x['name']))
    return {'path': path, 'alerts': compact, 'counts': counts}

def render_scan(title, summary):
    lines = [f'## {title}', '']
    if not summary:
        lines += ['Rapport JSON non disponible pour le moment.', '']
        return lines
    if summary.get('error'):
        lines += [f"Impossible de lire `{os.path.basename(summary['path'])}` : {summary['error']}", '']
        return lines
    lines += [f"Source : `{os.path.basename(summary['path'])}`", '']
    lines += ['| Niveau | Nombre d\'alertes |', '|---|---:|']
    for risk in RISK_ORDER:
        lines.append(f"| {risk} | {summary['counts'].get(risk, 0)} |")
    others = sum(v for k, v in summary['counts'].items() if k not in RISK_ORDER)
    if others:
        lines.append(f'| Autre | {others} |')
    lines.append('')
    if summary['alerts']:
        lines += ['### Alertes principales', '']
        for i, a in enumerate(summary['alerts'][:20], 1):
            lines.append(f"{i}. **[{a['risk']}] {a['name']}** — {a['count']} occurrence(s)")
        if len(summary['alerts']) > 20:
            lines += ['', f"_Seules les 20 premières alertes sont affichées ici. Consultez le rapport HTML complet pour les {len(summary['alerts'])} alertes._"]
        lines.append('')
    else:
        lines += ['Aucune alerte n\'a été extraite de ce rapport.', '']
    return lines

baseline = summarize(latest('zap-baseline-*.json'))
full = summarize(latest('zap-full-*.json'))

lines = [
    '# Résumé de sécurité — OWASP ZAP', '',
    f"Généré automatiquement le {datetime.now().strftime('%d/%m/%Y à %H:%M:%S')}.", '',
    '> Ce résumé facilite la lecture. Il ne remplace pas les rapports HTML complets de ZAP ni l’analyse du code source.', '',
    '## Ce que vous devez faire', '',
    '1. Comparez les résultats du **Baseline Scan** et du **Full Scan**.',
    '2. Ouvrez le rapport HTML correspondant à chaque alerte importante.',
    '3. Retrouvez dans le code la cause de la vulnérabilité ou de la faiblesse.',
    '4. Corrigez le code, puis laissez le laboratoire relancer automatiquement les scans.',
    '5. Vérifiez si l’alerte a disparu et expliquez pourquoi.', '',
]
lines += render_scan('ZAP Baseline Scan', baseline)
lines += render_scan('ZAP Full Scan', full)
lines += [
    '## Interprétation pédagogique', '',
    'Un résultat ZAP ne signifie pas automatiquement qu’une application est « sûre » ou « vulnérable » dans son ensemble. ',
    'ZAP automatise une partie des tests. Certaines failles logiques, erreurs de conception ou problèmes de contrôle d’accès nécessitent une analyse humaine.', '',
    '**Objectif du TP :** montrer qu’un bon prompt et une application qui fonctionne ne dispensent jamais de comprendre, tester et auditer le code généré par l’IA.', ''
]

os.makedirs(REPORTS, exist_ok=True)
with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    f.write('\n'.join(lines))
print(f'Résumé généré : {os.path.relpath(OUT, ROOT)}')

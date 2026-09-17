#!/bin/bash
# Script rápido para deploy
git add .
git commit -m "update $(date +%Y-%m-%d_%H:%M:%S)"
git push
echo "✅ Push feito! Aguarde ~5min para o build no GitHub Actions"
echo "📦 Acesse: https://github.com/SEU_USER/SEU_REPO/actions"

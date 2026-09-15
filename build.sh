#!/bin/bash

# =============================================================================
# build.sh — ThreeOneOSFive (3105) iOS App
# Uso igual ao do NeoCheats: basta rodar ~/main/build.sh
# =============================================================================

cd ~/main

echo "[*] Limpando build anterior..."
rm -rf .theos packages

echo "[*] Forçando timestamp em todos os arquivos fonte..."
find ThreeOneOSFive -name "*.swift" \
                    -o -name "*.m" \
                    -o -name "*.mm" \
                    -o -name "*.c" \
                    -o -name "*.h" | xargs touch

echo "[*] Verificando toolchain..."

# Detecta swiftc no toolchain do Theos
SWIFTC_PATH="$HOME/theos/toolchain/swift/bin/swiftc"
if [ ! -f "$SWIFTC_PATH" ]; then
    echo ""
    echo "ERRO: swiftc não encontrado em $SWIFTC_PATH"
    echo "O seu toolchain do Theos precisa incluir suporte a Swift."
    echo "Instale via: https://github.com/kabiroberai/swift-toolchain-linux"
    echo ""
    exit 1
fi

CLANG_PATH="$HOME/theos/toolchain/linux/iphone/bin/clang"
if [ ! -f "$CLANG_PATH" ]; then
    echo ""
    echo "ERRO: clang não encontrado em $CLANG_PATH"
    echo "Verifique sua instalação do Theos: https://theos.dev/docs/installation"
    echo ""
    exit 1
fi

echo "[*] Compilando..."
THEOS=$HOME/theos make package 2>&1

echo ""
echo "[*] IPA gerada:"
ls -lh packages/*.ipa 2>/dev/null || echo "ERRO: IPA não foi gerada — veja os logs acima"

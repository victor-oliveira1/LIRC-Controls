#!/bin/bash

# Define o ficheiro de entrada (padrão: lircd.conf ou o primeiro argumento passado)
LIRC_FILE="${1:-lircd.conf}"
OUTPUT_FILE="${1%.*}.xml"

if [ ! -f "$LIRC_FILE" ]; then
    echo "Erro: O ficheiro '$LIRC_FILE' não foi encontrado!"
    exit 1
fi

# Extrai o nome do dispositivo
MODEL_NAME=$(grep -E "^\s*name\s+" "$LIRC_FILE" | awk '{print $2}' | head -n 1)
MODEL_NAME="${MODEL_NAME:-Dispositivo_LIRC}"

# Cria o cabeçalho do XML
cat <<EOF > "$OUTPUT_FILE"
<irplus>
 <device manufacturer="LIRC" model="$MODEL_NAME" format="WINLIRC_NEC1">
EOF

# Extrai o bloco de códigos e processa linha a linha
sed -n '/begin codes/,/end codes/p' "$LIRC_FILE" | grep -E "0x[0-9a-fA-F]+" | while read -r line; do
    # Extrai o nome do botão e o primeiro código hexadecimal
    LABEL=$(echo "$line" | awk '{print $1}')
    HEX_CODE=$(echo "$line" | awk '{print $2}' | tr 'a-z' 'A-Z')

    # Ignora linhas inválidas
    if [ -z "$LABEL" ] || [ -z "$HEX_CODE" ]; then
        continue
    fi

    # Adiciona a tag do botão ao ficheiro XML
    echo "  <button label=\"$LABEL\">$HEX_CODE</button>" >> "$OUTPUT_FILE"
done

# Fecha a tag do XML
cat <<EOF >> "$OUTPUT_FILE"
 </device>
</irplus>
EOF

echo "✅ Sucesso! XML gerado em: '$OUTPUT_FILE'"
echo "📱 Conteúdo do ficheiro gerado:"
echo "--------------------------------------"
cat "$OUTPUT_FILE"

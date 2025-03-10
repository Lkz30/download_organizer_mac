#!/bin/bash


CONFIG_FILE="config.txt"

# Verificar si fswatch está instalado en macOS
if ! command -v fswatch &> /dev/null; then
    echo "fswatch no está instalado. Instalándolo ahora..."
    
    # Verificar si Homebrew está instalado
    if ! command -v brew &> /dev/null; then
        echo "Homebrew no está instalado. Instálalo manualmente desde https://brew.sh/"
        exit 1
    fi
    
    # Instalar fswatch con Homebrew
    brew install fswatch
else
    echo "fswatch ya está instalado."
fi

# Verificar si el archivo de configuración existe, si no, crearlo con formato correcto
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "El archivo de configuración no existe. Creándolo con formato de ejemplo..."
    cat <<EOL > "$CONFIG_FILE"
#  CONFIGURACIÓN DE REGLAS PARA ORGANIZADOR DE DESCARGAS
#  FORMATO PARA ASIGNAR ARCHIVOS A CARPETAS:
# extensión=carpeta_destino

pdf=~/Documents/freelance/descargas_pdf_diaLunes
jpg=~/Pictures/Carpeta_Imagenes
mp4=~/Videos/Carpeta_Videos

#  Si quieres cambiar rutas de carpetas, agrégalas aquí:
# antigua_ruta=nueva_ruta
~/Documents/freelance/descargas_pdf_diaLunes=~/Documents/proyectos/pdfs_ordenados
EOL
    echo "Archivo de configuración creado. Edita '$CONFIG_FILE' para personalizar las reglas."
    exit 0
fi

# Función para leer la configuración y mover archivos
mover_archivos() {
    local archivo="$1"
    local extension="${archivo##*.}"

    # Leer la carpeta destino desde el archivo de configuración, ignorando líneas comentadas
    carpeta_destino=$(grep -E "^[^#]*\b$extension\b" "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r')

    if [[ -n "$carpeta_destino" ]]; then
        # Expandir tilde (~) en rutas
        carpeta_destino=$(eval echo "$carpeta_destino")

        # Reemplazar rutas antiguas si están en la configuración
        while IFS="=" read -r antigua nueva; do
            if [[ "$carpeta_destino" == "$antigua" ]]; then
                carpeta_destino="$nueva"
            fi
        done < <(grep -v "^#" "$CONFIG_FILE" | awk -F= 'NF==2 && $1 ~ /^\//')

        mkdir -p "$carpeta_destino"
        mv "$archivo" "$carpeta_destino"
        echo "📂 Movido: $(basename "$archivo") → $carpeta_destino"
    fi
}

# Monitorear la carpeta Downloads y mover archivos en tiempo real
echo " Monitoreando ~/Downloads según las reglas de $CONFIG_FILE..."
nohup fswatch -0 ~/Downloads | while read -d "" archivo; do 
    mover_archivos "$archivo"
done &>/dev/null &




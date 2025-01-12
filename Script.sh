#!/bin/bash

# Script para analizar intentos de inicio de sesión sospechosos y bloquear IPs

LOG_FILE="/var/log/auth.log"  # Archivo de registros (ajusta según tu sistema, ej. /var/log/secure en CentOS)
THRESHOLD=5                   # Número de intentos fallidos antes de marcar como sospechosa
BLOCK_FILE="blocked_ips.txt"  # Archivo donde se guardan las IPs bloqueadas

echo "=== Analizando registros de intentos fallidos ==="

# Extraer direcciones IP con intentos fallidos y contar ocurrencias
suspicious_ips=$(grep "Failed password" "$LOG_FILE" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr)

echo -e "\nIPs con intentos fallidos:"
echo "$suspicious_ips"

# Filtrar IPs que exceden el umbral
echo -e "\nIPs sospechosas (>$THRESHOLD intentos):"
echo "$suspicious_ips" | awk -v threshold="$THRESHOLD" '$1 > threshold {print $2}' > suspicious_ips.txt

if [[ -s suspicious_ips.txt ]]; then
    cat suspicious_ips.txt
else
    echo "No se encontraron IPs sospechosas que excedan el umbral."
    exit 0
fi

# Opcional: Bloquear las IPs sospechosas con iptables
read -p "¿Desea bloquear estas IPs? (s/n): " response
if [[ "$response" == "s" ]]; then
    while read -r ip; do
        echo "Bloqueando IP: $ip"
        sudo iptables -A INPUT -s "$ip" -j DROP
        echo "$ip" >> "$BLOCK_FILE"
    done < suspicious_ips.txt
    echo "Todas las IPs sospechosas han sido bloqueadas."
else
    echo "No se bloquearon las IPs."
fi

# Mostrar las reglas actuales de iptables (opcional)
read -p "¿Desea ver las reglas actuales de iptables? (s/n): " show_rules
if [[ "$show_rules" == "s" ]]; then
    sudo iptables -L -n
fi

echo "Análisis y bloqueo completados."

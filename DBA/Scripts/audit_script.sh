#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
# Script de surveillance des modifications sur le fichier pg_hba.conf
# Envoie un email à l'adresse spécifiée en cas de modification détectée
cd /home/sysadm/scripts
# Configuration des variables
PG_HBA_CONF="/etc/postgresql/14/main/pg_hba.conf"
EMAIL="example@gmail.com"
SUBJECT="Alerte : Modification detectee dans pg_hba.conf"
BODY="Une modification a ete detectee dans le fichier $PG_HBA_CONF."
LOG_FILE="/var/log/pg_hba_monitor.log"  # Chemin vers le fichier de log
SENDER="sender.example@gmail.com"
# Vérification des permissions d'exécution
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : Ce script doit être exécuté en tant que root."
#    exit 1
fi

# Vérification de l'existence du fichier pg_hba.conf
if [[ ! -f "$PG_HBA_CONF" ]]; then
    echo "Erreur : Le fichier $PG_HBA_CONF n'existe pas. Vérifiez le chemin." | tee -a "$LOG_FILE"
    exit 1
fi

# Fonction pour envoyer un email
send_email() {
    local message=$1
    echo -e "From: $SENDER\nTo: $EMAIL\nSubject: $SUBJECT\n\n$BODY" | /usr/sbin/ssmtp $EMAIL
}

# Fonction de surveillance des modifications
monitor_modifications() {
    # Recherche des modifications récentes
    MODIFICATIONS=$(/usr/sbin/ausearch -k pg_hba_monitor -ts today )
    echo "**************************************************"
    echo $MODIFICATIONS
    echo "**********************************************"
    if [[ -n $MODIFICATIONS ]]; then
        # Envoie de la notification par email et log dans le fichier de log
        USER=$(echo "$MODIFICATIONS" | grep -oP 'uid=\K\d+' | xargs -I{} getent passwd {} | cut -d: -f1)
        BODY="$BODY\n Utilisateur responsable: $USER"
        echo -e "From: $SENDER\nTo: $EMAIL\nSubject: $SUBJECT\n\n$BODY" | /usr/sbin/ssmtp $EMAIL
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Notification envoyée à $EMAIL suite à une modification de $PG_HBA_CONF." | tee -a "$LOG_FILE"
        echo "$MODIFICATIONS" | tee -a "$LOG_FILE"

        # Réinitialise les règles d’audit pour éviter les notifications redondantes
        reset_audit_rules
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Aucune modification détectée." | tee -a "$LOG_FILE"
    fi
}

# Fonction pour réinitialiser les règles d’audit
reset_audit_rules() {
    auditctl -w "$PG_HBA_CONF" -p wa -k pg_hba_monitor
    if [[ $? -eq 0 ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Règles d'audit réinitialisées avec succès." | tee -a "$LOG_FILE"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Erreur lors de la réinitialisation des règles d'audit." | tee -a "$LOG_FILE"
    fi
}

# Exécute la surveillance des modifications
monitor_modifications



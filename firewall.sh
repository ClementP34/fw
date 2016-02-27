#!/bin/sh

### BEGIN INIT INFO
# Provides:          firewall-gq
# Required-Start:    $syslog $network
# Required-Stop:     $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: FireWall
# Description:       Lancer le FireWall au demarage
### END INIT INFO

# Initialisation des variables
#Ports
SSH="22"
FTP="21"
DNS="53"
SMTP="25"
NTP="123"
HTTP="80"
HTTPS="443"
WEBMIN="10000"

#Interfaces
ETH_LOCAL="eth1"
ETH_INTERNET="eth0"
ETH_DMZ=""

# Régles
 
fw_start(){
        # activer le forward
        echo 1 > /proc/sys/net/ipv4/ip_forward
        
        # ignore icmp Echo Request message
        echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
        echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
        
        # ignore icmp bogus responce message
        echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
        
        # interdire source routing
        echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
        
        # Surveiller martians (adresse source falsifier ou non routable)
        echo 1 >/proc/sys/net/ipv4/conf/all/log_martians
        
        # Se proteger de l ip spoofing
        echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
        
        #se proteger des attaques 'syn flood'
        echo 1 > /proc/sys/net/ipv4/tcp_syncookies
        
        # Vidage des tables et des regles personnelles
        iptables -t filter      -F
        iptables -t nat         -F
        iptables -t mangle      -F
        iptables -t filter      -X
        
        # Politique par defaut
        iptables -t filter      -P INPUT DROP
        iptables -t filter      -P FORWARD DROP
        iptables -t filter      -P OUTPUT DROP
        
        # Autoriser le ping
        iptables -t filter -A INPUT -p icmp -j ACCEPT
        iptables -t filter -A OUTPUT -p icmp -j ACCEPT
        
        # Activation du postrouting
        iptables -t nat -A POSTROUTING -o $ETH_INTERNET -j MASQUERADE
        
        # Loopback
        iptables -t filter -A INPUT -i lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
        iptables -t filter -A OUTPUT -o lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
        
        # INTERNE <--> EXTERNE (Forward)---------------------------------------------------------------
        iptables -A FORWARD -i $ETH_INTERNET -o $ETH_LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -m state --state ESTABLISHED,RELATED -j ACCEPT

        #Ping
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -p icmp -j ACCEPT
        #HTTP/HTTPS
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -p tcp --dport $HTTP -j ACCEPT
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -p tcp --dport $HTTPS -j ACCEPT
        #DNS
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -p tcp --dport $DNS -j ACCEPT
        iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -p udp --dport $DNS -j ACCEPT

        #iptables -A FORWARD -i $ETH_LOCAL -o $ETH_INTERNET -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT   
        
        # Firewall <--> reseau local----------------------------------------------------------------
        iptables -A INPUT  -i $ETH_LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A OUTPUT -o $ETH_LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT
        #iptables -A OUTPUT -o $ETH_LOCAL -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
        
        # Autoriser SSH
        iptables -t filter -A INPUT -i $ETH_LOCAL -p tcp --dport $SSH -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_LOCAL -p tcp --sport $SSH -j ACCEPT
        
        # Configuration Firewall <--> Web (EXTERNE)-------------------------------------------------
        iptables -A INPUT -i $ETH_INTERNET -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -o $ETH_INTERNET -m state --state RELATED,ESTABLISHED -j ACCEPT
        #iptables -A OUTPUT -i $ETH_INTERNET -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
 
        # Autoriser SSH
        iptables -t filter -A INPUT -i $ETH_INTERNET -p tcp --dport $SSH -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p tcp --dport $SSH -j ACCEPT
 
        # Autoriser DNS
#        iptables -t filter -A INPUT -i $ETH_INTERNET -p tcp --dport $DNS -j ACCEPT
#        iptables -t filter -A INPUT -i $ETH_INTERNET -p udp --dport $DNS -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p tcp --dport $DNS -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p udp --dport $DNS -j ACCEPT
        
        # Autoriser HTTP et HTTPS
#        iptables -t filter -A INPUT -i $ETH_INTERNET -p tcp --dport $HTTP -j ACCEPT
#        iptables -t filter -A INPUT -i $ETH_INTERNET -p tcp --dport $HTTPS -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p tcp --dport $HTTP -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p tcp --dport $HTTPS -j ACCEPT
}
 
fw_stop(){
        # Vidage des tables et des regles personnelles
        iptables -t filter      -F
        iptables -t nat         -F
        iptables -t mangle      -F
        iptables -t filter      -X
 
        # Autoriser toutes connexions entrantes et sortantes
        iptables -t filter      -P INPUT ACCEPT
        iptables -t filter      -P FORWARD ACCEPT
        iptables -t filter      -P OUTPUT ACCEPT
        
        echo 0 > /proc/sys/net/ipv4/ip_forward
        echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
        echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
        echo 0 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
        echo 1 > /proc/sys/net/ipv4/conf/all/accept_source_route
        echo 0 >/proc/sys/net/ipv4/conf/all/log_martians
        echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
        echo 0 > /proc/sys/net/ipv4/tcp_syncookies
}

fw_pause(){
        # Vidage des tables et des regles personnelles
        iptables -t filter      -F
        iptables -t nat         -F
        iptables -t mangle      -F
        iptables -t filter      -X
 
        # Interdire toutes connexions entrantes et sortantes
        iptables -t filter      -P INPUT STOP
        iptables -t filter      -P FORWARD STOP
        iptables -t filter      -P OUTPUT STOP
        
        echo 0 > /proc/sys/net/ipv4/ip_forward
        echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
        echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
        echo 0 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
        echo 1 > /proc/sys/net/ipv4/conf/all/accept_source_route
        echo 0 >/proc/sys/net/ipv4/conf/all/log_martians
        echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
        echo 0 > /proc/sys/net/ipv4/tcp_syncookies
        
        #Regle pour garder SSH
        iptables -A INPUT -i $ETH_INTERNET -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -o $ETH_INTERNET -m state --state RELATED,ESTABLISHED -j ACCEPT
        # Autoriser SSH
        iptables -t filter -A INPUT -i $ETH_INTERNET -p tcp --dport $SSH -j ACCEPT
        iptables -t filter -A OUTPUT -o $ETH_INTERNET -p tcp --dport $SSH -j ACCEPT
}
 
case "$1" in
        start|restart)
                echo -n "Firewall START"
                fw_start
                echo "Firewall [ON]"
                ;;
        stop)
                echo -n "Firewall STOP"
                fw_stop
                echo "Firewall [OFF]"
                ;;
        pause)
                echo -n "Firewall PAUSE"
                fw_pause
                echo "Firewall [PAUSE]"
                ;;                
        *)
                echo "Usage: $0 {start|stop|pause|restart}"
                exit 1
                ;;
esac
 
exit 0 

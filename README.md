# fw

Firewall iptables en chantier.

Il Fonctionne pas trop mal. Il y a surement des améliorations à avoir.
Le Port Forwarding est en cours.

Pour l'installer :
* Copier dans "/etc/init.d/firewall.sh"
* Faire "chmod +x /etc/init.d/firewall.sh"
* Faire "chown root:root /etc/init.d/firewall.sh"
* Puis "update-rc.d firewall.sh defaults"
 
Pour lancer : /etc/init.d/firewall.sh start

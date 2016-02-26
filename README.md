# fw

Firewall iptables en chantier.

Je ne l'ai pas encore testé, il y a surement des bugs.

Pour l'installer :
* Copier dans "/etc/init.d/firewall.sh"
* Faire "chmod +x /etc/init.d/firewall.sh"
* Faire "chown root:root /etc/init.d/firewall.sh"
* Puis "update-rc.d firewall.sh defaults"
 
Pour lancer : /etc/init.d/firewall.sh start

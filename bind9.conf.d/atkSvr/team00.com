;success Zone
$TTL    60
@       IN      SOA     team00.com. admin.team00.com. (
                              2         ; Serial
                             60         ; Refresh
                             60         ; Retry
                             60         ; Expire
                             60 )       ; Negative Cache TTL
;
@       IN      NS      ns.attacker32.com.
*       IN      A       10.0.10.14
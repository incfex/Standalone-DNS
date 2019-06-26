;.com Zone
$TTL    60
@       IN      SOA     a.gtld-seed.com. seed.com. (
                              2         ; Serial
                             60         ; Refresh
                             60         ; Retry
                             60         ; Expire
                             60 )       ; Negative Cache TTL
;
@       IN      NS      a.gtld-seed.com.
@       IN      A       10.0.10.11
com.    IN      NS      a.gtld-seed.com.
a.gtld-seed.com. IN      A       10.0.10.11
attacker32.com. IN      NS      ns.attacker.com.
ns.attacker.com.        IN      A       10.0.10.14
team0.com.     IN      NS      ns.team0.com.
ns.team0.com.  IN      A       10.0.10.12
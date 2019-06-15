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
team01.com.     IN      NS      ns.team01.com.
ns.team01.com.  IN      A       10.0.10.12

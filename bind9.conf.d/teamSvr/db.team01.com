;team Zone
$TTL    60
@       IN      SOA     ns.team01.com. admin.team01.com. (
                              2         ; Serial
                             60         ; Refresh
                             60         ; Retry
                             60         ; Expire
                             60 )       ; Negative Cache TTL
;
@       IN      NS      ns.team01.com.
*       IN      A       10.0.10.12
#!/bin/bash

#-------VARIABLES-------
RED='\033[31m' # Kırmızı
BLUE='\033[34m' # Mavi
YELLOW='\033[33m' # Sarı
GREEN='\033[32m' # Yeşil
NC='\033[0m' # Renksiz

#--------ANA MENU--------
header() {
	clear
	echo -e "$GREEN~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$NC"	
	echo -e "$NC->" "$YELLOW""Yunus Özçelik MailBaby Cpanel Auto İnstall <-$NC"
	echo -e "$GREEN~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
	}	
ana_menu() {
	echo -e "$YELLOW 1) -$NC English"
	echo -e "$YELLOW 2) -$NC Türkçe"
	echo -e "$YELLOW 3) -$NC Exit\n"
}
ana_siklar(){
	local choice
	read -p "[ 1 - 2] Choose between: " choice
	case $choice in
		1) en_menu ;;
		2) tr_menu ;;
		3) exit 0;;
		*) echo -e "${RED}Incorrect entry..." && sleep 2
	esac
}
#--------ANA MENU--------

#--------TR ANA MENU--------
tr_menu() {

tr_anamenu() {
	echo -e "$YELLOW 1) -$NC Kurulumu Başlat"
	echo -e "$YELLOW 2) -$NC Çıkış\n"
}

tr_siklar(){
	local choice
	read -p "[ 1 - 2] Arası seçim yapın : " choice
	case $choice in
		1) proccess_start_tr ;;
		2) exit 0;;
		*) echo -e "${RED}Hatalı Giriş..." && sleep 2
	esac
	}
	
	while true
	do
		header
		tr_anamenu
		tr_siklar
	done
}
#--------TR ANA MENU--------

#--------EN ANA MENU--------
en_menu() {

en_anamenu() {
	echo -e "$YELLOW 1) -$NC Install"
	echo -e "$YELLOW 2) -$NC Exit\n"
}

en_siklar(){
	local choice
	read -p "[ 1 - 2] Choose between: " choice
	case $choice in
		1) proccess_start_en ;;
		2) exit 0;;
		*) echo -e "${RED}Incorrect entry..." && sleep 2
	esac
	}
	
	while true
	do
		header
		en_anamenu
		en_siklar
	done
}
#--------EN ANA MENU--------

#--------EN ANA FONKSIYON--------
function proccess_start_en(){
#!/bin/bash

# Let's find out the Cpanel version
cpanel_version=$(cat /usr/local/cpanel/version | cut -d'.' -f2)


echo
# Check the version and take appropriate action
if [[ $cpanel_version -lt 108 ]]; then
   # Actions to be taken if cPanel version is less than 108
    echo "cPanel version detected to be less than 108, operations begin"
	echo 

read -p "Enter MailBaby connection username: " username
read -sp "Enter MailBaby connection password: " password

eximconfdusuk="
%RETRYBLOCK%
+secondarymx * F,4h,5m; G,16h,1h,1.5; F,4d,8h
* * F,2h,15m; G,16h,1h,1.5; F,4d,8h
* auth_failed
@AUTH@
mailbaby_login:
driver = plaintext
public_name = LOGIN
client_send = : $username : $password

@BEGINACL@

@CONFIG@

chunking_advertise_hosts = ""
local_from_check = true
# mailbaby max size limit is 100MB while the cpanel default may be less#message_size_limit = 100M
ignore_bounce_errors_after = 1h
timeout_frozen_after = 12h


@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@


@POSTMAILCOUNT@

remoteserver_route:
driver = manualroute
transport = mailbaby_smtp
domains = !+local_domains
ignore_target_hosts = 127.0.0.0/8
route_list = * relay.mailbaby.net::25 randomize byname
host_find_failed = defer
no_more

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@
* data_4xx F,4h,1m
* rcpt_4xx F,4h,1m
* timeout F,4h,1m
* refused F,1h,5m
* lost_connection F,1h,1m
* * F,6h,5m

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@

  mailbaby_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536

"


echo "$eximconfdusuk" | sudo tee /etc/exim.conf.local >/dev/null

sudo /scripts/buildeximconf
sudo service exim restart

echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$NC"	
	echo -e "$NC->" "$GREEN""Mailbaby has been successfully installed and is usable. <-$NC"
	echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
exit 0

elif [[ $cpanel_version -ge 108 ]]; then
    # Actions to take if cPanel version is 108 or greater
	echo "cPanel version detected to be greater than 108, operations begin"

echo 

read -p "Enter MailBaby connection username: " username
read -sp "Enter MailBaby connection password: " password

eximconf="%RETRYBLOCK%
+secondarymx * F,4h,5m; G,16h,1h,1.5; F,4d,8h
* * F,2h,15m; G,16h,1h,1.5; F,4d,8h
* auth_failed
@AUTH@
mailbaby_login:
driver = plaintext
public_name = LOGIN
client_send = : $username : $password

@BEGINACL@

@CONFIG@

chunking_advertise_hosts = ""
local_from_check = true
# mailbaby max size limit is 100MB while the cpanel default may be less#message_size_limit = 100M
ignore_bounce_errors_after = 1h
timeout_frozen_after = 12h

@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@

@POSTMAILCOUNT@

remoteserver_route:
driver = manualroute
.ifdef SRSENABLED
# if outbound, and forwarding has been done, use an alternate transport
transport = \${if eq {\$local_part@\$domain} {\$original_local_part@\$original_domain} {mailbaby_smtp} {mailbaby_forward_smtp}}
.else
transport = mailbaby_smtp
.endif
domains = !+local_domains
ignore_target_hosts = 127.0.0.0/8
route_list = * relay.mailbaby.net::25 randomize byname
host_find_failed = defer
no_more

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@
* data_4xx F,4h,1m
* rcpt_4xx F,4h,1m
* timeout F,4h,1m
* refused F,1h,5m
* lost_connection F,1h,1m
* * F,6h,5m

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@
mailbaby_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_canon = relaxed
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536

  mailbaby_forward_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_canon = relaxed
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536
  .ifdef SRSENABLED
  return_path = \${srs_encode {SRS_SECRET} {\$return_path} {\$original_domain}}
  .endif
"

# write eximconf to file
echo "$eximconf" | sudo tee /etc/exim.conf.local >/dev/null

sudo /scripts/buildeximconf
sudo service exim restart

echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$NC"	
	echo -e "$NC->" "$GREEN""Mail Baby has been successfully installed. Ready to use! <-$NC"
	echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
exit 0
  
else
    # What to do if the cPanel version is outside the specified conditions
    echo "cPanel version not supported."
   exit 0
fi

}
#--------EN ANA FONKSIYON--------


#--------TR ANA FONKSIYON--------
function proccess_start_tr(){
#!/bin/bash

# Cpanel sürümünü öğrenelim
cpanel_version=$(cat /usr/local/cpanel/version | cut -d'.' -f2)


echo
# Sürümü kontrol et ve uygun işlemleri yapalım
if [[ $cpanel_version -lt 108 ]]; then
    # cPanel sürümü 108'den küçükse yapılacak işlemler
    echo "cPanel sürümü 108'den küçük olduğu tespit edildi işlemler başlıyor"
	echo 

read -p "MailBaby bağlantı kullanıcı adını girin: " username
read -sp "MailBaby bağlantı şifresini girin: " password

eximconfdusuk="
%RETRYBLOCK%
+secondarymx * F,4h,5m; G,16h,1h,1.5; F,4d,8h
* * F,2h,15m; G,16h,1h,1.5; F,4d,8h
* auth_failed
@AUTH@
mailbaby_login:
driver = plaintext
public_name = LOGIN
client_send = : $username : $password

@BEGINACL@

@CONFIG@

chunking_advertise_hosts = ""
local_from_check = true
# mailbaby max size limit is 100MB while the cpanel default may be less#message_size_limit = 100M
ignore_bounce_errors_after = 1h
timeout_frozen_after = 12h


@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@


@POSTMAILCOUNT@

remoteserver_route:
driver = manualroute
transport = mailbaby_smtp
domains = !+local_domains
ignore_target_hosts = 127.0.0.0/8
route_list = * relay.mailbaby.net::25 randomize byname
host_find_failed = defer
no_more

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@
* data_4xx F,4h,1m
* rcpt_4xx F,4h,1m
* timeout F,4h,1m
* refused F,1h,5m
* lost_connection F,1h,1m
* * F,6h,5m

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@

  mailbaby_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536

"


echo "$eximconfdusuk" | sudo tee /etc/exim.conf.local >/dev/null

sudo /scripts/buildeximconf
sudo service exim restart

echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$NC"	
	echo -e "$NC->" "$GREEN""Mailbaby başarılı bir şekilde kuruldu. Kullanıma hazır! <-$NC"
	echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
exit 0

elif [[ $cpanel_version -ge 108 ]]; then
    # cPanel sürümü 108 veya daha büyükse yapılacak işlemler
	echo "cPanel sürümü 108'den büyük olduğu tespit edildi işlemler başlıyor"

echo 

read -p "MailBaby bağlantı kullanıcı adını girin: " username
read -sp "MailBaby bağlantı şifresini girin: " password

eximconf="%RETRYBLOCK%
+secondarymx * F,4h,5m; G,16h,1h,1.5; F,4d,8h
* * F,2h,15m; G,16h,1h,1.5; F,4d,8h
* auth_failed
@AUTH@
mailbaby_login:
driver = plaintext
public_name = LOGIN
client_send = : $username : $password

@BEGINACL@

@CONFIG@

chunking_advertise_hosts = ""
local_from_check = true
# mailbaby max size limit is 100MB while the cpanel default may be less#message_size_limit = 100M
ignore_bounce_errors_after = 1h
timeout_frozen_after = 12h

@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@

@POSTMAILCOUNT@

remoteserver_route:
driver = manualroute
.ifdef SRSENABLED
# if outbound, and forwarding has been done, use an alternate transport
transport = \${if eq {\$local_part@\$domain} {\$original_local_part@\$original_domain} {mailbaby_smtp} {mailbaby_forward_smtp}}
.else
transport = mailbaby_smtp
.endif
domains = !+local_domains
ignore_target_hosts = 127.0.0.0/8
route_list = * relay.mailbaby.net::25 randomize byname
host_find_failed = defer
no_more

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@
* data_4xx F,4h,1m
* rcpt_4xx F,4h,1m
* timeout F,4h,1m
* refused F,1h,5m
* lost_connection F,1h,1m
* * F,6h,5m

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@
mailbaby_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_canon = relaxed
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536

  mailbaby_forward_smtp:
  driver = smtp
  hosts_require_auth = *
  tls_tempfail_tryclear = true
  headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*} {\$authenticated_id} {\${if match {\$authenticated_id}{.+} {\$authenticated_id@\${primary_hostname}} {\$authenticated_id}}}}
  dkim_domain = \${lookup{\$sender_address_domain}lsearch{ret=key{/etc/localdomains}}}
  dkim_selector = default
  dkim_canon = relaxed
  dkim_private_key = \"/var/cpanel/domain_keys/private/\${dkim_domain}\"
  # uncomment this if users get errors message has line too long for transport
  #message_linelength_limit = 65536
  .ifdef SRSENABLED
  return_path = \${srs_encode {SRS_SECRET} {\$return_path} {\$original_domain}}
  .endif
"

# eximconf'u dosyaya yazdır
echo "$eximconf" | sudo tee /etc/exim.conf.local >/dev/null

sudo /scripts/buildeximconf
sudo service exim restart

echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$NC"	
	echo -e "$NC->" "$GREEN""Mailbaby başarılı bir şekilde kuruldu. Kullanıma hazır! <-$NC"
	echo -e "$YELLOW~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
exit 0
  
else
    # cPanel sürümü belirtilen koşulların dışında ise yapılacak işlem
    echo "cPanel sürümü desteklenmiyor."
   exit 0
fi
}
#--------TR ANA FONKSIYON--------

	while true
	do
		header
		ana_menu
		ana_siklar
	done
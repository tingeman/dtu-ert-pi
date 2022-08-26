import requests
import netifaces as ni
import sys
import socket

url_post = 'http://alive.arctic.byg.dtu.dk/submit_data'
url_info = 'http://alive.arctic.byg.dtu.dk/info'

hostname = socket.gethostname()

json = {'client': hostname}
message = []

if len(sys.argv)>1:
    message.append('; '.join(sys.argv[1:]))

try:
    r = requests.get('http://ifconfig.me')
    json['public_ip'] = r.text
except ConnectionError:
    # handle case where we cannot connect
    pass

try:
    ppp0 = ni.ifaddresses('ppp0')[ni.AF_INET]
except:
    message.append('ppp0 interface does not exist')
else:
    json['ppp0_addr'] = ppp0[0]['addr']
    # json['ppp0_netmask'] = ppp0[0]['netmask']

try:
    eth0 = ni.ifaddresses('eth0')[ni.AF_INET]
except:
    message.append('eth0 interface does not exist')
else:
    json['eth0_addr'] = eth0[0]['addr']
    # json['eth0_netmask'] = eth0[0]['netmask']

print(json)

if len(message) > 0:
    json['message'] = '; '.join(message)

r = requests.post(url_post, json=json)

print(r.text)

r2 = requests.get(url_info)
print(r2.text)

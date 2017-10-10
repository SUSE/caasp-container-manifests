import netifaces
import socket

def get_local_ipv4():
    return netifaces.ifaddresses('eth0')[netifaces.AF_INET][0]['addr']

def get_instance_id():
    return socket.getfqdn()

def upload_ssh_public_key(key_name, public_key_data):
    raise Exception('not yet implemented')


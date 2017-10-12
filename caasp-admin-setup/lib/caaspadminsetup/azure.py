import netifaces
import socket

def get_local_ipv4():
    return netifaces.ifaddresses('eth0')[netifaces.AF_INET][0]['addr']

def get_instance_id():
    return socket.getfqdn()

def create_public_key(key_name, public_key_data):
    raise Exception('not yet implemented')

def generate_salt_cloud_config(
        config_dir,
        key_name,
        private_key_file,
        image,
        root_volume_size
    ):
    raise Exception('not yet implemented')

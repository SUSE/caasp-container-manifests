import netifaces
import socket
import os
import random
import requests
import string

metadata_headers = { "Metadata": "true" }
metadata_params = { "format": "text", "api-version": "2017-04-02" }
metadata_base_url = "http://169.254.169.254/metadata/instance/"

def _generate_password():
    chars = string.ascii_letters + string.digits + '!@#$%^&*()=+'
    random.seed(os.urandom(1024))
    return ''.join(random.choice(chars) for i in range(32))

def _get_cluster_node_image_id():
    # FIXME: return something useful here
    # options are publisher|offer|sku|version or look up from pint
    return "IMAGE"

def _get_instance_location():
    r = requests.get(
        metadata_base_url+"compute/location",
        params = metadata_params,
        headers = metadata_headers
    )
    if r.status_code == requests.codes.ok:
        return r.text
    else:
        logging.warning("Could not determine instance location ({})".format(r.text))
        return None

def get_local_ipv4():
    return netifaces.ifaddresses('eth0')[netifaces.AF_INET][0]['addr']

def get_instance_id():
    return socket.getfqdn()

def create_public_key(key_name, public_key_data):
    # not supported in Azure
    return

def setup_network_security(cluster_name):
    return

def get_salt_cloud_profile_config(profile_name, root_volume_size, ssh_user, ssh_pub_key):
    config = {
        profile_name:  {
            "provider": "azure",
            "image": _get_cluster_node_image_id(),
            "location": _get_instance_location(),
            "script": "/etc/salt/cloud-configure-minion.sh",
            "script_args": "-s \"{}\"".format(ssh_pub_key),
            "ssh_username": ssh_user,
            "ssh_password": _generate_password(),
            "cleanup_disks": True,
            "cleanup_vhds": True,
            "cleanup_interfaces": True
        }
    }
    return config

def get_salt_cloud_provider_config(key_name, private_key_file):
    config = {
        "azure": {
            "driver": "azurearm",
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config

def setup_network_security(cluster_name):
    return

def get_database_pillars():
    return [
        {
            "name": "cloud:profiles:cluster_node:image",
            "value": _get_cluster_node_image_id()
        }
    ]

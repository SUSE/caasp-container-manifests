import caaspadminsetup.utils as utils
import logging
import netifaces
import os
import random
import requests
import socket
import string

metadata_headers = {"Metadata": "true"}
metadata_params = {"format": "text", "api-version": "2017-04-02"}
metadata_base_url = "http://169.254.169.254/metadata/instance/"


def _generate_password():
    chars = string.ascii_letters + string.digits + '!@#$%^&*()=+'
    random.seed(os.urandom(1024))
    return ''.join(random.choice(chars) for i in range(32))


def _get_cluster_node_image_id():
    region = _get_instance_location()
    image_data = utils.get_cluster_image_identifier('microsoft', region)
    # in salt-cloud image IDs may be in URN or VHD blob URI notation; the
    # latter may be used for custom images
    if image_data.get('urn'):
        image_to_use = image_data.get('urn').replace(':', '|')
    else:
        # warn if 'name' is not a URI
        if not image_data.get('name').startswith('http'):
           logging.warning('Custom image ID is not a VHD blob URI.')
           logging.warning('Cluster node instance creation will likely fail.')
        image_to_use = image_data.get('name')
    logging.info('Using cluster node image with name: "%s"' % image_to_use)
    return image_to_use


def _get_instance_location():
    r = requests.get(
        metadata_base_url+"compute/location",
        params=metadata_params,
        headers=metadata_headers
    )
    if r.status_code == requests.codes.ok:
        return r.text
    else:
        logging.warning(
            "Could not determine instance location ({})".format(r.text)
        )
        return None


def get_local_ipv4():
    return netifaces.ifaddresses('eth0')[netifaces.AF_INET][0]['addr']


def get_instance_id():
    return socket.getfqdn()

def have_permissions():
    try:
        from msrestazure.azure_active_directory import MSIAuthentication
        credentials = MSIAuthentication()
    except ImportError:
        print("MSI authentication support not available on this system.")
        return False
    except requests.exceptions.HTTPError:
        print("This instance does not have session credentials.")
        print("Please enable system assgined identity on this VM with role 'Contributor'")
        print("and scope of the resource group you want to use for this cluster.")
        return False
    return True

def create_public_key(key_name, public_key_data):
    # not supported in Azure
    return


def setup_network_security(cluster_name):
    return


def get_salt_cloud_profile_config(
        profile_name,
        root_volume_size,
        ssh_user,
        ssh_pub_key,
        ssh_private_key_file):
    config = {
        profile_name:  {
            "provider": "azure",
            "image": _get_cluster_node_image_id(),
            "location": _get_instance_location(),
            "script": "/etc/salt/cloud-configure-minion.sh",
            "script_args": "-s \"{}\" -t {}".format(ssh_pub_key, get_local_ipv4()),
            "ssh_username": ssh_user,
            "ssh_password": _generate_password(),
            "bootstrap_interface": "private",
            "os_disk_size_gb": root_volume_size
        }
    }
    return config


def get_salt_cloud_provider_config(key_name, private_key_file):
    config = {
        "azure": {
            "cleanup_disks": True,
            "cleanup_vhds": True,
            "cleanup_interfaces": True,
            "driver": "azurearm",
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config


def get_database_pillars():
    return [
        {
            "name": "cloud:profiles:cluster_node:image",
            "value": _get_cluster_node_image_id()
        }
    ]

import caaspadminsetup.utils as utils
import gcemetadata.gcemetadata as gcemetadata
import logging
import re


def _get_cluster_node_image_id():
    region = None  # All images are global
    image_data = utils.get_cluster_image_identifier('google', region)
    image_to_use = image_data.get('name')
    if not image_to_use.startswith('projects/'):
        # not a custom image, set project prefix
        if utils.get_from_config('procurement_flavor') == 'byos':
            project = 'suse-byos-cloud'
        else:
            project = 'suse-cloud'
        prefix = 'projects/{}/global/images/'.format(project)
        image_to_use = prefix + image_to_use
    logging.info('Using cluster node image with name: "%s"' % image_to_use)
    return image_to_use


def _get_from_metadata(key, category='instance'):
    meta = gcemetadata.GCEMetadata()
    meta.set_data_category(category)
    # make sure we get network related data from primary interface
    meta.set_net_device('0')
    return meta.get(key)


def _get_instance_location():
    zone = _get_from_metadata('zone')
    return zone.split('/')[3]


def _get_instance_network():
    network = _get_from_metadata('network')
    return network.split('/')[3]


def get_local_ipv4():
    return _get_from_metadata('ip')


def get_instance_id():
    return _get_from_metadata('id')


def have_permissions():
    scopes = _get_from_metadata('scopes')
    pattern = re.compile("auth/cloud-platform")
    if not pattern.search(scopes):
        print("This instance does not have the required API scopes configured.")
        print("Please attach a service account to this instance that includes")
        print("the roles 'Compute Admin' and 'Service Account Actor'.")
        return False
    return True


def create_public_key(key_name, public_key_data):
    # not used in GCE
    return


def get_salt_cloud_profile_config(
        profile_name,
        root_volume_size,
        ssh_user,
        ssh_pub_key,
        ssh_private_key_file):
    config = {
        profile_name:  {
            "provider": "gce",
            "location": _get_instance_location(),
            "network": _get_instance_network(),
            "external_ip": "None",
            "script": "/etc/salt/cloud-configure-minion.sh",
            "ssh_interface": "private_ips",
            "ssh_username": ssh_user,
            "ssh_keyfile": ssh_private_key_file,
            "use_persistent_disk": False,
            "metadata": '{"sshKeys": "caasp: '+ssh_pub_key+'"}',
            "ex_disks_gce_struct":
            [
                {
                    "boot": True,
                    "autoDelete": True,
                    "initializeParams":
                    {
                        "sourceImage": _get_cluster_node_image_id(),
                        "diskSizeGb": root_volume_size
                    }
                }
            ]
        }
    }
    return config


def get_salt_cloud_provider_config(key_name, private_key_file):
    config = {
        "gce": {
            "driver": "gce",
            "project": _get_from_metadata(key="project-id", category="project"),
            "service_account_email_address": "",
            "service_account_private_key": "",
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config


def setup_network_security(cluster_name):
    # not used in GCE
    return


def get_database_pillars():
    prefix = "cloud:profiles:cluster_node:"
    pillars = [
        {
            "name": prefix + "image",
            "value": _get_cluster_node_image_id()
        },
        {
            "name": prefix + "network",
            "value": _get_instance_network()
        },
    ]
    return pillars

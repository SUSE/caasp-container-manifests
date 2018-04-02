import caaspadminsetup.utils as utils
import gcemetadata
import logging


def _get_cluster_node_image_id():
    region = None  # All images are global
    image_data = utils.get_cluster_image_identifier('google', region)
    image_to_use = image_data.get('name')
    logging.info('Using cluster node image with name: "%s"' % image_to_use)
    return image_to_use


def _get_from_metadata(key):
    meta = gcemetadata.GCEMetadata()
    meta.set_data_category('instance')
    return meta.get(key)


def get_local_ipv4():
    return _get_from_metadata('ip')


def get_instance_id():
    return _get_from_metadata('id')


def create_public_key(key_name, public_key_data):
    raise Exception('not yet implemented')


def get_salt_cloud_profile_config(image, root_volume_size):
    raise Exception('not yet implemented')


def get_salt_cloud_provider_config(key_name, private_key_file):
    raise Exception('not yet implemented')


def setup_network_security(cluster_name):
    raise Exception('not yet implemented')

import gcemetadata

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

def generate_salt_cloud_config(
        config_dir,
        key_name,
        private_key_file,
        image,
        root_volume_size
    ):
    raise Exception('not yet implemented')


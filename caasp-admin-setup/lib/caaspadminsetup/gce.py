import gcemetadata

def _get_from_metadata(key):
    meta = gcemetadata.GCEMetadata()
    meta.set_data_category('instance')
    return meta.get(key)

def get_local_ipv4():
    return _get_from_metadata('ip')

def get_instance_id():
    return _get_from_metadata('id')

def upload_ssh_public_key(key_name, public_key_data):
    raise Exception('not yet implemented')

import boto3
import ec2metadata

def _get_from_metadata(key):
    return ec2metadata.EC2Metadata().get(key)

def _get_instance_region():
    return _get_from_metadata('availability-zone')[:-1]

def get_local_ipv4():
    return _get_from_metadata('local-ipv4')

def get_instance_id():
    return _get_from_metadata('instance-id')

def upload_ssh_public_key(key_name, public_key_data):
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    client.import_key_pair(
        KeyName = key_name,
        PublicKeyMaterial = public_key_data
    )


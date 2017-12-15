import boto3
import ec2metadata
import urllib

_cluster_security_group_id = None

def _get_from_metadata(key):
    return ec2metadata.EC2Metadata(api="2016-09-02").get(key)

def _get_instance_region():
    return _get_from_metadata('availability-zone')[:-1]

def _get_instance_mac():
    return _get_from_metadata("mac")

def _get_instance_vpc_id():
    return _get_from_metadata("vpc-id")

def _get_instance_subnet_id():
    return _get_from_metadata('subnet-id')

def get_local_ipv4():
    return _get_from_metadata('local-ipv4')

def get_instance_id():
    return _get_from_metadata('instance-id')

def create_public_key(key_name, public_key_data):
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    client.import_key_pair(
        KeyName = key_name,
        PublicKeyMaterial = public_key_data
    )

def setup_network_security(cluster_name):
    global _cluster_security_group_id
    client = boto3.client(service_name='ec2', region_name=_get_instance_region())
    response = client.create_security_group(
                   Description="Autocreated by SUSE CaaSP",
                   GroupName=cluster_name,
                   VpcId=_get_instance_vpc_id()
               )
    group_id = response["GroupId"]
    res = boto3.resource(service_name='ec2', region_name=_get_instance_region())
    sec_group = res.SecurityGroup(group_id)
    sec_group.authorize_ingress(
        IpPermissions=
        [{
            "IpProtocol": "-1",
            "UserIdGroupPairs":
            [{
                'GroupId': sec_group.group_id
            }]
        }]
    )
    sec_group.authorize_ingress(
        IpProtocol="-1",
        CidrIp="{}/32".format(get_local_ipv4())
    )
    _cluster_security_group_id = sec_group.group_id

    # also attach security group to host instance so nodes can
    # communicate to salt-master
    groups_desc = client.describe_instance_attribute(
                      InstanceId=get_instance_id(),
                      Attribute="groupSet"
                  )["Groups"]
    groups = []
    for grp in groups_desc:
        groups += [ grp["GroupId"] ]
    groups += [ _cluster_security_group_id ]
    client.modify_instance_attribute(InstanceId=get_instance_id(), Groups=groups)

def get_salt_cloud_profile_config(profile_name, image, root_volume_size):
    config = {
        profile_name:  {
            "provider": "ec2",
            "image": image,
            "script": "/etc/salt/cloud-configure-minion.sh",
            "block_device_mappings": [{
                "DeviceName": "/dev/sda1",
                "Ebs.VolumeSize": root_volume_size
            }],
            "network_interfaces": [{
                "DeviceIndex": 0,
                "AssociatePublicIpAddress": False,
                "SecurityGroupId": _cluster_security_group_id,
                "SubnetId": _get_instance_subnet_id()
            }]
        }
    }
    return config

def get_salt_cloud_provider_config(key_name, private_key_file):
    config = {
        "ec2": {
            "driver": "ec2",
            "keyname": key_name,
            "ssh_interface": "private_ips",
            "ssh_user": "ec2-user",
            "private_key": private_key_file,
            "id": "use-instance-role-credentials",
            "key": "use-instance-role-credentials",
            "location": _get_instance_region(),
            "minion": {
                "master": get_local_ipv4()
            }
        }
    }
    return config

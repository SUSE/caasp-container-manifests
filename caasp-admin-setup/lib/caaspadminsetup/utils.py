def load_platform_module(platform_name):
    mod = __import__('caaspadminsetup.%s' % platform_name, fromlist=[''])
    return mod

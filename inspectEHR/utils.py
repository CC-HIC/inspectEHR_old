import yaml


def load_spec(filepath):
    """Loads in CC-HIC specification from YAML."""
    with open(filepath, 'r') as f:
        return yaml.load(f)

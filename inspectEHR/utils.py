import yaml

class ProgressMarker():
    """Print a dot with suitable line breaks etc"""

    def __init__(self, steps=10, linebreak=50):

        self.i = 0
        self.steps = steps
        self.linebreak = linebreak * steps

    def status(self):
        if self.i % self.linebreak == 0:
            print("\n{:>6} ".format(self.i), end='')
        if self.i % self.steps == 0:
            print(".", end='')

        self.i += 1
        return None

    def reset(self):
        self.i = 0

def load_spec(filepath):
    """Loads in CC-HIC specification from YAML."""
    with open(filepath, 'r') as f:
        return yaml.load(f)

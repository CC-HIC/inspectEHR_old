
class MixinOne(object):
    def print_name(self):
        print("{} is using MixinOne.".format(self.name))


class MixinTwo(object):
    def print_name(self):
        print("{} is using MixinTwo.".format(self.name))

class AutoMixinMeta(type):
    def __call__(cls, *args, **kwargs):
        try:
            mixin = kwargs.pop('mixin')
            name = "{}With{}".format(cls.__name__, mixin.__name__)
            cls = type(name, (mixin, cls), dict(cls.__dict__))
        except KeyError:
            pass
        return type.__call__(cls, *args, **kwargs)

class Sub(object, metaclass = AutoMixinMeta):

    def __init__(self, name):
        self.name = name


s = Sub('foo', mixin=MixinOne)
s.print_name()

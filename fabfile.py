from fabric.api import cd, env, run, parallel, task

try:
    import fabfile_local
    _pyflakes = fabfile_local
except ImportError:
    pass

@task
@parallel
def update():
    "Updates the installer generate code on the host."
    with cd("~/vagrant-installers"):
        run("git pull")

@task
@parallel
def build():
    "Builds the installer."
    with cd("~/vagrant-installers"):
        run("rake")

@task
def all():
    "Run the task against all hosts."
    for _, value in env.roledefs.iteritems():
        env.hosts.extend(value)

@task
def role(name):
    "Set the hosts to a specific role."
    env.hosts = env.roledefs[name]

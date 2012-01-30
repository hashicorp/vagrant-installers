from fabric.api import cd, run, task

try:
    import fabfile_local
    _pyflakes = fabfile_local
except ImportError:
    pass

@task
def update():
    with cd("~/vagrant-installers"):
        run("git pull")

from fabric.api import cd, env, local, run, parallel, task

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
def build(revision="HEAD"):
    "Builds the installer."
    aws = "%s,%s,%s" % (env.aws["aws_access_key_id"],
                        env.aws["aws_secret_access_key"],
                        env.aws["bucket"])

    env_vars = {}
    env_vars["VAGRANT_REVISION"] = revision
    env_vars["AWS"] = aws

    if env.host == "local":
        # This is a local install, meaning we're running on THIS machine.
        local("%s rake" % _env_string(env_vars))
    else:
        # Otherwise, it is a remote install, so we execute on a remote
        # machine.
        with cd("~/vagrant-installers"):
            run("%s rake" % _env_string(env_vars))

@task
def all():
    "Run the task against all hosts."
    for _, value in env.roledefs.iteritems():
        env.hosts.extend(value)

@task
def role(name):
    "Set the hosts to a specific role."
    env.hosts = env.roledefs[name]

def _env_string(env_vars):
    parts = []
    for key, value in env_vars.iteritems():
        parts.append("%s=%s" % (key, value))

    return " ".join(parts)

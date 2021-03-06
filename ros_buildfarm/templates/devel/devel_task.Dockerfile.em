# generated from @template_name

@(TEMPLATE(
    'snippet/from_base_image.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
    arch=arch,
))@
MAINTAINER Dirk Thomas dthomas+buildfarm@@osrfoundation.org

VOLUME ["/var/cache/apt/archives"]

ENV DEBIAN_FRONTEND noninteractive

@(TEMPLATE(
    'snippet/setup_locale.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
    timezone=timezone,
))@

RUN useradd -u @uid -m buildfarm

@(TEMPLATE(
    'snippet/old_release_set.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
))@

@(TEMPLATE(
    'snippet/add_distribution_repositories.Dockerfile.em',
    distribution_repository_keys=distribution_repository_keys,
    distribution_repository_urls=distribution_repository_urls,
    os_code_name=os_code_name,
    add_source=False,
))@

@[if os_name == 'ubuntu']@
# Enable multiverse
RUN sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list
@[else if os_name == 'debian']@
# Add contrib and non-free to debian images
RUN echo deb http://http.debian.net/debian @os_code_name contrib non-free | tee -a /etc/apt/sources.list
@[end if]@

@(TEMPLATE(
    'snippet/add_wrapper_scripts.Dockerfile.em',
    wrapper_scripts=wrapper_scripts,
))@

# automatic invalidation once every day
RUN echo "@today_str"

@(TEMPLATE(
    'snippet/install_python3.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
))@

RUN python3 -u /tmp/wrapper_scripts/apt-get.py update-and-install -q -y ccache

@(TEMPLATE(
    'snippet/install_dependencies.Dockerfile.em',
    dependencies=dependencies,
    dependency_versions=dependency_versions,
))@

USER buildfarm
ENTRYPOINT ["sh", "-c"]
@{
cmd = \
    'PATH=/usr/lib/ccache:$PATH' + \
    ' PYTHONPATH=/tmp/ros_buildfarm:$PYTHONPATH python3 -u'
if not testing:
    cmd += \
        ' /tmp/ros_buildfarm/scripts/devel/catkin_make_isolated_and_install.py' + \
        ' --rosdistro-name %s --clean-before' % rosdistro_name
else:
    cmd += \
        ' /tmp/ros_buildfarm/scripts/devel/catkin_make_isolated_and_test.py' + \
        ' --rosdistro-name %s' % rosdistro_name
if not prerelease_overlay:
    cmd += \
        ' --workspace-root /tmp/catkin_workspace'
else:
    cmd += \
        ' --workspace-root /tmp/catkin_workspace_overlay' + \
        ' --parent-result-space /tmp/catkin_workspace/install_isolated'
}@
CMD ["@cmd"]

def main(ctx):
  versions = [
    'fedora',
  ]

  arches = [
    'amd64',
  ]

  # image's base version
  # For example, in latest's Dockerfile;
  #   FROM ubuntu:22.04
  # then,
  #   'latest': '22.04'
  base_img_tag = {
    'fedora': ['fedora', '42'],
  }

  config = {
    'version': 'latest',
    'arch': 'amd64',
    'repo': ctx.repo.name,
    'squishversion': {
        'fedora': '9.1.0-qt68x-linux64',
    },
    'description': 'Squish for ownCloud CI',
    's3secret': {
       'from_secret': 'squish_download_s3secret',
    },
  }

  stages = []
  for version in versions:
    config['version'] = version

    if config['version'] == 'latest':
      config['path'] = 'latest'
    else:
      config['path'] = '%s' % config['version']

    config['tags'] = [config['version']]
    if config['version'] == 'latest':
      config['tags'].append('%s-%s' % (base_img_tag[config['version']][0], config['squishversion'][config['version']]))
    else:
      config['tags'].append('%s-%s' % (config['version'], config['squishversion'][config['version']]))
    if config['version'] in base_img_tag:
      config['tags'].append(
        '%s-%s-%s' % (base_img_tag[config['version']][0], base_img_tag[config['version']][1], config['squishversion'][config['version']])
      )


    stages.append(docker(config))

  after = [
    documentation(config),
    notification(config),
  ]

  for s in stages:
    for a in after:
      a['depends_on'].append(s['name'])

  return stages + after

def docker(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': '%s-%s' % (config['arch'], config['path']),
    'platform': {
      'os': 'linux',
      'arch': config['arch'],
    },
    'steps': steps(config),
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }

def documentation(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'documentation',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'link-check',
        'image': 'ghcr.io/tcort/markdown-link-check:3.8.7',
        'commands': [
          '/src/markdown-link-check README.md',
        ],
      },
      {
        'name': 'publish',
        'image': 'chko/docker-pushrm:1',
        'environment': {
          'DOCKER_PASS': {
            'from_secret': 'public_password',
          },
          'DOCKER_USER': {
            'from_secret': 'public_username',
          },
          'PUSHRM_FILE': 'README.md',
          'PUSHRM_TARGET': 'owncloudci/${DRONE_REPO_NAME}',
          'PUSHRM_SHORT': config['description'],
        },
        'when': {
          'ref': [
            'refs/heads/master',
          ],
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }


def notification(config):
  steps = [{
    'name': 'notify',
    'image': 'plugins/slack',
    'settings': {
      'webhook': {
        'from_secret': 'rocketchat_talk_webhook',
      },
      'channel': 'builds',
    },
    'when': {
      'status': [
        'success',
        'failure',
      ],
    },
  }]

  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'notification',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'clone': {
      'disable': True,
    },
    'steps': steps,
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
      'status': [
        'success',
        'failure',
      ],
    },
  }

def dryrun(config):
  return [{
    'name': 'dryrun',
    'image': 'plugins/docker',
    'environment':{
      'S3SECRET': config['s3secret']
    },
    'settings': {
      'dry_run': True,
      'tags': config['tags'],
      'dockerfile': '%s/Dockerfile.%s' % (config['path'], config['arch']),
      'repo': 'owncloudci/%s' % config['repo'],
      'context': config['path'],
      'build_args': [
        'SQUISHVERSION=%s' % config['squishversion'][config['version']],
      ],
      'build_args_from_env': [
        'S3SECRET'
      ],
    },
    'when': {
      'ref': [
        'refs/pull/**',
      ],
    },
  }]

def publish(config):
  return [{
    'name': 'publish',
    'image': 'plugins/docker',
    'environment':{
      'S3SECRET': config['s3secret']
    },
    'settings': {
      'username': {
        'from_secret': 'public_username',
      },
      'password': {
        'from_secret': 'public_password',
      },
      'tags': config['tags'],
      'dockerfile': '%s/Dockerfile.%s' % (config['path'], config['arch']),
      'repo': 'owncloudci/%s' % config['repo'],
      'context': config['path'],
      'pull_image': False,
      'build_args': [
        'SQUISHVERSION=%s' % config['squishversion'][config['version']],
      ],
      'build_args_from_env': [
        'S3SECRET'
      ],
    },
    'when': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }]



def steps(config):
  return dryrun(config) + publish(config)

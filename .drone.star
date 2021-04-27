def main(ctx):
  versions = [
    'latest',
  ]

  arches = [
    'amd64',
  ]

  config = {
    'version': None,
    'arch': None,
    'trigger': [],
    'repo': ctx.repo.name,
    'squishversion': '6.7.0-qt512x-linux64',
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
      config['path'] = 'v%s' % config['version']

    m = manifest(config)
    inner = []

    for arch in arches:
      config['arch'] = arch

      if config['version'] == 'latest':
        config['tag'] = arch
      else:
        config['tag'] = '%s-%s' % (config['version'], arch)

      if config['arch'] == 'amd64':
        config['platform'] = 'amd64'

      if config['arch'] == 'arm64v8':
        config['platform'] = 'arm64'

      if config['arch'] == 'arm32v7':
        config['platform'] = 'arm'

      config['internal'] = '%s-%s' % (ctx.build.commit, config['tag'])

      d = docker(config)
      m['depends_on'].append(d['name'])

      inner.append(d)

    inner.append(m)
    stages.extend(inner)

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
      'arch': config['platform'],
    },
    'steps': steps(config),
    'image_pull_secrets': [
      'registries',
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }

def manifest(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'manifest-%s' % config['path'],
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'manifest',
        'image': 'plugins/manifest',
        'settings': {
          'username': {
            'from_secret': 'public_username',
          },
          'password': {
            'from_secret': 'public_password',
          },
          'spec': '%s/manifest.tmpl' % config['path'],
          'ignore_missing': 'true',
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
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
        'image': 'ghcr.io/tcort/markdown-link-check:stable',
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
        'from_secret': 'private_rocketchat',
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

  downstream = [{
    'name': 'downstream',
    'image': 'plugins/downstream',
    'settings': {
      'token': {
        'from_secret': 'drone_token',
      },
      'server': 'https://drone.owncloud.com',
      'repositories': config['trigger'],
    },
    'when': {
      'status': [
        'success',
      ],
    },
  }]

  if config['trigger']:
    steps = downstream + steps

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
      'tags': config['tag'],
      'dockerfile': '%s/Dockerfile.%s' % (config['path'], config['arch']),
      'repo': 'owncloudci/%s' % config['repo'],
      'context': config['path'],
      'build_args': [
        'SQUISHVERSION=%s' % config['squishversion'],
      ],
      'build_args_from_env': [
        'S3SECRET'
      ]
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
      'tags': config['tag'],
      'dockerfile': '%s/Dockerfile.%s' % (config['path'], config['arch']),
      'repo': 'owncloudci/%s' % config['repo'],
      'context': config['path'],
      'pull_image': False,
      'build_args': [
        'SQUISHVERSION=%s' % config['squishversion'],
      ],
      'build_args_from_env': [
        'S3SECRET'
      ]
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

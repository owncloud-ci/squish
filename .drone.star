'''
This config defines the Drone CI pipelines for building and publishing Squish images for ownCloud CI.
'''

versions = {
  # <base_image>: <base_image_tag>
  'fedora': '42',
}

def main(ctx):
  config = {
    'version': 'latest',
    'arch': 'amd64',
    'repo': ctx.repo.name,
    'squishversion': {
        'fedora': '8.1.0-qt68x-linux64',
    },
    'description': 'Squish for ownCloud CI',
    's3secret': {
        'from_secret': 'squish_download_s3secret',
    },
    'licensekey': {
       'from_secret': 'squish_licensekey_new',
    },
    'ghostunnel_ca_cert': {
       'from_secret': 'ghostunnel_ca_cert',
    },
    'ghostunnel_client_cert': {
       'from_secret': 'ghostunnel_client_cert',
    },
    'ghostunnel_client_key': {
       'from_secret': 'ghostunnel_client_key',
    },
  }

  stages = []
  for version, base_img_tag in versions.items():
    config['version'] = version
    config['base_image_tag'] = base_img_tag

    if config['version'] == 'latest':
      config['path'] = 'latest'
    else:
      config['path'] = config['version']

    config['tags'] = [config['version']]
    config['tags'].append('%s-%s' % (config['version'], config['squishversion'][config['version']]))
    config['tags'].append(
      '%s-%s-%s' % (config['version'], base_img_tag, config['squishversion'][config['version']])
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
    'volumes': volumes(config),
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }


def volumes(config):
    return [
    {
        'name': 'docker',
        'temp': {},
    },
    ]

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
    'image': 'docker.io/owncloudci/drone-docker-buildx:4',
    'environment':{
      'S3SECRET': config['s3secret'],
      'LICENSEKEY': config['licensekey'],
      'CACERT': config['ghostunnel_ca_cert'],
      'CLIENTKEY': config['ghostunnel_client_key'],
      'CLIENTCERT': config['ghostunnel_client_cert'],
    },
    'settings': {
      'dry_run': True,
      'tags': config['tags'],
      'dockerfile': '%s/Dockerfile.%s' % (config['path'], config['arch']),
      'repo': 'owncloudci/%s' % config['repo'],
      'secrets': ['id=cacert\\\\,env=CACERT', 'id=client-cert\\\\,env=CLIENTCERT', 'id=client-key\\\\,env=CLIENTKEY'],
      'context': config['path'],
      'build_args': [
        'SQUISHVERSION=%s' % config['squishversion'][config['version']],
        'BASETAG=%s' % config['base_image_tag'],
      ],
      'build_args_from_env': [
        'S3SECRET',
        'LICENSEKEY',
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
      'S3SECRET': config['s3secret'],
      'LICENSEKEY': config['licensekey'],
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
        'BASETAG=%s' % config['base_image_tag'],
      ],
      'build_args_from_env': [
        'S3SECRET',
        'LICENSEKEY',
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
  return dryrun(config)

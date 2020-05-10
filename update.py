#!/usr/bin/env python3
"""
Dirty website parser to get updates for Matlab's MCR.

Each Matlab release name (R2020a etc) gets a branch that contains a single
Dockerfile and each release version (9.8 or 9.8.5 for 9.8 Update 5) becomes
a tag in that branch. So a sample history for R2020a could look like:

 + [R2020a] <9.8> <9.8.2> Auto-Update
 + <9.8.1> Auto-Update
 + <9.8.0> Auto-Update
 + <master> Import

(Circle)CI should then fire a docker build and push for every tag received.

Update.py should be run often enough to catch individual matlab releae updates.
"""

import re
from subprocess import DEVNULL, run
from urllib import request

from packaging import version
from bs4 import BeautifulSoup

REL_URL = 'https://www.mathworks.com/products/compiler/matlab-runtime.html'
VER_LIMIT = '9.3'

def call(cmd, split=True, show=False):
    if split:
        cmd = cmd.split()
    if show:
        process = run(cmd)
    else:
        process = run(cmd, stdout=DEVNULL, stderr=DEVNULL)
    return process.returncode == 0


with request.urlopen(REL_URL) as res:
    if res.status != 200:
        raise RuntimeError('Could not open matlab release URL')
    html = res.read()

soup = BeautifulSoup(html, 'html.parser')
ver_re = re.compile(r'(R2\d{3}.) \((\d\.\d)\)')
rel_re = re.compile(r'Release/(\d+)/')

dockers = []
for row in soup.find_all('table')[0].find_all('tr'):
    tds = row.find_all('td')
    if len(tds) >= 4:
        name = tds[0].text
        match = ver_re.match(name)
        if not match:
            continue
        mcr_name, mcr_ver = match.groups()
        if version.parse(mcr_ver) <= version.parse(VER_LIMIT):
            continue
        try:
            link = tds[2].a.get('href')
        except (KeyError, ValueError):
            raise RuntimeError('Error parsing matlab release page')
        if 'glnxa64' not in link:
            raise RuntimeError('Error parsing matlab release page link')
        match = rel_re.search(link)
        if match:
            mcr_ver = '{}.{}'.format(mcr_ver, match.groups()[0])
        dockers.append((mcr_name, mcr_ver, link))


variants = [
    ('Dockerfile-full.template', ''),
    #('Dockerfile-core.template', '-core')
]

for docker in dockers:
    mcr_name, mcr_ver, link = docker
    if len(mcr_ver.split('.')) == 2:
        mcr_ver = mcr_ver + '.0'
    mcr_ver_maj = '.'.join(mcr_ver.split('.')[0:2])
    mcr_ver_dir = 'v{}'.format(mcr_ver_maj.replace('.', ''))
    if not call('git checkout {}'.format(mcr_name)):
        call('git checkout -b {}'.format(mcr_name))
    if call('git rev-parse --verify {}'.format(mcr_ver)):
        print('Skipping {}/{}, already present'.format(mcr_name, mcr_ver))
        call('git checkout master')
        continue
    call('git merge master')
    for (template, suffix) in variants:
        print('Adding {}/{}{}'.format(mcr_name, mcr_ver, suffix))
        with open(template) as f:
            lines = f.read()
            lines = lines.replace('%%MATLAB_VERSION%%', mcr_name)
            lines = lines.replace('%%MCR_VERSION%%', mcr_ver_dir)
            lines = lines.replace('%%MCR_LINK%%', link)
            with open('Dockerfile', 'w+') as f2:
                f2.write(lines)
            call('git add Dockerfile')
            call(['git', 'commit', '-m', 'Auto-Update'], split=False)
            call('git tag {}{}'.format(mcr_ver, suffix))
            if mcr_ver != mcr_ver_maj:
                print('Adding {}/{}{}'.format(mcr_name, mcr_ver_maj, suffix))
                call('git tag {}{}'.format(mcr_ver_maj, suffix))
    call('git checkout master')

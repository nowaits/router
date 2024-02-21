#!/usr/bin/env python
# coding:utf-8

import os
import sys
import subprocess


def execute(cmd, is_async=False):
    try:
        #
        # @warn: 不使用with
        #
        #   1. with退出时为同步等待
        #   2. with退出时会提前关闭输入/输出导致shell判断逻辑异常
        #
        proc = subprocess.Popen(
            cmd, shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        if is_async:
            return True, None
        out, err = proc.communicate()
        return proc.returncode == 0, (out.decode(), err.decode())
    except Exception:
        return False, None


def make_deps(f):
    d = {}
    if os.path.islink(f):
        f = os.path.realpath(f)
    a, b = execute("ldd "+f)
    if not a:
        return []

    for i in b[0].split("\n\t"):
        for _r in i.strip().split():
            if not os.path.exists(_r):
                continue
            d[_r] = 1

    return list(d.keys())


module_deps = {}
args = sys.argv
if len(sys.argv) < 2:
    print("missing dir args")
    exit(1)

exclude_exts = {}
exclude_exts_list = [
    '.order', '.c', '.pem', '.pc', '.ko', '.md', '.ctypes',
    '.py', '.conf', '.decTest', '.mo', '.xml', '.dtd', '.def',
    '.cnf', '.zip', '.pickle', '.icns', '.sample', '.gif',
    '.pck', '.db', '.storage', '.shutdown', '.typed', '.au',
    '.vfat', '.vbs', '.ext2', '.builtin', '.bat', '.out', '.sh',
    '.info-3', '.pyw', '.so', '.doc', '.pub', '.info', '.info-8',
    '.uue', '.info-2', '.aif', '.info-1', '.info-6', '.info-7',
    '.info-4', '.info-5', '.management', '.7-config', '.pyc',
    '.tar', '.pyi', '.minix', '.pyo', '.wav', '.txt', '.egg-info',
    '.html', '.aiff', '.aifc', '.exe'
]

for e in exclude_exts_list:
    exclude_exts[e] = 1

for d, _, files in os.walk(sys.argv[1]):
    for f in files:
        n = "%s/%s" % (d, f)

        if os.path.splitext(n)[1] in exclude_exts or \
                os.path.islink(n):
            continue

        a, b = execute("file --mime-type "+n)
        if not a:
            continue

        mine_type = b[0].split(":")[1].strip(' \n')
        if not mine_type in [
            "application/x-executable",
            "application/x-sharedlib",
        ]:
            continue

        for r in make_deps(n):
            module_deps[r] = 1

# extra libs
for f in sys.argv[2].split():
    module_deps[f] = 1
    for r in make_deps(f):
        module_deps[r] = 1

def populate_deps():
    need_repopulate = False
    for k in list(module_deps.keys()):
        for r in make_deps(k):
            if r in module_deps:
                continue

            module_deps[r] = 1
            need_repopulate = True
    if need_repopulate:
        populate_deps()


populate_deps()

ks = list(module_deps.keys())
ks.sort()
print(' '.join(ks))

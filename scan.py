#!/usr/bin/env python

import subprocess as sp
from gevent.queue import Queue
from queue import Empty as QueueEmpty  # Changed from 'Queue' to 'queue' for Python 3 compatibility
from gevent import spawn
import signal
from gevent import select
import os


log = open('/dev/stdout', 'w')


def info(msg):
    if msg[-1] == '\n':
        log.write(msg[:-1])
    else:
        log.write(msg)
    log.flush()


def do_scan():
    info('Scanning...')
    # Define your distribution structure
    dist_base_path = '/data/dists/bg-gateway'
    for dist in os.getenv('DISTS', 'beta,stable').split(','):
        dist_path = f"{dist_base_path}/{dist}"
        for arch in os.getenv('ARCHS', 'armhf').split(','):
            path = f"{dist_path}/binary-{arch}"
            if not os.path.exists(path):
                os.makedirs(path)
            cmd = f'dpkg-scanpackages -m . | gzip -9c > {path}/Packages.gz'
            sp.check_call(cmd, shell=True, close_fds=True)
    info('Scanning...done')


def main():
    def loop():
        try:
            while True:
                rlist, _, _ = select.select([p.stdout], [], [p.stderr])
                if p.poll() is not None:
                    break
                if rlist:
                    line = p.stdout.readline().strip()
                    if len(line) == 0:
                        continue
                    if line.endswith('Packages.gz'):
                        continue
                    queue.put(('msg', line))
        except select.error:
            pass
        finally:
            try:
                p.kill()
            except:
                pass
            queue.put(('stop', 'unknown exit'))

    def stop(signum, frame):
        queue.put(('stop', str(signum)))

    signal.signal(signal.SIGCHLD, signal.SIG_IGN)
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGHUP, stop)
    signal.signal(signal.SIGINT, stop)

    queue = Queue()

    cmd = ['inotifywait', '-rm', '-e', 'close_write,moved_to,moved_from,delete', '.']
    p = sp.Popen(cmd, stdout=sp.PIPE, stderr=sp.PIPE, close_fds=True)
    t = spawn(loop)

    timeout = 1
    while True:
        try:
            msg = queue.get(True, timeout)
            if msg[0] == 'stop':
                break
            elif msg[0] == 'msg':
                try:
                    info(str(msg[1]))
                    timeout = 5
                except ValueError:
                    info('abnormal format message: ' + str(msg))
            else:
                info('unknown command: ' + str(msg))
        except QueueEmpty:
            do_scan()
            timeout = None
    try:
        p.kill()
    except OSError:
        pass
    finally:
        p.wait()
        t.join()


if __name__ == "__main__":
    main()

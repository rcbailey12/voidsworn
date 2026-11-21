"""Issue 1535: job tools make temporary folders that the normal cleanup can delete.

ship_job.bat and look_bench.bat put this folder on PYTHONPATH while their tools run under the job's own voidsworn-run
TEMP. Python 3.12.4+ on Windows gives a tempfile.mkdtemp folder (mode 0o700) a private ACL protected from inheritance,
and the cleanup could not remove it (cleanup 4, Nov 21: 31 folders, about 49 GB). The PC proof (board/pc-out-1535)
showed a stock mkdtemp folder protected even from a non-elevated job, so the 0o700 ACL alone is the cause. Here mkdtemp makes its folder with a plain mkdir instead, which inherits the TEMP folder's ACL. Names,
retries and the return value are as in the standard library; TemporaryDirectory uses it too.
"""
import os
import sys
import tempfile

_ENABLED = os.name == 'nt' or os.environ.get('VOIDSWORN_PYSITE_TEST') == '1'


def _mkdtemp(suffix=None, prefix=None, dir=None):
    prefix, suffix, dir, output_type = tempfile._sanitize_params(prefix, suffix, dir)
    names = tempfile._get_candidate_names()
    if output_type is bytes:
        names = map(os.fsencode, names)
    for _ in range(tempfile.TMP_MAX):
        name = next(names)
        file = os.path.join(dir, prefix + name + suffix)
        sys.audit('tempfile.mkdtemp', file)
        try:
            os.mkdir(file)
        except FileExistsError:
            continue
        except PermissionError:
            if os.name == 'nt' and os.path.isdir(dir) and os.access(dir, os.W_OK):
                continue
            raise
        return os.path.abspath(file)
    raise FileExistsError('No usable temporary directory name found')


if _ENABLED and not getattr(tempfile, '_voidsworn_inherited_acl', False):
    tempfile._voidsworn_stock_mkdtemp = tempfile.mkdtemp
    tempfile.mkdtemp = _mkdtemp
    tempfile._voidsworn_inherited_acl = True

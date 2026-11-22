"""Issue 1535: job tools make temporary folders that the normal cleanup can delete.

ship_job.bat and look_bench.bat put this folder on PYTHONPATH while their tools run under the job's own voidsworn-run
TEMP. Python 3.12.4+ on Windows gives a tempfile.mkdtemp folder (mode 0o700) a private ACL protected from inheritance,
and the cleanup could not remove it (cleanup 4, Nov 21: 31 folders, about 49 GB). The PC proof (board/pc-out-1535)
showed a stock mkdtemp folder protected even from a non-elevated job, so the 0o700 ACL alone is the cause. Here mkdtemp makes its folder with a plain mkdir instead, which inherits the TEMP folder's ACL. Names,
retries and the return value are as in the standard library; TemporaryDirectory uses it too.

Only inside the job's own scratch (Artoo on issue 1535, after PR 1537): the root is the TEMP folder the interpreter
starts with, and only when it is a runner's voidsworn-run-* scratch. A folder asked for anywhere else (an explicit dir=
outside that root, or a process whose TEMP is not job scratch) gets the standard library's private folder unchanged.
"""
import os
import sys
import tempfile

_TEST = os.environ.get('VOIDSWORN_PYSITE_TEST') == '1'
_ENABLED = os.name == 'nt' or _TEST


def _job_root():
    try:
        root = os.path.realpath(tempfile.gettempdir())
    except Exception:
        return None
    name = os.path.basename(root.rstrip('\\/'))
    if name.startswith('voidsworn-run-') or (_TEST and name.startswith('pysite1535-')):
        return os.path.normcase(root)
    return None


_ROOT = _job_root() if _ENABLED else None


def _inside_root(dir):
    if not _ROOT:
        return False
    try:
        here = os.path.normcase(os.path.realpath(os.fsdecode(dir)))
    except Exception:
        return False
    return here == _ROOT or here.startswith(_ROOT.rstrip('\\/') + os.sep)


def _mkdtemp(suffix=None, prefix=None, dir=None):
    if not _inside_root(tempfile.gettempdir() if dir is None else dir):
        return tempfile._voidsworn_stock_mkdtemp(suffix, prefix, dir)
    prefix, suffix, dir, output_type = tempfile._sanitize_params(prefix, suffix, dir)
    names = tempfile._get_candidate_names()
    if output_type is bytes:
        names = map(os.fsencode, names)
    for _ in range(tempfile.TMP_MAX):
        name = next(names)
        file = os.path.join(dir, prefix + name + suffix)
        # The folder actually made must sit inside the job scratch too: a prefix or suffix carrying a path (or ..)
        # could put it elsewhere, so that goes to the standard library (Artoo on PR 1600).
        if not _inside_root(os.path.dirname(os.path.abspath(file))):
            return tempfile._voidsworn_stock_mkdtemp(suffix, prefix, dir)
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


if _ROOT and not getattr(tempfile, '_voidsworn_inherited_acl', False):
    tempfile._voidsworn_stock_mkdtemp = tempfile.mkdtemp
    tempfile.mkdtemp = _mkdtemp
    tempfile._voidsworn_inherited_acl = True

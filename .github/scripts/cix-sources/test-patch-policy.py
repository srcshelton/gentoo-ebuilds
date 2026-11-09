#!/usr/bin/env python3
"""Source-specific patch replay regressions; fixtures are generated source diffs."""
import difflib
import subprocess
import tempfile
from pathlib import Path
import unittest
POLICY=Path(__file__).with_name('patch-policy.sh')
class PatchPolicyTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
  self.before=[f'line {i}\n' for i in range(40)]
  self.after=self.before.copy();self.after[15]='replacement\n'
  self.patch=self.root/'change.patch'
  self.patch.write_text(''.join(difflib.unified_diff(self.before,self.after,fromfile='a/file',tofile='b/file',n=3)))
  (self.root/'file').write_text(''.join(self.before))
 def tearDown(self):self.tmp.cleanup()
 def run_policy(self,fn):
  return subprocess.run(['bash','-c','source "$1"; "$2" "$3"','test',str(POLICY),fn,str(self.patch)],cwd=self.root,capture_output=True,text=True)
 def test_gentoo_offset_matches_normal_patch(self):
  (self.root/'file').write_text('prefix\n'+''.join(self.before))
  reference=subprocess.run(['patch','-p1','--no-backup-if-mismatch','--dry-run','-f','-i',str(self.patch)],cwd=self.root,capture_output=True)
  result=self.run_policy('apply_gentoo_patch_file')
  self.assertEqual(result.returncode,reference.returncode);self.assertEqual(result.returncode,0)
  self.assertIn('offset',result.stdout)
 def test_gentoo_fuzz_matches_normal_patch(self):
  data=self.before.copy();data[12]='changed outer context\n';(self.root/'file').write_text(''.join(data))
  reference=subprocess.run(['patch','-p1','--no-backup-if-mismatch','--dry-run','-f','-i',str(self.patch)],cwd=self.root,capture_output=True)
  result=self.run_policy('apply_gentoo_patch_file')
  self.assertEqual(result.returncode,reference.returncode);self.assertEqual(result.returncode,0)
  self.assertIn('fuzz',result.stdout)
 def test_gentoo_real_failure_is_fatal(self):
  (self.root/'file').write_text('unrelated\n');self.assertNotEqual(self.run_policy('apply_gentoo_patch_file').returncode,0)
 def test_local_offset_rejected_without_mutation(self):
  data='prefix\n'+''.join(self.before);(self.root/'file').write_text(data)
  self.assertNotEqual(self.run_policy('apply_maintained_patch_file').returncode,0)
  self.assertEqual((self.root/'file').read_text(),data)
 def test_local_fuzz_rejected(self):
  data=self.before.copy();data[12]='changed outer context\n';(self.root/'file').write_text(''.join(data))
  self.assertNotEqual(self.run_policy('apply_maintained_patch_file').returncode,0)
 def test_local_postimage_drift_rejected(self):
  self.assertEqual(self.run_policy('apply_maintained_patch_file').returncode,0)
  (self.root/'file').write_text(''.join(self.after).replace('replacement','unexpected'))
  r=subprocess.run(['bash','-c','source "$1"; maintained_patch_check "$2" --reverse','test',str(POLICY),str(self.patch)],cwd=self.root,capture_output=True)
  self.assertNotEqual(r.returncode,0)
 def test_order_preserved(self):
  second=self.after.copy();second[15]='final\n'
  p=self.root/'second.patch';p.write_text(''.join(difflib.unified_diff(self.after,second,fromfile='a/file',tofile='b/file',n=3)))
  self.assertEqual(self.run_policy('apply_gentoo_patch_file').returncode,0)
  self.patch=p;self.assertEqual(self.run_policy('apply_maintained_patch_file').returncode,0)
  self.assertEqual((self.root/'file').read_text(),''.join(second))
 def test_harness_routes_in_unpack_and_prepare_order(self):
  import tarfile
  harness=POLICY.with_name('create-patched-kernel.sh').read_text().split('\nforce=no\n')[0]
  (self.root/'functions.sh').write_text(harness)
  paths=[self.root/'archive/1000.patch', self.root/'work/cix-linux-main-test/vendor.patch',
         self.root/'files/local.patch', self.root/'files/final.patch']
  states=[self.before]
  for i,path in enumerate(paths):
   after=states[-1].copy();after[15]=f'stage {i}\n'
   path.parent.mkdir(parents=True,exist_ok=True)
   path.write_text(''.join(difflib.unified_diff(states[-1],after,fromfile='a/file',tofile='b/file',n=3)))
   states.append(after)
  with tarfile.open(self.root/'gen.tar','w') as tf:tf.add(paths[0],arcname='1000.patch')
  script = r"""set -euo pipefail
source "$1"
source "$2"
FILESDIR="$PWD/files"; WORKDIR="$PWD/work"; T="$PWD/tmp"; mkdir "$T"
EGIT_CIX_COMMIT=test; stop_before_patch=''
record_patch_file() { printf '%s\n' "$2" >> sequence; }
apply_patch_archive "$PWD/gen.tar" gentoo-genpatches:test
PATCHES=("$FILESDIR/final.patch")
src_prepare() {
 eapply "$WORKDIR/cix-linux-main-test/vendor.patch"
 eapply "$FILESDIR/local.patch"
 kernel-2_src_prepare
}
src_prepare
"""
  r=subprocess.run(['bash','-c',script,'test',str(self.root/'functions.sh'),str(POLICY)],cwd=self.root,capture_output=True,text=True)
  self.assertEqual(r.returncode,0,r.stdout+r.stderr)
  self.assertEqual((self.root/'sequence').read_text().splitlines(),['gentoo-genpatches:test','cix:test','overlay','overlay'])
  self.assertEqual((self.root/'file').read_text(),''.join(states[-1]))
if __name__=='__main__':unittest.main()

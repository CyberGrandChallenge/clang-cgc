#!/usr/bin/python

import os
import unittest
import subprocess

class CGCOS(unittest.TestCase):

    #previously installed binary
    #path = "/usr/i386-linux-cgc/bin"

    #build binary
    path = "../Release+Asserts/bin"

    #if doing a Debug build, default for svn checkoutdir
    #path = "../Debug+Asserts/bin"
 
    def setUp(self):
        self._cwd = os.getcwd()
        dirname = os.path.dirname(__file__)
        if dirname:
            os.chdir(dirname)
        self.run_cmd(['make', 'clean'])
        self.run_cmd(['make'])

    def run_cmd(self, cmd):
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return p.communicate()

    #make sure repo information didn't make it in
    def test_nosvn(self):
        #probably could pipe to strings or something
        #should NOT using strings directly with binary as an argument
	results = self.run_cmd(['cat', os.path.join('.', 'tester')])
        self.assertIn("clang-cgc", results[0])
        self.assertNotIn("svn/svn", results[0])
        self.assertNotIn("infrastructure", results[0])
        self.assertNotIn("(tags/", results[0])

    #quick test to ensure we're looking are the correct clang
    def test_is_correct_clang(self):
	results = self.run_cmd([os.path.join(self.path,'clang'), '--version'])
        self.assertIn("clang-cgc", results[0])

    #similar, but from the clang binary.  
    def test_clangver(self):
	results = self.run_cmd([os.path.join(self.path,'clang'), '--version'])
        self.assertNotIn("svn/svn", results[0])
        self.assertNotIn("infrastructure", results[0])
        self.assertNotIn("(tags/", results[0])


if __name__ == '__main__':
    unittest.main()


# -*- coding: utf-8 -*-
#
# Copyright 2015-2015 Spotify AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.









import datetime
import time

import luigi


class Bar(luigi.Task):
    task_namespace = 'examples'
    num = luigi.IntParameter()
    ts = luigi.Parameter('_')

    def run(self):
        time.sleep(100)
        self.output().open('w').close()

    def output(self):
        return luigi.LocalTarget('/tmp/bar/%s/%d' % (self.ts, self.num))



class EntryPoint(luigi.Task):
    task_namespace = 'examples'

    def run(self):
        print("Running EntryPoint")

    def requires(self):
        for i in range(100):
            yield Bar(i)

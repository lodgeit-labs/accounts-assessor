optimization and parallelization of automated testing
=====


## things we can expect to do in near future:

### testing of python div7a

### testing of prolog div7a
- it's now taking ~10 hours of 24core work just for testing passthrough of div7a tasks from prolog to python, cpu-bound, most time being taken up by swipl (just interfacing..)

### testing of ledger endpoint
- long running tasks
- even with just some 100 saved testcases,
- and a couple big private ones
- we're looking at hours of single-thread runtime, and hour long singular tasks
- multiply by ~10 for various permutations of worker configuration

### more general reasoner testing
- also lots of small jobs, and some big jobs too
- running either as:
    - remote-able services. kinda like robust already is.
    - ?






## ideas, roughly sorted by profitability:




* try to merge small luigi tasks into one, like immediate xml prepare/result/evaluate tasks.




* run multiple separate robust instances on multiple machines, and have the runner decide on a concrete machine only in the last step -
    - not sure what the criterion would be, maybe have a rest endpoint in frontend that returns the length of the queue
    - use luigi resources - dont have big ledger jobs go to small-ram machines - https://github.com/lodgeit-labs/accounts-assessor/commit/49bda4418f43481f1223397d177f81e0e6ddca6d




* implement non-backtracking doc. This will cut runtime of long ledger jobs at least in half, maybe a lot more.
    - this is the easiest




* prefilter incoming rdf data:
  * avoid unnecessary template and example(!!) data
    * some of this should be filtered by graph on client / in c#
    * maybe some more can be deleted from doc memory during swipl runtime
    - we can run a mode where cell metadata (locations) are deleted - filter them by graph again - error messages will be less helpful
    - disable context trace
  * we should do this at some point at any case





* actually implement the "rpc server" part of the worker->prolog workflow, rather than loading up a fresh swipl with all code for each invocation - each python worker process would be running a single thread with a swipl process running

  - this will mainly speed up short prolog tasks, like right now just interfacing back to python, or simple div7a computation, or depreciation, hirepurchase, chat..

  - implementations:

    - -->>> seems reasonable: https://www.swi-prolog.org/packages/mqi/prologmqi.html
    - they even thought about debugging (!!)
    - worker config json can toggle between this and spawning swipl the usual way

    - probably can be done in an afternoon

  - other implementation options (meh):
    - one option could be the "pipe to swipl cli" communication mode (fragile)

    - a more robust option would be tcp piping json rpc messages, but then we have to implement all the back and forth

    - swipl http server (over unix socket maybe? otherwise have to find free listening port for each worker process and for each container in case of host network mode..)

    - notes:
        - we *could* streamline things by removing python from the picture, using some rpc/task queue / mpi client thing in prolog directly,
          but this seems a step back, given prolog's unreliability in IO, and also we have a lot of logic around spawning / managing jobs, fetching files, tmp directories, (possibly again) interfacing with triplestore,..






* distribute robust workers across a swarm
    - this should mostly work, the logic to toggle between compose and swarm is already there, just at some point i switched to compose for ease of development, so there will be some maintenance needed first.






* distribute luigi workers - have a shared filesystem across multiple machines:
    - but luigi workers don't seem to be the bottleneck, it's the swipl process, and it's the central scheduler, to some extent

    - a shared luigi workspace(robust_tests dir), along with luigi scheduler being built for this,
    - sharing a luigi workspace is a lot less throughput-intensive on the network mount, than sharing a robust_tmp dir.
      the most traffic coming from saving:

    - fetched result files
        - and this can be "virtualized", we don't have to save them, just fetch them in-memory or into a scratch tmp for immediate comparison, and just store an url in the job.json or somesuch place in the test run dir
    - input files
        - same, can be referenced by file path, (maybe with repo commit added)

    - maybe add "gitinfo" (mainly for git diff) from each worker into session dir. (generated on session start, triggered by Summary)

    - like some other schemas here, this relies on the exact same commit of the repo being checked out on all the machines, same paths for tests, ..

      - this can be easily checked by the runner (summary?..), or rather a commit should be passed as an argument (default) to summary job, propagated to individual Result tasks, and those can check the argument value against actual value:

        - actual commit that the given worker is on, also implied to be the commit of the tests directory
        
        - eventually, we'll also want to check the actual robust server commit, but it can be inferred that it's the runner commit, this would be more relevant for testing other reasoners, we can skip it altogether when running immediate xml tests, maybe at some point implement the check when running handle jobs 
   
     * this is very preferable to sharing a robust_tmp across a swarm





* for testing of python div7a, we could bypass:
  * swipl
  * worker
  * frontend
  - and talk to services directly, but then it wont even have a directory to store test.html
  - we could bypass just swipl, go from worker to services,
  - but it seems more reasonable to try to optimize the swipl jump instead of removing it entirely, if next step is gonna be reviving the swipl div7a implementation anyway





* shard luigi scheduler, have Permutations create multiple files with equally sized batches,
  then run an overseer scheduler and worker, with a luigi task that spawns a slave scheduler (with subprocess?).

  * the rest is as normal, run worker with Summary + assistant workers (maybe reasoner-specific invocations of assistantw orkers on different machiens later, but again that's the same as with single scheudelr)

  * in effect, we have a generic scheduler sharding.

  * this is gonna be somewhat problematic in hte sense that each scheduler(shard) should have its own worker instance on each machine (each core or more, really)`


  

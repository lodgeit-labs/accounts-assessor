# meta
todo: continue migrating from https://github.com/lodgeit-labs/accounts-assessor/issues/16








# new architecture with untrusted workloads and isolated workers

internetwork these "local" services with worker containers running in fly.io:
* manager
* webproxy
* csharp_services 
* download_bastion? can probably be thrown away






## file access

manager will copy files in and out of workers.

potential alternative: https://stackoverflow.com/questions/28458590/upload-files-to-s3-bucket-directly-from-a-url?rq=1











# demo server security concerns

(security concerns of other types of deployments would currently be subsumed in this overview)

Three general ways that workers can run: 
 * locally, 
 * untrusted but managed by us,
 * managed by users


## attack vectors by topic

#### malicious requests
frontend server and worker does some file retrieval and conversion before inputs are handed over to prolog

see new arch


##### /reference
covered by DOWNLOAD_BASTION

#### malicious input files
evil xlsx?

we're gonna hope there's none for now, and continue running csharp_services locally






#### malicious url references
##### /reference
covered by DOWNLOAD_BASTION or webproxy
##### as taxanomy url in ledger request file
The process is controlled by arelle, and is quite complex. The http layer is urllib.
The only security measure that will be in place is setting a proxy envvar, so that these urls cannot poke the local network.
The whole process should be sandboxed.

new arch: this is a helper api in worker. Proxy var will be set, but the security measure is in restricting the network access of untrusted worker machines.


#### overtaking of worker container
this might be possible mainly through vulnerabilities in swipl. The worker container should be controlled by a trusted worker_proxy, which would be the one connecting to rabbitmq, spawning it to process a job, and killing it afterwards and also after a timeout. Worker container itself might get all info in an env var.

#### services


##### /post_div7a
##### /post_div7a2
##### /shell
this is probably only used for symlinking within job tmp dir.
##### /arelle_extract
##### /xml_xsd_validator
not much risk here, will just make sure this is forced to use proxy.






## ephemeral workers
* only access to own job tmp director
* ideally would have its own "services" queue to do:
* * shell (or shell can be handled by swipl), 
* * arelle_extract
* * xml_xsd_validator
* * input file conversion



### manager
thread pool for remoulade actors
pool of available workers .... (in case of not using fly.io)


### fly.io alternatives


#### docker helper
process running outside the stack, relaying information of worker container creation and destruction, and taking commands of container restarts

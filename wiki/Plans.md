## user accounts, authentication





## access control

an authorization token will be passed from frontend server to worker - 
this can only be in form of a function parameter of a field of a message.
- this is a fairly weak link wrt trying to keep the token secret.
-  - the fallout of this will be mitigated by the fact that it will not be possible to force robust to use a different token than the one coming from the frontend server.
- but an implication is that the token must not be used for authorizing access to resources outside of the stack, like add-on services running on different servers 
..so, it's pretty much just userid.

userid = auth_service + '_' + user_id

with open(request_tmp_directory_path / '.userid', 'w') as f:
    f.write(userid)
    
https://12factor.net/



## security

a public-facing service with a lot of experimental code will be hackable (for example through stack-smashing vulnerabilities in swi-pl). But confer also Row-hammer. There is only so much that can be done to protect sensitive data on shared instances. On-prem and personal instances are already possible, the code is open-source. A mixed isolation model, where worker containers are spawned per-user or per-task, would also be possible to implement.


## file-retrieval bastion
I'm surprised this doesn't exist as SaaS yet. It would be a service that allows you to download files from the internet, without risk of malicious users using this to access your internal network, the hosting server, or other containers. Rate-limiting should also be implemented.

It would be triggered by an api call like /download?userid=xxx,destination=yyy,url=zzzz
We will achieve the network isolation by running this service in a separate docker-compose stack.


## div7a GPT

multi-year input and output:

loan year
opening balance year
calculation year




## optimization
### non-backtracking doc
tests2/runner/docs/parallelization.md:47
### prologmqi
tests2/runner/docs/parallelization.md:71




## depreciation
verify functionality at least without pools. gpt it?
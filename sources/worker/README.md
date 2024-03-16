"worker" is a work-in-progress. It will be a replacement for the current "workers" container. The reason is a radical change in architecture. The new architecture will allow protection against malicious workloads by using a self-contained and self-sufficient single container worker, managed by a new "manager" container.

The worker container will be able to run both as a docker container in a local deployment (for trusted workloads), and as a fly.io "machine" (for untrusted workloads).


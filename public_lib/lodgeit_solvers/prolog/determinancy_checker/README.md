### terminology
adapted from: https://stackoverflow.com/questions/39804667/has-the-notion-of-semidet-in-prolog-settled :
```
have exactly one solution,
	then that mode is deterministic (det);
	!
either have no solutions or have one solution,
	then that mode is semideterministic (semidet);
	?
have at least one solution but may have more,
	then that mode is multisolution (multi);
	+
	seems to be a rare case, not implemented.
have zero or more solutions,
	then that mode is nondeterministic (nondet);
	this is the default, nothing to check.
```

### alternatives: 
	rdet: uses goal expansion, which is imo pretty broken. see docs/rdet.txt . Main difference between rdet and this is that with rdet, you declare determinancy of a predicate, while with this, you declare determinancy of a call.

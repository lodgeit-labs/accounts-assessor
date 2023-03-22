attempting to represent numbers and mathematical operations with CLP-FD and -Q.
The takeaway is that the only workable method for now is:
* represent numbers as rationals, 
* rely on CLPFD, but carefully, because it has bugs
* where required, express limits by applying > and < clpq constraints. More explicit limit arithmetic is too complex for the clp libs.

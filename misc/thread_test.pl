:- b_setval(xxx, xxx).

omg :- 
	open(fo, read, Fo),
	read_term(Fo, X,[]),
	open(X,write,Out_Stream),
	writeq(Out_Stream, bananana),
	close(Out_Stream),
	thread_signal(main, throw(xxx)),
	omg.
	
:- thread_create(omg, Id).

x :- findall(X,(between(0,999999999999999999999999999999,X),b_setval(xxx,X),between(0,999999,X)),_).




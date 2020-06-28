#! /bin/sh
# findall(x,(pack_install(tap,O); pack_install(regex,O); 
swipl -g "O=[interactive(false)],findall(x,(pack_install('https://github.com/koo5/fnotation.git',O)),Xs)."

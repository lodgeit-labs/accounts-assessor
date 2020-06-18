#! /bin/sh
swipl -g "O=[interactive(false)],findall(x,(pack_install(tap,O); pack_install(regex,O); pack_install('https://github.com/jonakalkus/xsd/archive/v0.2.0.zip',O); pack_install('https://github.com/rla/rdet.git',O); pack_install(fnotation,O)),Xs)."

#!/bin/bash

# not needed anymore:
# findall(x,(pack_install(tap,O); pack_install(regex,O); 

# only needed:
# swipl -g "O=[interactive(false)],findall(x,(pack_install('https://github.com/koo5/fnotation.git',O)),Xs)."
# yea this is NOT fixed: https://github.com/SWI-Prolog/swipl-devel/issues/482

mkdir -p ~/.local/share/swi-prolog/pack
cd ~/.local/share/swi-prolog/pack
git clone https://github.com/koo5/fnotation.git


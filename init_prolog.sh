#! /bin/sh
swipl -g "findall(_,(pack_install(tap); pack_install(regex); pack_install('https://github.com/jonakalkus/xsd/archive/v0.2.0.zip'); pack_install('https://github.com/rla/rdet.git'); pack_install(fnotation)),_)."

#! /bin/sh
swipl -g "pack_install(tap), pack_install(regex), pack_install(xsd), pack_install('https://github.com/rla/rdet.git'), pack_install(fnotation)."

#!/usr/bin/python3 -tt
# -*- coding: utf-8 -*-


from twisted.logger import Logger, FileLogObserver, globalLogPublisher, formatEventAsClassicLogText, LogBeginner, LogPublisher
import sys
# globalLogPublisher.addObserver(FileLogObserver(sys.stderr, formatEventAsClassicLogText))
__all__ = ['Logging']


class Logging:
    log = None
    # log = Logger(namespace="Uninitialized")

    def __init__(self):
        self.log = Logger(namespace=self.logPrefix())
        print("Starting log for", self.logPrefix())

    def logPrefix(self):
        return '-|-'

    def dbg(self, text, *args, **kw):
        # noinspection PyArgumentList
        return self.log.debug(text, *args, **kw)

    def msg(self, text, *args, **kw):
        # noinspection PyArgumentList
        return self.log.info(text, *args, **kw)

    def err(self, *args, **kw):
        return self.log.error(*args, **kw)


class LoggerWriter:
    _buffer = ''

    def __init__(self, level):
        """ level: the logger callable. rename?. """
        # self.level is really like using log.debug(message)
        # at least in my case
        self.level = level

    def write(self, message):
        self._buffer += str(message)
        while '\n' in self._buffer:
            msg, self._buffer = self._buffer.split('\n', 1)
            self.level("{msg}", msg=msg)

    def flush(self):
        # create a flush method so things can be flushed when
        # the system wants to. Not sure if simply 'printing'
        # sys.stderr is the correct way to do it, but it seemed
        # to work properly for me.
        #         self.level(sys.stderr)
        self.level("Flush")


# vim:set sw=4 ts=4 et:

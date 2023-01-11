#!/usr/bin/env python3

from twisted.internet import reactor
from common import tzmq
from twisted.internet import defer
from pprint import pprint


class SMCliZmqFactory(tzmq.Subscriber):

    _websocket = None
    status = None
    publisher = None

    def __init__(self, identity=None):
        super().__init__(identity="%s-srv" % identity)
        self.status = {'power': None, 'mute': None}
        self._old_status = None
        self.connect("ipc:///tmp/%s.pub" % identity)
        self.publisher = tzmq.Publisher(identity="%s-srv" % identity)
        self.publisher.connect("ipc:///tmp/%s.rpc" % identity)

    def on_message(self, message):
        #print("message:",message)
        self.status = message
        self.notify()

    def do_get_status(self):
        #         print("Getstatus")
        self.publisher.send({'request': 'refresh'})

    def get_status(self):
        return self.status

    def notify(self):
        self._client.notify(self.status)

    def stop_service(self, param):
        self.send_cmd("stop-service", param)

    def start_service(self, param):
        self.send_cmd("start-service", param)

    def send_cmd(self, request, param=None):
        self.publisher.send({'request': request, 'param': param})

    def set_power(self, power: str) -> defer.Deferred:
        self.send_cmd('set-power', power)
        return defer.Deferred().callback(True)


class cli_process(SMCliZmqFactory):
    def __init__(self, argv):
        self.argv = argv
        self.sm = SMCliZmqFactory(identity="servicemanager")
        self.sm._client = self
        reactor.callLater(1, self.parseargs)

    def parseargs(self):
        #         print(self.argv)
        argv = self.argv[1:]
        if argv:
            if argv[0] == 'list':
                self.get_list()
            if argv[0] == 'stop':
                self.stop_service(argv[1])
            if argv[0] == 'start':
                self.start_service(argv[1])

    def get_list(self):
        self.sm.do_get_status()

    def stop_service(self, service):
        self.sm.stop_service(service)

    def start_service(self, service):
        self.sm.start_service(service)

    def notify(self, status):
        print("Status:")
        pprint(status)
        reactor.stop()

if __name__ == "__main__":
    import sys
    sm = cli_process(sys.argv)
    reactor.run()

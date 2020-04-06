#!/usr/bin/python3 -tt
# -*- coding: utf-8 -*-

from twisted.internet import reactor
from twisted.internet.interfaces import IFileDescriptor, IReadDescriptor
from zope.interface import implementer
from simplejson import loads, dumps
from time import time
from uuid import uuid4

import zmq


__all__ = ['Router']


@implementer(IReadDescriptor, IFileDescriptor)
class Zmq(object):
    """
    Twisted-compatible ZMQ router.
    """
    _zmq_type = None

    def __init__(self, identity=None):
        """
        Prepares ZMQ socket.

        You can supply an identity to be able to bootstrap communication
        by sending messages to well-known participants.  Participants
        sending most messages to a single recipient can set it as default
        as ommit it's name when calling the send method.

        Every message contains a timestamp that is checked by recipient.
        If the time difference is larger than 15 seconds, message is dropped.
        Make sure your machines use NTP to synchronize their clocks.
        """

        # Create the 0MQ socket.
        self.socket = zmq.Context.instance().socket(self._zmq_type)

        # Assume either user-specified identity or generate our own.
        if identity is not None:
            self.socket.setsockopt_string(zmq.IDENTITY, identity)
        else:
            self.socket.setsockopt_string(zmq.IDENTITY, uuid4().hex)

        # Register ourselves with Twisted reactor loop.
        reactor.addReader(self)

    def fileno(self):
        return self.socket.getsockopt(zmq.FD)

    def shutdown(self):
        reactor.removeReader(self)
        self.socket.close()

    def connectionLost(self, reason):
        pass

    def doRead(self):
        #         print("DoReadStart")
        events = self.socket.getsockopt(zmq.EVENTS)
#         print(events)
#         print(self.socket.poll(timeout=5))
        if events & zmq.POLLIN:

            while True:
                #             if True:
                try:
                    self.on_multipart_message(self.socket.recv_multipart(zmq.NOBLOCK))
#                     break
                except zmq.ZMQError as e:
                    if e.errno == zmq.EAGAIN:
                        break
                    raise
#             else:
#                 break
#         print("DoReadEnd")
#         return None
        else:
            print("ZMQ Event:", self._zmq_type, events)

    def connect(self, address):
        """Connects to ZMQ endpoint."""
        self.socket.connect(address)
        return self

    def bind(self, address):
        """Binds as ZMQ endpoint."""
        self.socket.bind(address)
        return self

    def on_multipart_message(self, message):
        self.on_message(loads(message[0].decode('UTF-8')))

    def on_message(self, message):
        """Method called for every received message. Override."""
        raise NotImplementedError('You need to override on_message()')

    def send_multipart(self, multipart_message):
        self.socket.send_multipart(multipart_message)
        # Check for potential replies.
        # This is absolutely essential to do, because Twisted is going to
        # miss replies received during the send_multipart() above.
        reactor.callLater(0, self.doRead)

    def logPrefix(self):
        return 'tzmq'


class Router(Zmq):
    _zmq_type = zmq.ROUTER
    default_recipient = None

    def __init__(self, identity=None, default_recipient=None):
        super().__init__(identity)
        # Hand over socket when peer relocates.
        # This means that we trust peer identities.
        self.socket.setsockopt(zmq.ROUTER_HANDOVER, 1)

        # Remember the default recipient.
        self.default_recipient = None
        if default_recipient is not None:
            if not isinstance(default_recipient, bytes):
                self.default_recipient = default_recipient.encode('utf-8')
            else:
                self.default_recipient = default_recipient

    def send(self, message, recipient=None):
        """Send message to specified peer."""

        # If recipient have not been specified, use the default one.
        if recipient is None:
            # But fail if no default have been set.
            if self.default_recipient is None:
                raise TypeError('no recipient specified')

            # Otherwise just use the default and save user some work.
            recipient = self.default_recipient

        else:
            if not isinstance(recipient, bytes):
                recipient = recipient.encode('utf-8')

        # JSON-encode the message.
        json = dumps(message, for_json=True).encode('utf-8')

        # Get current time as a byte sequence.
        now = str(int(time())).encode('utf-8')

        # Send the message.
        self.send_multipart([recipient, json, now])

    def on_multipart_message(self, message):
        sender, data, t = message
        if int(t) + 15 < time():
            pass
        else:
            self.on_message(loads(data), sender)

    def on_message(self, message, sender):
        """Method called for every received message. Override."""
        raise NotImplementedError('You need to override on_message()')

    def logPrefix(self):
        return 'tzmq-router'


# noinspection PyPep8Naming
class Router_wt(Router):

    def on_multipart_message(self, message):
        sender, data = message
        self.on_message(loads(data), sender)

    def send(self, message, recipient=None):
        """Send message to specified peer."""

        # If recipient have not been specified, use the default one.
        if recipient is None:
            # But fail if no default have been set.
            if self.default_recipient is None:
                raise TypeError('no recipient specified')

            # Otherwise just use the default and save user some work.
            recipient = self.default_recipient

        else:
            if not isinstance(recipient, bytes):
                recipient = recipient.encode('utf-8')

        # JSON-encode the message.
        json = dumps(message, for_json=True).encode('utf-8')

        # Send the message.
        self.send_multipart([recipient, json])


class Publisher(Zmq):
    _zmq_type = zmq.PUB

    def logPrefix(self):
        return 'tzmq-publisher'

    def send(self, message):
        self.socket.send_json(message)

    def on_message(self, message):
        pass


class Rep(Zmq):
    _zmq_type = zmq.REP

    def logPrefix(self):
        return 'tzmq-rep'

    def send(self, message):
        self.socket.send_json(message)


class Subscriber(Zmq):
    _zmq_type = zmq.SUB

    def __init__(self, identity=None, default_recipient=None):
        super().__init__(identity)
        self.socket.setsockopt(zmq.SUBSCRIBE, b"")


if __name__ == '__main__':
    server = Router(identity='server')
    server.bind('tcp://127.0.0.1:4321')

    client = Router(default_recipient='server')
    client.connect('tcp://127.0.0.1:4321')

    def client_received(msg, sender):
        print('client received', msg)
        print('stopping reactor')
        reactor.stop()

    def server_received(msg, sender):
        print('server received', msg)
        print('sending reply')
        server.send({'client_to': msg, 'message': 'hello'}, sender)

    client.on_message = client_received
    server.on_message = server_received

    def start():
        client.send({'title': 'how are you?'})

    reactor.callLater(1, start)
    reactor.run()


# vim:set sw=4 ts=4 et:

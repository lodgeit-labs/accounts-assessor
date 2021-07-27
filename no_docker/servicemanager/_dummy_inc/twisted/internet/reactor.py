import twisted.internet.error


def __init__():
    """
    Initialize epoll object, file descriptor tracking dictionaries, and the
    base class.
    """


def _add(xer, primary, other, selectables, event, antievent):
    """
    Private method for adding a descriptor from the event loop.

    It takes care of adding it if  new or modifying it if already added
    for another state (read -> read/write for example).
    """


def _cancelCallLater(tple):
    """ No Help :-( """


def _checkProcessArgs(args, env):
    """
    Check for valid arguments and environment to spawnProcess.

    @return: A two element tuple giving values to use when creating the
    process.  The first element of the tuple is a C{list} of C{bytes}
    giving the values for argv of the child process.  The second element
    of the tuple is either L{None} if C{env} was L{None} or a C{dict}
    mapping C{bytes} environment keys to C{bytes} environment values.
    """


def _disconnectSelectable(selectable, why, isRead, faildict={twisted.internet.error.ConnectionDone, twisted.internet.error.ConnectionLost}):
    """
    Utility function for disconnecting a selectable.

    Supports half-close notification, isRead should be boolean indicating
    whether error resulted from doRead().
    """


def _doReadOrWrite(selectable, fd, event):
    """
    fd is available for read or write, do the work and raise errors if
    necessary.
    """


def _handleSignals():
    """
    Extend the basic signal handling logic to also support
    handling SIGCHLD to know when to try to reap child processes.
    """


def _initThreadPool():
    """
        Create the threadpool accessible with callFromThread.
        """


def _initThreads():
    """ No Help :-( """


def _insertNewDelayedCalls():
    """ No Help :-( """


def _moveCallLaterSooner(tple):
    """ No Help :-( """


def _reallyStartRunning():
    """
    Extend the base implementation by also installing signal handlers, if
    C{self._installSignalHandlers} is true.
    """


def _remove(xer, primary, other, selectables, event, antievent):
    """
    Private method for removing a descriptor from the event loop.

    It does the inverse job of _add, and also add a check in case of the fd
    has gone away.
    """


def _removeAll(readers, writers):
    """
    Remove all readers and writers, and list of removed L{IReadDescriptor}s
    and L{IWriteDescriptor}s.

    Meant for calling from subclasses, to implement removeAll, like::

      def removeAll(self):
          return self._removeAll(self._reads, self._writes)

    where C{self._reads} and C{self._writes} are iterables.
    """


def _stopThreadPool():
    """
        Stop the reactor threadpool.  This method is only valid if there
        is currently a threadpool (created by L{_initThreadPool}).  It
        is not intended to be called directly; instead, it will be
        called by a shutdown trigger created in L{_initThreadPool}.
        """


def _uninstallHandler():
    """
    If a child waker was created and installed, uninstall it now.

    Since this disables reactor functionality and is only called
    when the reactor is stopping, it doesn't provide any directly
    useful functionality, but the cleanup of reactor-related
    process-global state that it does helps in unit tests
    involving multiple reactors and is generally just a nice
    thing.
    """


def addReader(reader):
    """
    Add a FileDescriptor for notification of data available to read.
    """


def addSystemEventTrigger(_phase, _eventType, _f, *args, **kw):
    """See twisted.internet.interfaces.IReactorCore.addSystemEventTrigger.
    """


def addWriter(writer):
    """
    Add a FileDescriptor for notification of data available to write.
    """


def adoptDatagramPort(fileDescriptor, addressFamily, protocol, maxPacketSize=8192):
    """ No Help :-( """


def adoptStreamConnection(fileDescriptor, addressFamily, factory):
    """
    @see:
        L{twisted.internet.interfaces.IReactorSocket.adoptStreamConnection}
    """


def adoptStreamPort(fileDescriptor, addressFamily, factory):
    """
    Create a new L{IListeningPort} from an already-initialized socket.

    This just dispatches to a suitable port implementation (eg from
    L{IReactorTCP}, etc) based on the specified C{addressFamily}.

    @see: L{twisted.internet.interfaces.IReactorSocket.adoptStreamPort}
    """


def callFromThread(f, *args, **kw):
    """
        See
        L{twisted.internet.interfaces.IReactorFromThreads.callFromThread}.
        """


def callInThread(_callable, *args, **kwargs):
    """
        See L{twisted.internet.interfaces.IReactorInThreads.callInThread}.
        """


def callLater(_seconds, _f, *args, **kw):
    """See twisted.internet.interfaces.IReactorTime.callLater.
    """


def callWhenRunning(_callable, *args, **kw):
    """See twisted.internet.interfaces.IReactorCore.callWhenRunning.
    """


def connectSSL(host, port, factory, contextFactory, timeout=30, bindAddress=None):
    """ No Help :-( """


def connectTCP(host, port, factory, timeout=30, bindAddress=None):
    """ No Help :-( """


def connectUNIX(address, factory, timeout=30, checkPID=0):
    """ No Help :-( """


def connectUNIXDatagram(address, protocol, maxPacketSize=8192, mode=438, bindAddress=None):
    """
    Connects a L{ConnectedDatagramProtocol} instance to a path.

    EXPERIMENTAL.
    """


def crash():
    """
    See twisted.internet.interfaces.IReactorCore.crash.

    Reset reactor state tracking attributes and re-initialize certain
    state-transition helpers which were set up in C{__init__} but later
    destroyed (through use).
    """


def disconnectAll():
    """Disconnect every reader, and writer in the system.
    """


def doPoll(timeout):
    """
    Poll the poller for new events.
    """


def fireSystemEvent(eventType):
    """See twisted.internet.interfaces.IReactorCore.fireSystemEvent.
    """


def getDelayedCalls():
    """
    Return all the outstanding delayed calls in the system.
    They are returned in no particular order.
    This method is not efficient -- it is really only meant for
    test cases.

    @return: A list of outstanding delayed calls.
    @type: L{list} of L{DelayedCall}
    """


def getReaders():
    """ No Help :-( """


def getThreadPool():
    """
        See L{twisted.internet.interfaces.IReactorThreads.getThreadPool}.
        """


def getWriters():
    """ No Help :-( """


def installNameResolver(resolver):
    """
    See L{IReactorPluggableNameResolver}.

    @param resolver: See L{IReactorPluggableNameResolver}.

    @return: see L{IReactorPluggableNameResolver}.
    """


def installResolver(resolver):
    """
    See L{IReactorPluggableResolver}.

    @param resolver: see L{IReactorPluggableResolver}.

    @return: see L{IReactorPluggableResolver}.
    """


def installWaker():
    """
    Install a `waker' to allow threads and signals to wake up the IO thread.

    We use the self-pipe trick (http://cr.yp.to/docs/selfpipe.html) to wake
    the reactor. On Windows we use a pair of sockets.
    """


def iterate(delay=0):
    """See twisted.internet.interfaces.IReactorCore.iterate.
    """


def listenMulticast(port, protocol, interface='', maxPacketSize=8192, listenMultiple=False):
    """Connects a given DatagramProtocol to the given numeric UDP port.

    EXPERIMENTAL.

    @returns: object conforming to IListeningPort.
    """


def listenSSL(port, factory, contextFactory, backlog=50, interface=''):
    """ No Help :-( """


def listenTCP(port, factory, backlog=50, interface=''):
    """ No Help :-( """


def listenUDP(port, protocol, interface='', maxPacketSize=8192):
    """Connects a given L{DatagramProtocol} to the given numeric UDP port.

    @returns: object conforming to L{IListeningPort}.
    """


def listenUNIX(address, factory, backlog=50, mode=438, wantPID=0):
    """ No Help :-( """


def listenUNIXDatagram(address, protocol, maxPacketSize=8192, mode=438):
    """
    Connects a given L{DatagramProtocol} to the given path.

    EXPERIMENTAL.

    @returns: object conforming to L{IListeningPort}.
    """


def mainLoop():
    """ No Help :-( """


def removeAll():
    """
    Remove all selectables, and return a list of them.
    """


def removeReader(reader):
    """
    Remove a Selectable for notification of data available to read.
    """


def removeSystemEventTrigger(triggerID):
    """See twisted.internet.interfaces.IReactorCore.removeSystemEventTrigger.
    """


def removeWriter(writer):
    """
    Remove a Selectable for notification of data available to write.
    """


def resolve(name, timeout=(1, 3, 11, 45)):
    """Return a Deferred that will resolve a hostname.
    """


def run(installSignalHandlers=True):
    """ No Help :-( """


def runUntilCurrent():
    """
    Run all pending timed calls.
    """


def sigBreak(*args):
    """
    Handle a SIGBREAK interrupt.

    @param args: See handler specification in L{signal.signal}
    """


def sigInt(*args):
    """
    Handle a SIGINT interrupt.

    @param args: See handler specification in L{signal.signal}
    """


def sigTerm(*args):
    """
    Handle a SIGTERM interrupt.

    @param args: See handler specification in L{signal.signal}
    """


def spawnProcess(processProtocol, executable, args=(), env={}, path=None, uid=None, gid=None, usePTY=0, childFDs=None):
    """ No Help :-( """


def startRunning(installSignalHandlers=True):
    """
    Extend the base implementation in order to remember whether signal
    handlers should be installed later.

    @type installSignalHandlers: C{bool}
    @param installSignalHandlers: A flag which, if set, indicates that
        handlers for a number of (implementation-defined) signals should be
        installed during startup.
    """


def stop():
    """
    See twisted.internet.interfaces.IReactorCore.stop.
    """


def suggestThreadPoolSize(size):
    """
        See L{twisted.internet.interfaces.IReactorThreads.suggestThreadPoolSize}.
        """


def timeout():
    """
    Determine the longest time the reactor may sleep (waiting on I/O
    notification, perhaps) before it must wake up to service a time-related
    event.

    @return: The maximum number of seconds the reactor may sleep.
    @rtype: L{float}
    """


def wakeUp():
    """
    Wake up the event loop.
    """

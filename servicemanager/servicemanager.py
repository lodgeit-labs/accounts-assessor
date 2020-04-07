#!/usr/bin/env python3

from twisted.internet import reactor, protocol, defer, error
from common.logging import Logging, LoggerWriter
from common import tzmq
from twisted import logger
import os
import configparser
from json import loads
from twisted.python import usage
import sys
import yaml
import shlex
import signal
SM_VERSION = 0.1

class ServiceLogger:
    """ manages logging of stdout and stderr of a service """
    filename = ''
    fd = None
    buffer = None

    def __init__(self, filename):
        self.buffer = []
        self.filename = filename
        self.fd = open(self.filename, "a")

    def stdout(self, data):
        self.fd.write(data)
        self.fd.flush()

    def stderr(self, data):
        self.fd.write(data)
        self.fd.flush()


class Service(protocol.ProcessProtocol, Logging):
    name = ''
    executable = ''
    args = None
    desired_state = False
    state = False
    manager = None
    stop_pending = None
    start_pending = None
    sclog = None
    dir = None
    _exitCode = 0

    def __init__(self, service_config):
        Logging.__init__(self)


        self.args=[]
        if 'args' in service_config:
            if service_config['args']:
                self.args = service_config['args']
		# simply just self.args = service_config.get('args', []) ?


        self.executable = service_config['exec']
        self.name = service_config['name']
        self.dir = service_config['dir']

    # twisted callbacks:

    def outReceived(self, data):
        lines = data.decode().split(os.linesep)
        if self.sclog:
            for line in lines:
                self.sclog.stdout(self.name + " STDOUT:" + line + os.linesep)

    def errReceived(self, data):
        lines = data.decode().split(os.linesep)
        if self.sclog:
            for line in lines:
                self.sclog.stderr(self.name + " STDERR:" + line + os.linesep)
	
	# sending signals to services 

    def sigKill(self):
        self.transport.signalProcess('KILL')

    def sigInt(self):
        self.transport.signalProcess('INT')



    def processExited(self, reason):
        self.state = False
        self.msg("{service} processExited {msg}", msg=reason, service=self.name)
#         try:
#             self._exitCode = reason.value.exitCode
#         except Exception as e:
#             print("Exception Exitcode not found for %s" % self.name)
#             print(e)
#             print(reason.value)

    def processEnded(self, reason):
        self.state = False
        self.msg("{service} processEnded {msg}", msg=reason, service=self.name)
        #         self.msg("processEnded, status %s" % (str(reason.value.exitCode),))
        self._exitCode = reason.value.exitCode

        if self.stop_pending:
            if isinstance(reason.value, error.ProcessDone):
                self.stop_pending.callback(True)
            else:
                self.stop_pending.callback(reason.value)
            self.stop_pending = None
        self.check_state()

    def check_state(self):
        if self.state != self.desired_state:
            self.set_state(self.desired_state)

    def set_state(self, state):
        if state:
            return self.start()
        else:
            return self.stop()

    def get_state(self):
        return self.state

    def start(self):
        if self.start_pending:
            return self.start_pending

        d = defer.Deferred()

        if self.state:
            d.callback(True)
            self.start_pending = None
        else:
            self.desired_state = True
            self.start_pending = d
            reactor.spawnProcess(self, self.executable, [self.executable] + self.args, os.environ, self.dir)

        return d

    def stop(self):
        if self.stop_pending:
            return self.stop_pending

        d = defer.Deferred()

        if self.state:
            self.desired_state = False
            self.sigInt()
            self.stop_pending = d
            return self.stop_pending
        else:
            self.stop_pending = None

            d.callback(True)
            return d

    def logPrefix(self):
        return "Service " + self.name + ":"

    def connectionMade(self):
        self.msg("Connection Made %s" % self.start_pending)
        self.state = True
        if self.start_pending:
            self.start_pending.callback(True)
            self.start_pending = None

    def __repr__(self):
        return "<%s at %s state='%s', name='%s', executable='%s' args='%s'>" % \
            (self.__class__.__name__, hex(id(self)), str(self.state), self.name, self.executable, str(self.args))

    def get_info(self):
        return {"name": self.name, "state": self.state, "desired_state": self.desired_state, "executable": self.executable, "args": self.args}


class PythonService(Service):

    def __init__(self, service_config):
        Service.__init__(self, service_config)
        self.executable = service_config['python_interpreter']
        self.args = ['-m', service_config['exec']]
        if 'args' in service_config:
            self.args += service_config['args']

class StartedPythonService(PythonService):

    def __init__(self, *args):
        PythonService.__init__(self, *args)
        self.start()


class ServiceManager(Logging):
    services = None
    config = None
    config_section = 'pc01'
    sclog = None

    def __init__(self, log_file=None):
        super().__init__()
        self.services = []
        reactor.addSystemEventTrigger('before', 'shutdown', self.stop_services)
        self.sclog = ServiceLogger(log_file)

    def logPrefix(self):
        return 'Service Manager'

    def load_config(self, config_file, config_group=None):
        #         config = configparser.ConfigParser()
        #         config.read("services.ini")

        #         if config.has_section(self.config_section):
        #             self.config = config[self.config_section]
        y = yaml.safe_load(open(config_file))

        if 'all' in y:
            self.config = y['all']
        else:
            self.config = {}
        
        if config_group and config_group != 'all':
            if config_group in y:
                """ Zatim odlozime az se configurace vyseparuje jinam
                if 'identity' in y[config_group]:
                   self.config['identity']=y[config_group]['identity'])
                else:
                    if 'identity' not in self.config:
                        self.config['identity']=DEFAULT_IDENTITY
                """
                if 'defaults' in y[config_group]:
                    if 'defaults' not in self.config:
                        self.config['defaults'] = {}
                    self.config['defaults'].update(y[config_group]['defaults'])
                if 'services' in y[config_group]:
                    if 'services' not in self.config:
                        self.config['services'] = []
                    self.config['services'] += y[config_group]['services']
            else:
                print("Config group not found!")
                sys.exit(1)
        else:
            print("""Config group not set and "all" not found, not running anything.""")

    def load_services(self):
        self.dbg("Config: {msg}",msg=self.config)
        if 'services' in self.config:
            for serviceiter in self.config['services']:
                service_config = self.config['defaults'].copy()
                service_config.update(serviceiter)

                if 'args' in service_config:
                    if isinstance(service_config['args'], str):
                        service_config['args'] = shlex.split(service_config['args'])
                if 'type' not in service_config:
                    service_config['type'] = 'exec'

                print(service_config)
                if service_config['type'] == 'python_module':
                    service = PythonService(service_config)
                    service.sclog = self.sclog
                    self.services.append(service)
                else:
                    service = Service(service_config)
                    service.sclog = self.sclog
                    self.services.append(service)

    def start_services(self):
        print(self.services)
        for service in self.services:
            print ("Startig %s" % service.name)
            service.start()

    def stop_services(self):
        d = defer.Deferred()

        def done(*args):
            print("Services Stopped")
            reactor.callLater(2, d.callback, True)

        print("Stoping services")
        ds = []
        for service in self.services:
            ds.append(service.stop())

        dl = defer.DeferredList(ds)
        dl.addCallback(done)
        return d

    def list_services(self):
        return [service.name for service in self.services]

    def get_services_info(self):
        return [service.get_info() for service in self.services]

    def get_service_by_name(self, name):
        services = [service for service in self.services if service.name == name]
        if services:
            return services[0]
        return False

    def get_service_by_id(self, scid):
        try:
            return self.services[scid]
        except IndexError:
            return False

    def service_start(self, scid):
        if isinstance(scid, str):
            service = self.get_service_by_name(scid)
        elif isinstance(scid, int):
            service = self.get_service_by_id(scid)
        elif isinstance(scid, Service):
            service = scid

        if service:
            return service.start()
        else:
            d = defer.Deferred()
            d.errback(ValueError("Service not exist"))
            return d

    def service_stop(self, scid):
        if isinstance(scid, str):
            service = self.get_service_by_name(scid)
        elif isinstance(scid, int):
            service = self.get_service_by_id(scid)
        elif isinstance(scid, Service):
            service = scid

        if service:
            return service.stop()
        else:
            d = defer.Deferred()
            d.errback(ValueError("Service not exist"))
            return d


class SMDriver(tzmq.Subscriber):
    _publisher = None
    _sm = None
    log = None

    def __init__(self, identity=None, publisher_bind=None, config_file=None, config_group=None, log_file=None):
        self.log = logger.Logger(namespace=self.__class__.__name__)
        super().__init__()
        self._publisher = tzmq.Publisher(identity=identity)
        self.log.info("Binding socket {socket}".format(socket=publisher_bind))

        try:
            self._publisher.bind(publisher_bind)
        except Exception as e:
            self.log.critical("while trying to bind to %s:" % publisher_bind)
            self.log.critical("%s" % e)
            self.log.critical("if you are sure these sockets are stale, rm /tmp/servicemanager.*")
            exit(1)
        self._sm = ServiceManager(log_file=log_file)
        self._sm.load_config(config_file=config_file, config_group=config_group)
        self._sm.load_services()
        self._sm.start_services()

    def on_message(self, message):
        print(message)
        self.log.info("Request: {message} {msgtype}", message=message, msgtype=type(message))
        if isinstance(message, str):
            try:
                message = loads(message)
            except Exception as e:
                print("Exception:", e)
        if isinstance(message, dict):
            if 'request' in message:
                request = message['request']
                if 'param' in message:
                    param = message['param']
                else:
                    param = None

                if request == 'start-service':
                    self.start_service(param)
                elif request == 'stop-service':
                    self.stop_service(param)

                elif request == 'refresh':
                    self.notify(self._sm.get_services_info())

                elif request == 'stop':
                    self.stop_all()

    def notify(self, status):
        self.log.info("Sending message {status}", status=status)
        self._publisher.send(status)

    def stop_service(self, param):
        self._sm.service_stop(param).addCallback(lambda status: self.notify({"status": self._sm.get_services_info()}))

    def start_service(self, param):
        self._sm.service_start(param).addCallback(lambda status: self.notify({"status": self._sm.get_services_info()}))

    def stop_all(self):
        self._sm.stop_services().addCallback(lambda: self.notify({"status": self._sm.get_services_info()}))


class Options(usage.Options):
   
    optParameters = [['identity', 'i', 'servicemanager', "(Required) Identity of ZMQ driver"],
                     ['rpc-bind', 'r', None, "(Required) RPC endpoint to bind to [default: ipc://<identity>.rpc]"],
                     ['pub-bind', 'p', None, '(Required) Publisher endpoint to bind to [default: ipc://<identity>.pub]'],
                     ['config-group', 'g', 'all', '(Optional) Group of configuration'],
                     ['config', 'c', 'services.yml', 'Config file (yaml)'],
                     ['log_file', None, "SM-test.log", "Log File"]]

    optFlags =       [['group-in-identity', 'a', "Append Group name to Identity"]]

    def opt_version(self):
        """
        Display Service Manager version and exit.
        """

        print("Service Manager version:", SM_VERSION)
        sys.exit(0)

def chcip(para,metr):
	print ("CHCIP",para,metr)
	reactor.stop()

def main():
    signal.signal(signal.SIGQUIT, chcip)
    logger.globalLogPublisher.addObserver(logger.FileLogObserver(sys.stderr, logger.formatEventAsClassicLogText))

    log = logger.Logger(namespace="Service Manager Driver Print")
    config = Options()
    try:
        config.parseOptions()  # When given no argument, parses sys.argv[1:]
    except usage.UsageError as errortext:
        print ('%s: %s' % (sys.argv[0], errortext))
        print ('%s: Try --help for usage details.' % (sys.argv[0]))
        return 1
    if config['group-in-identity'] and config['config-group']:
        config['identity'] += "-" + config['config-group']
        print(config['group-in-identity'])

    if config['identity'] is None:
        print(config)

        return 1
    else:
        if config['rpc-bind'] is None:
            config['rpc-bind'] = 'ipc:///tmp/{}.rpc'.format(config['identity'])

        if config['pub-bind'] is None:
            config['pub-bind'] = 'ipc:///tmp/{}.pub'.format(config['identity'])

    sys.stdout = LoggerWriter(log.info)
    sys.stderr = LoggerWriter(log.warn)

    subs = SMDriver(publisher_bind=config['pub-bind'], identity=config['identity'], config_file=config['config'], config_group=config['config-group'], log_file=config['log_file'])
    """ Sem pak dopsat ten exception handler """
    subs.bind(config['rpc-bind'])

    reactor.run()
    return 0


if __name__ == "__main__":

    sys.exit(main())

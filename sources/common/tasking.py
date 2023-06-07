import os
# what this really controls is how many times it should try to reconnect gracefully before it starts reconnecting in an uncontrolled DOS-style loop (still true?)
os.environ['remoulade_restart_max_retries']='99999999'
import remoulade
from remoulade.brokers.rabbitmq import RabbitmqBroker
from remoulade.results.backends import RedisBackend
from remoulade.state.backends import PostgresBackend
from remoulade.results import Results
from remoulade.state.middleware import MessageState
from remoulade.cancel import Cancel
from remoulade.cancel.backends import RedisBackend as CancelBackend
from remoulade.middleware import CurrentMessage
from remoulade.scheduler import ScheduledJob, Scheduler

redis_backend = RedisBackend(url=os.environ['REDIS_HOST'])
result_time_limit_ms = 10 * 12 * 31 * 24 * 60 * 60 * 1000
broker_url="amqp://"+os.environ['RABBITMQ_URL']+"?timeout=15"
print(broker_url)
broker = RabbitmqBroker(url=broker_url)

broker.add_middleware(Results(backend=redis_backend, store_results=True, result_ttl=result_time_limit_ms))
broker.add_middleware(MessageState(PostgresBackend(url=os.environ['REMOULADE_PG_URI']), state_ttl=result_time_limit_ms))
broker.add_middleware(Cancel(backend=CancelBackend()))
broker.add_middleware(CurrentMessage())

print(broker)
remoulade.set_broker(broker)
scheduler = Scheduler(broker, [])
#scheduler = Scheduler(broker, [ScheduledJob(actor_name="ping", args=(), interval=100)])
remoulade.set_scheduler(scheduler)

#@remoulade.actor
#def ping():
#	return "pong"
#remoulade.declare_actors([ping])
#print('scheduler.start...')
#scheduler.start()

print('tasking loaded')
print()


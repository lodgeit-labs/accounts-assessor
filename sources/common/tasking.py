
import os
# what this really controls is how many times it should try to reconnect gracefully before it starts reconnecting in an uncontrolled DOS-style loop
os.environ['remoulade_restart_max_retries']='99999999'


from config import secret



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


result_backend = RedisBackend(url=os.environ['REDIS_HOST'])
result_time_limit_ms = 10 * 12 * 31 * 24 * 60 * 60 * 1000

broker = RabbitmqBroker(url="amqp://"+os.environ['RABBITMQ_URL']+"?timeout=15")
broker.add_middleware(Results(backend=result_backend, store_results=True, result_ttl=result_time_limit_ms))
broker.add_middleware(MessageState(PostgresBackend(url=os.environ['REMOULADE_PG_URI']), state_ttl=result_time_limit_ms))
broker.add_middleware(Cancel(backend=CancelBackend()))
broker.add_middleware(CurrentMessage())

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


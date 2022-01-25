
import os
# what this really controls is how many times it should try to reconnect gracefully before it starts reconnecting in an uncontrolled DOS-style loop
os.environ['emoulade_restart_max_retries']='99999999'



import remoulade
from remoulade.brokers.rabbitmq import RabbitmqBroker
from remoulade.results.backends import RedisBackend
from remoulade.state.backends import PostgresBackend
from remoulade.results import Results
from remoulade.state.middleware import MessageState


result_backend = RedisBackend()
result_time_limit_ms = 31 * 24 * 60 * 60 * 1000

rabbitmq_broker = RabbitmqBroker(url="amqp://localhost?timeout=15")
rabbitmq_broker.add_middleware(Results(backend=result_backend, store_results=True, result_ttl=result_time_limit_ms))
rabbitmq_broker.add_middleware(MessageState(PostgresBackend(), state_ttl=result_time_limit_ms))
remoulade.set_broker(rabbitmq_broker)

print('"tasking" loaded')


print()

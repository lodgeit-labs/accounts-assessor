import remoulade
from remoulade.brokers.rabbitmq import RabbitmqBroker
from remoulade.results.backends import RedisBackend
from remoulade.results import Results

result_backend = RedisBackend()
result_time_limit_ms = 31 * 24 * 60 * 60 * 1000

rabbitmq_broker = RabbitmqBroker(url="amqp://localhost")
rabbitmq_broker.add_middleware(Results(backend=result_backend, store_results=True, result_ttl=result_time_limit_ms))
remoulade.set_broker(rabbitmq_broker)



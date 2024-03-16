import sys, os

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/remoulade')))

#sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../actors')))
#import trusted_workers

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../manager')))
import app.manager_actors

from remoulade.api.main import app


from logging.config import dictConfig
from flask.logging import default_handler
app.logger.removeHandler(default_handler)


dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'console': {
        'class': 'logging.StreamHandler',
        'level': 'DEBUG',
        'filters': [],
        'stream': 'ext://sys.stdout',
        'formatter': 'default'
    }},
    'root': {
        'level': 'DEBUG',
        'handlers': ['console']
    }
})



if __name__ == "__main__":
    # the port 5005 is the default port read by super-bowl
    app.run(host="localhost", port=5005)


from grakn.client import GraknClient

with GraknClient(uri="localhost:48555") as client:
    with client.session(keyspace="social_network") as session:
        ## creating a write transaction
        with session.transaction().write() as write_transaction:
            ## write transaction is open
            ## write transaction must always be committed (closed)
            write_transaction.commit()

        ## creating a read transaction
        with session.transaction().read() as read_transaction:
            ## read transaction is open
            ## if not using a `with` statement, we must always close the read transaction like so
            # read_transaction.close()
            pass
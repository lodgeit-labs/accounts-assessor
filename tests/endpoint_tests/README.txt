We need to consider following two things while writing test code for prolog server.

1. The file upload option uses a 'tmp' folder to store a file temporarily. That's 
why we have created a 'tmp' folder in this directory and using that directory to 
store other files as well.

2. Currently, XML loan response is validated using a schema loan-reponse.xsd. 
The server looks-up the file in the taxonomy folder. That's why we have created 
a taxonomy folder and kept the schema file there.

It would be nice if we can come up with a technique so that we do not need to do 
the above tasks and the server can handle them.

The problem in current test code is that we cannot run this test from anywhere. 
Some codes in the server use the root directory as a base path and do other tasks 
based on that. If we run the test from a different directory, we have to take care 
of the above mentioned issues. That means from where we are running the test, we 
should have these two folders and files.
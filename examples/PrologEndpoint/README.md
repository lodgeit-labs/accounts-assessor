# Prolog Web Endpoint

This Visual Studio Solution is a demonstration of how a Prolog program can be used to make a web service that receives input data, performs certain computations, and sends back the result. More concretely, this demonstration comprises an ASP.NET Web Application project that receives a loan agreement in XML form, uses Prolog to compute the loan balance at year-ends, and sends back the result in XML form. Only the POST request method is used in this demonstration.

## This Web Application's dependencies
* An installation of [Visual Studio 2017](https://visualstudio.microsoft.com/vs/) with the [ASP.NET and web development workload](https://visualstudio.microsoft.com/vs/support/selecting-workloads-visual-studio-2017/). This is the software that can open the code herein and run the web endpoint on your local machine.
* A copy of [this repository](https://github.com/LodgeiT/labs-accounts-assessor/). This is where the Prolog scripts that do the actual computations reside. The Visual Studio project does nothing but receive HTTP requests and execute these scripts.
* An installation of [SWI-Prolog](http://www.swi-prolog.org/download/stable). This will contain a DLL library called `libswipl.dll` to interpret/execute the aforementioned Prolog scripts.

## How to run this Web Application
* Open up this solution up in Microsoft Visual Studio
* Make sure that argv of `PrologEndpoint.WebApiApplication.InitializeProlog` contains the correct location of `main.pl` which is to be found at the root of this repository. (Right now it is `C:\Users\murisi\Mirror\labs-accounts-assessor\main.pl` )
* Make sure that PrologEndpoint.Helpers.PL.dllName has the correct location of the Prolog Kernel DLL. (Right now it is `C:\Program Files\swipl\bin\libswipl.dll` )
* Go Project > Properties... > Build > General . Set Platform Target to match the target architecture of libswipl.dll, the Prolog Kernel DLL.
* Go Tools > Options > Projects and Solutions > Web Projects > Use the 64 bit version of IIS Express for web sites and projects, and make a selection depending on the target architecture of the Prolog Kernel DLL.
* Now go Debug > Start Debugging.

## What this Web Application does
* The endpoint will be at `http://localhost:57417/api/Loan` modulo the port number
* The endpoint will take an HTTP POST request whose Body is similar to request.xml
* The endpoint will take an HTTP POST request whose Content-Type is application/xml
* The endpoint will send a response whose Content is similar to response.xml
* The endpoint will service up to `PrologEndpoint.WebApiApplication.PrologEngines.length` requests simultaneously with no delay. Any additional requests will delay until a Prolog engine is available.

## An example usage of this Web Application
* Open up [request.xml](request.xml) and strip the document of all its new lines
* Open up Windows Powershell and enter `$out = Invoke-WebRequest -Uri http://localhost:57417/api/Loan -Body '<newline stripped request.xml goes here>' -ContentType application/xml -Method POST`
* There will be a significant delay in the servicing of this first request
* When the command is complete, `$out` will contain the full HTTP response
* To see the result of the computations, enter `$out.Content`
* The result should be the same as [response.xml](response.xml).

## Threading issues to be aware of
* After `PL_initialise` is called, there is one Prolog engine and it is associated only to the current thread at that point
* A Prolog engine cannot be used by a thread that it is not associated with
* The methods of a Web API controller that handle HTTP requests can be called from any thread
* Hence the HTTP request handlers of a controller cannot simply execute Prolog queries without prior configuration
* Also, a Prolog engine can only be associated with at most one thread at a time
* Also, Prolog engines are expensive to create/destroy in terms of space and time requirements
* Hence in this demo I implemented the following configuration:
  * I create a fixed-size pool of Prolog engines when the Web Application starts up
  * When a HTTP request is received, I grab the first free engine from the pool and associate it with the current thread
  * If there are no free engines, I busy loop until there is one
* Also, the implementation of `PL_create_engine` in `libswipl.dll` seems to be incorrect:
  * It will crash if the attr argument is `NULL`
  * If you want a Prolog engine with default attributes, supply it the address of a `PL_thread_attr_t` struct with all fields set to zero.

## Memory safety issues to be aware of
* The C# `unsafe` keyword is used a lot, this is primarily because pointers are used a lot
* Pointers are primarily used as type-checked handles to Prolog objects rather than as raw indicies into memory
* The combination of type-checking and lack of pointer arithmetic make the chances of memory corruption negligable
* The declaration of empty structs in PL.cs is analogous to how `typedef`s are used to declare opaque types in C
* Essentially all unmanaged memory allocations and deallocations are tracked by Prolog
* Hence wrapping Prolog queries with calls to `PL_open_foreign_frame` and `PL_discard_foreign_frame` will prevent memory leaks
* The only unmanaged memory allocations that are not tracked by Prolog are for housing string literals, and this is done exactly once in the web application's lifetime.

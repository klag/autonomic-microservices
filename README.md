# Towards Autonomic Microservices
This is the proof of concept related to the presentation "Towards Autonomic Microservices" given at the [Microservice Conference 2020](https://www.conf-micro.services/2020/program/) 

## Requirements
In order to run the PoC you need:


* [Jolie](https://www.jolie-lang.org/)
* [Docker](https://www.docker.com/)
* [Jocker](https://jolielang.gitbook.io/docs/language-tools-and-standard-library/containerization/docker/jocker)

## Running the PoC

### Running Jocker
Assumming docker is installed and working, run the jocker container:
```
docker pull jolielang/jocker
docker run -it -p 8008:8008 --name jocker -v /var/run:/var/run jolielang/jocker
```

### Running the simulator of the Execution Environment
Open a shell into folder `ExecutionEnvironment` and run the following command:
```
jolie main_execution_environment.ol
```

### Running the sample microservice
The sample microservice can be run within a container, here we describe its execution on a local shell just for allowing a direct observation of its behaviour. It is possible to run it inside a container following these [instructions](https://jolielang.gitbook.io/docs/language-tools-and-standard-library/containerization/docker) 

Open a shell into folder `Sample` and run the following command
```
jolie autonomic_manager.ol
```

### Running a test client
In order to sending requests to the sample microservice, open a shell into folder `clients` and run the following commands:
```
jolie client_reader.ol 200
```
where 200 is the number of requests sent to the sample microservice. The sample microservice simulate delays in the responses and will enable the deployment of new containers for its subservice `reader`. After 50 calls the delay simulator cut the delay simulating a well performing scenario and the sample service will remove the instantiated containers.



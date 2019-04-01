# cosmos-demo

We provide a docker image which contains all of the requsite code and models to
apply the COSMOS extraction pipeline (https://github.com/UW-COSMOS/Cosmos) to all PDFs within a specified directory.

First, clone this repository to get the necessary docker-compose files and some example input:

`git clone https://github.com/UW-COSMOS/cosmos-demo.git`


## Resource usage and runtime
The model can be run on either GPU or CPU but we **strongly** suggest utilizing GPUs
if available, as the speed increate in model application drastically reduces overall runtime.
In CPU only mode, a typical document will take on the order of 30 minutes, while
in GPU mode, this is closer to 5 minutes.

Additionally, at least 9 GB of memory must be made available to the running docker container.

For more information on allocating resources to docker, see https://docs.docker.com/config/containers/resource_constraints/.

## Running the model
Three environment variables must be defined needed to dictate the behavior of the image:

`INPUT_DIR` should point to the directory of PDFs on the host machine
`OUTPUT_DIR` should point to the desired output destiation (on the host machine)
`DEVICE` should either be set to `cpu` or `cuda:0` to switch between running on CPU or GPU, respectively.


### Running the model in CPU mode

```
OUTPUT_DIR=./output/ INPUT_DIR=/path/to/input/docs DEVICE=cpu docker-compose -f docker-compose-standalone-CPU.yml up --abort-on-container-exit
```


### Running the model in GPU mode

To run the model with a GPU, you will need [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) installed along with the correct drivers for your GPU card. Only NVIDIA cards are supported.

```
OUTPUT_DIR=./output/ INPUT_DIR=/path/to/input/docs DEVICE=cuda:0 docker-compose -f docker-compose-standalone-GPU.yml up --abort-on-container-exit
```

### Output
Once the model has been applied, the `cosmos` image will report an exit code of 0) and the docker-compose process will exit.
At the point, all of the models' output will be in the specified output directory:

    output.csv  -- CSV dump of the equation knowledgebase
    tables.csv  -- CSV dump of the table-related knowledgebase
    figures.csv  -- CSV dump of the figure-related knowledgebase
    xml/ -- Directory of the classified areas (bounding box coordinates and estimated category), stored at the page level
    html/ -- Directory of HTML representations of the pages, including unicode and tesseract text representations.
    images/ -- Page-level PNG images

It is recommended to run `docker-compose -f docker-compose-standalone-CPU.yml down` (or `docker-compose -f docker-compse-standalone-CPU.yml down`) between runs to prevent unexpected caching issues.

## Visualizer components

In addition to the model, we provide an additional suite of docker images which
can be used to visualize the resulting vision segmentations, along with
extracted figure, table, and equation knowledgebases.

By default, this setup forwards local port 5002 to the web service running on port 80 within a docker container. To view locally, point your browser to: http://localhost:5002

These components can be run alongside the pipeline and will automatically update when data become available.
To do this, you must also invoke the visualizer-specific docker-compose setup on top of the normal pipeline, as follows below.

Once the model has been applied, the `cosmos` image will report an exit code of 0). At this point, the results have been written to the output directory, and will be imported into the visualizer within a minute.


### Running the model in CPU mode, with visualization

```
OUTPUT_DIR=./output/ INPUT_DIR=/path/to/input/docs DEVICE=cpu docker-compose -f docker-compose-standalone-CPU.yml -f docker-compose_visualizer.yml up 
```


### Running the model in GPU mode, with visualization

To run the model with a GPU, you will need [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) installed along with the correct drivers for your GPU card. Only NVIDIA cards are supported.

```
OUTPUT_DIR=./output/ INPUT_DIR=/path/to/input/docs DEVICE=cuda:0 docker-compose -f docker-compose-standalone-GPU.yml -f docker-compose_visualizer.yml up 
```

### Running only the visualizer

It is also possible to run only the visualizer components on previously processed PDFs. This only requires defining the `OUTPUT_DIR` environmental variable, pointing it to the specified directory:

```
OUTPUT_DIR=./output/ docker-compose -f docker-compose_visualizer.yml up
```

By default, this setup forwards local port 5002 to the web service running on port 80 within a docker container. To view locally, point your browser to: http://localhost:5002

It is recommended to run `docker-compose -f docker-compose_visualizer.yml down` between runs to prevent unexpected caching issues.

## Common issues

cosmos image execution stops with an exit code of 137.
    This is likely due to the model application process being killed by a memory manager. Often it means that docker has not been provisioned enough memory. See https://docs.docker.com/config/containers/resource_constraints/ and check the memory allocated to docker on your system.

Delay between exit code 0 (succesful model completion) and availability of data in visualizer.
After successful execution of the Cosmos pipeline, there is a short delay before the output is made available in the visualizer. The visualizer accessible at http://localhost:5002 will report non-zero summary KB stats (e.g., more than 0 documents) once the database has been populated.

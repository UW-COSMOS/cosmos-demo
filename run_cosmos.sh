#!/bin/bash
# Run the cosmos pipeline, the results visualizer, or both on the specified data.
# If FULL or VIZ is specified, a persistent service listening on localhost port 5002 will be spawned.

# Usage example: 
#    Apply the model to the pdfs in "input" and store the results in "output"
#    INPUT_DIR=./input OUTPUT_DIR=./output ./run_cosmos.sh MODEL CPU 
#    Visualize the results in ./output
#    OUTPUT_DIR=./output ./run_cosmos.sh VIZ
#    Use the GPU to apply the model, then visualize the result
#    INPUT_DIR=./input OUTPUT_DIR=./output ./run_cosmos.sh FULL GPU

# $1: mode (either MODEL, FULL, or VIZ; defaults to FULL)
# $2: device (either GPU or CPU; defaults to CPU)

run_visualizer () {
    echo "Visualizing COSMOS output in $OUTPUT_DIR."
    OUTPUT_DIR=$OUTPUT_DIR  docker-compose -f docker-compose_visualizer.yml up
    sleep 60 # wait for startup + data import
    echo "Visualizer startup complete. Go to localhost:5002 to view results."
    printf "Don't forget to \n \t docker-compose -f docker-compose_visualizer.yml down\n ...when done viewing.\n"
}

MODE=${1:-FULL}
DEVICE=${2:-CPU}

echo "Removing any running containers.."
docker-compose -f docker-compose-standalone-GPU.yml -f docker-compose_visualizer.yml down 2>/dev/null

if [ -z "$OUTPUT_DIR" ]; then
    echo "Please set an OUTPUT_DIR environment variable to contain (or visualize) the output!"
    echo "Example: INPUT_DIR=./pdfs OUTPUT_DIR=./output ./run_cosmos.sh CPU MODEL"
    exit 1
fi

if [ "$MODE" == "FULL" ] || [ "$MODE" == "MODEL" ]; then
    if [ -z "$INPUT_DIR" ]; then
        echo "Please set an INPUT_DIR environment variable!"
        echo "Example: INPUT_DIR=./pdfs OUTPUT_DIR=./output ./run_cosmos.sh CPU MODEL"
        exit 1
    fi
fi

if [ "$MODE" == "VIZ" ]; then
    run_visualizer
elif [ "$DEVICE" == "CPU" ]; then
    echo "Running $MODE on device $DEVICE, input $INPUT_DIR and writing output to $OUTPUT_DIR."

    OUTPUT_DIR=$OUTPUT_DIR INPUT_DIR=$INPUT_DIR DEVICE=cpu docker-compose -f docker-compose-standalone-CPU.yml up --abort-on-container-exit

    if [ "$MODE" == "FULL" ] ; then
        run_visualizer
    else
        echo Model application complete. Output saved to $OUTPUT_DIR
    fi

elif [ "$DEVICE" == "GPU" ]; then
    echo "Running $MODE on device $DEVICE, input $INPUT_DIR and writing output to $OUTPUT_DIR."

    OUTPUT_DIR=$OUTPUT_DIR INPUT_DIR=$INPUT_DIR DEVICE=cuda:0 docker-compose -f docker-compose-standalone-GPU.yml up --abort-on-container-exit
    if [ "$MODE" == "FULL" ]; then
        run_visualizer
    else
        echo Model application complete. Output saved to $OUTPUT_DIR
    fi

else
    echo "Please provide a valid set of parameters. Example usage:"
    echo INPUT_DIR=./input OUTPUT_DIR=./output ./run_cosmos.sh MODEL CPU 
    echo To apply the model to the pdfs in "input" and store the results in "output":
    printf "\tINPUT_DIR=./input OUTPUT_DIR=./output ./run_cosmos.sh MODEL CPU\n"
    echo To visualize the results in ./output:
    printf "\tOUTPUT_DIR=./output ./run_cosmos.sh VIZ\n"
    echo To use the GPU to apply the model, then visualize the result:
    printf "\tINPUT_DIR=./input OUTPUT_DIR=./output ./run_cosmos.sh FULL GPU\n"
fi

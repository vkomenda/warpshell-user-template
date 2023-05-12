# MNIST Warpshell example app

## Contents

### MNIST Vitis HLS core

The core is located in `hls/`. This is a slightly modified [example](https://github.com/Nunigan/MNIST_HLS) due to Nunigan.


### Rust host driver

The driver is located in `/srcs/mnist/host/mnist-host/`.


## Setup

1. Get the MNIST dataset into directory of the `mnist-host` crate,
```
cd srcs/mnist/host/mnist-host
wget https://www.openml.org/data/download/52667/mnist_784.arff
```


## Build

1. Set up Vivado and Vitis environment variables.

2. Synthesise and export the MNIST Vitis HLS IP in `/srcs/mnist`:

```
/usr/bin/cmake -B build
cd build
make csynth_mnist_f250
make export_mnist_f250
```

3. In the top level Makefile, set `PERSONA=mnist`. Then run

```
make synth
make impl
```


## Run

Start the `xdma` kernel module and adjust the `/dev` file permissions as described in [Warpshell Rust crate](https://github.com/Quarky93/warpshell/tree/main/sw/rust#setup).

In this directory,
```
cd srcs/mnist/host/mnist-host
cargo run
```

The downloaded MNIST dataset has to be in the working directory for this to work.

You should see the output such as
```
The first image:
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 0A 08 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 08 0A 06 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 09 09 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 0A 05 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 08 0A 05 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 0A 0A 05 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 0A 0A 02 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 0A 0A 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 02 0A 0A 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 06 0A 08 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 01 0A 0A 03 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 03 0A 0A 02 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 03 0A 0A 02 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 03 0A 08 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 06 0A 07 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 08 0A 03 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 01 0A 0A 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 02 0A 0A 02 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 02 0A 0A 05 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 08 0A 08 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

Done in 52ms. Reading the results...
Success rate 99.58
```

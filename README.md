# Hardware Accelerated Sobel Operator
Image processing with an Artix-7 FPGA on Basys 3 development board

## Introduction
The aim of this project is to create an FPGA-based system that is able to display the edges of incoming images using the Sobel operator. The system is composed of an Artix-7 FPGA on Digilent's Basys 3 development board, a host computer with UART output, and a monitor to display the processed image.

## File Structure
* /src - contains all the relevant source files necessary to demo the design
* /tb - contains the test benches for the top level and all individual module designs
* /test_vectors - contains a variety of different test vectors that can be adjusted as necessary to evaluate the implementation
* /reports holds the final timing, area, and power reports for the top_level.vhd

## How to simulate and test the design
1. Create a new Vivado project including all the src files, test vectors, and test_bench
  * Make sure to use the accompanying xdc files to setup the clocks
2. Set the top level design to top_level.vhd as well as for the top_level_tb.vhd
3. Simulate top_level_tb.vhd for 3 ms
  * The simulation will stop once the data has been written to the file
4. Compare the output against the reference files to verify the working design
  * It's suggested to avoid using other larger test vectors it takes a signficant amount of time to run anything larger than the 16x16 file.


// `include "potential_decay/potential_decay.v"
// `include "mac/mac.v"
// `include "potential_adder/potential_adder.v"
`include "utils/Addition_Subtraction.v"
`include "utils/Multiplication.v"
`include "network_interface/network_interface.v"
`include "neuron/neuron.v"	// Include the neuron module

`timescale 1ns/100ps

module accelerator(
    input wire CLK,
    input wire clear,
    input wire[3:0] decay_rate,
    input wire[11:0] source_addresses[0:10-1],         //write her simulate spike packets by sending source addresses
    input wire[159:0] weights_arrays[0:10-1],           //initialize store weights of the connections
    input wire[59:0] source_addresses_arrays[0:10-1],   //initialize connection by writing source addresses to the accumulators
    input wire[11:0] neuron_addresses[0:10-1],          //initialize with neuron addresses
    input wire[31:0] membrane_potential[0:10-1],        //initialize membrane potential values
    input wire[31:0] v_threshold[0:10-1],               //threshold values
    input wire[359:0] downstream_connections_initialization,    //input to initialize the dowanstream connections
    input wire[119:0] neuron_addresses_initialization,                //input to initialize the neruon addresses
    input wire[54:0] connection_pointer_initialization,               //input to initialize the connection pointers
    input wire[1:0] model,
    input wire[31:0]a, b, c, d, u_initialize,      //for izhikevich model
    output wire spike[0:number_of_neurons-1],                              //spike signifier from potential decay
);

    parameter number_of_neurons=10;                        //initiailize number of neurons

    reg[11:0] spike_origin;                               //to store the nueron address from the arrived packet
    reg[11:0] spike_destination;                               //to store source address from the arrived packet
    wire[23:0] packet;                          //packet containing neuron address and sources address

    // generate 10 neurons
    genvar i;
    generate
        for(i=0; i<10; i=i+1) begin
          neuron n(
            .CLK(CLK),
            .clear(clear),
            .neuron_address(neuron_addresses[i]),
            .source_address(source_addresses[i]),
            .weights_array(weights_arrays[i]),
            .source_addresses_array(source_addresses_arrays[i]),
            .v_threshold(v_threshold[i]),
            .decay_rate(decay_rate),
            .membrane_potential_initialization(membrane_potential[i]),
            .model(model),
            .a(a),
            .b(b),
            .c(c),
            .d(d),
            .u_initialize(u_initialize),
            .spike(spike[i])
          );
        end
    endgenerate    

    network_interface ni1(
        .CLK(CLK),
        .clear(clear),
        // .spikes({spike[0],spike[1],spike[2],spike[3],spike[4],spike[5],spike[6],spike[7],spike[8],spike[9]}),
        .spike0(spike[0]),
        .spike1(spike[1]),
        .spike2(spike[2]),
        .spike3(spike[3]),
        .spike4(spike[4]),
        .spike5(spike[5]),
        .spike6(spike[6]),
        .spike7(spike[7]),
        .spike8(spike[8]),
        .spike9(spike[9]),
        .neuron_addresses_initialization(neuron_addresses_initialization),
        .connection_pointer_initialization(connection_pointer_initialization),           //input to initialize the connection pointers
        .downstream_connections_initialization(downstream_connections_initialization),    //input to initialize the dowanstream connections
        .packet(packet)               //outgoing packet         
    );

    //when packets arrive from the potential adder send the source address to the relevant mac unit 
    always @(packet) begin
        spike_origin = packet[23:12];               // From where the spike came
        spike_destination = packet[11:0];           // To where it should be sent 

        source_addresses[spike_destination] = spike_origin;      // Trigger the wire of the relevant accumulator
    end


endmodule
`timescale 1ns / 10ps

//DisplayDriver DDO(.clk100MHz(clk100MHz), .clk(clk), .charWE(charWE), .(posX), .posY(posY), 
//                  .AsciiHex(AsciiHex), .Hsync(Hsync), .Vsync(Vsync), .vgaRed(vgaRed), .vgaBlue(vgaBlue), .vgaGreen(vgaGreen));
//input clk100MHz,          Has to be a 100MHz clock                                 
//input clk,                Slower Clock used to clock in characters                 
//input charWE,             Used to enable character write                           
//input [7:0]posX,          Used to select the position X on the screen from top left
//input [4:0]posY,          Used to select the position Y on the screen from top left
//input [7:0] AsciiHex,     Used to input new character to array                     
//output Hsync,             Used by this module to drive the VGA port                
//output Vsync,             Used by this module to drive the VGA port                
//output reg[3:0] vgaRed,   Used by this module to drive the VGA port                
//output reg[3:0] vgaBlue,  Used by this module to drive the VGA port                
//output reg[3:0] vgaGreen  Used by this module to drive the VGA port 

module DisplayDriver(
    input clk100MHz,        //Has to be a 100MHz clock
    input clk,              //Slower Clock used to clock in characters
    input charWE,           //Used to enable character write
    input [7:0]posX,             //Used to select the position X on the screen from top left
    input [4:0]posY,             //Used to select the position Y on the screen from top left
    input [7:0] AsciiHex,   //Used to input new character to array
    output Hsync,           //Used by this module to drive the VGA port
    output Vsync,           //Used by this module to drive the VGA port
    output reg[3:0] vgaRed,     //Used by this module to drive the VGA port
    output reg[3:0] vgaBlue,    //Used by this module to drive the VGA port
    output reg[3:0] vgaGreen    //Used by this module to drive the VGA port
    );
    //Variableish Declarations
    localparam WIDTH = 640;    //Horizontal screen width
    localparam HEIGHT = 480;   //Vertical screen height
    
    wire clk25MHz, Animate, ScreenEnd, OnScreen;
    wire[10:0] Xc, Yc;
    reg TextOn;
    reg WriteEnable;
    reg [4:0]RRowSel, WRowSel;
    reg [7:0]RColSel, WColSel;
    wire [7:0]HexOut;
    reg YDivToggle;
    reg[17:0] wordIndex;
    wire[3:0]RowSelText;
    wire[7:0]TextRowOut;
    reg [2:0]TextIndex;
    reg TestTextLatch;
    reg [7:0]Filter;
        
    //Setup the Display Drivers for use
    //Returns clk25MHz, Animate, EndScreen, OnScreen, Hsync, Vsync for use
    Driver D0(clk100MHz, clk25MHz, Animate, ScreenEnd, OnScreen, Hsync, Vsync, Xc, Yc);
        
    //Initialize a text array
    ScreenText STA0(clk100MHz, clk, charWE, AsciiHex, RRowSel, posY, RColSel, posX, HexOut);
    
    //Pipe the HexOut into this function for decoding
    //Ycurrent is the row that we want to select
    AsciiDecode ASCIID0(clk100MHz, HexOut, Yc[3:0], TextRowOut);
    
    //Draw TextBuffer
    initial
    begin
        YDivToggle <= 1; //Starts as true on purpose
        WriteEnable <= 0;
        wordIndex <= 0;
        TextIndex <= 0;
        TestTextLatch <= 1; //Intentinaly high
        RRowSel <= 0;
        RColSel <= 0;
        WRowSel <= 0;
        WColSel <= 0;        
        //$monitor($time,"\tWatching: Xc=%b, RColSel=%d",Xc,RColSel);
    end
    
    
    //This is how to draw a square if you are so inclined. However, there is not currently
    //A way to choose between multiple inputs to the screen out so you will have to disable
    //The text system first. OR you can design a way to implement both.
//    wire Sqr_a, Sqr_b, Sqr_c;
//    assign Sqr_a = (Xc < 100 & Yc < 100)?1:0;
//    assign Sqr_b = (Xc > 80 & Xc < 180 & Yc > 80 & Yc < 180)?1:0;
//    assign Sqr_c = (Xc > 160 & Xc < 260 & Yc > 160 & Yc < 260)?1:0;
    
    //DRAW FUNCTION
    always@(negedge clk25MHz)
    begin
        //TextIndex rolls over at 7 to 0
        TextIndex <= TextIndex + 1;
    end
    
    always@(posedge clk25MHz)
    begin
        //when the screen is at the next line
        if (Yc[3:0] == 4'b1111 && YDivToggle) //devide Ycurrent by 16 to index every 16
        begin
            RRowSel <= RRowSel + 5'd1;
            YDivToggle = 0;
        end
        else if (Yc[3:0] != 4'b1111 && !YDivToggle)
            YDivToggle = 1;    
        else if (Yc == 0)
            RRowSel <= 5'd0; //Check and then reset at zero
        //When the screen updates a pixel, index    
        if (Xc[2:0] == 3'b111)
            RColSel <= RColSel + 8'd1;
        else if (Xc == 0)
            RColSel <= 8'd0;
        //Text filtering
        //Using bit masking we can select the appropriate bit from 
        //Each of the characters to display the proper output
        case(TextIndex)
            0:Filter = 8'b1000_0000;
            1:Filter = 8'b0100_0000;
            2:Filter = 8'b0010_0000;
            3:Filter = 8'b0001_0000;
            4:Filter = 8'b0000_1000;
            5:Filter = 8'b0000_0100;
            6:Filter = 8'b0000_0010;
            7:Filter = 8'b0000_0001;
        endcase
        
        
        //auto increments through the avalible pixels one at a time
        //for the textTextRowOut
        TextOn = (TextRowOut & Filter)?1:0;
        //Draws the text to the screen. 
        //Change this to change the color Output
        vgaRed   <= (TextOn)? 4'hf : 0;
        vgaBlue  <= (TextOn)? 4'hf : 0;
        vgaGreen <= (TextOn)? 4'hf : 0;
        
        //This is a fail safe incase a character is generated that is outside 
        //the allowable bounds, preventing the screen from just blanking 
        if(~OnScreen)
        begin
            vgaRed   <= 4'h0;
            vgaBlue  <= 4'h0;  
            vgaGreen <= 4'h0; 
        end
    end
endmodule

module Driver(
    input clk100MHz,
    output clk25MHz, Animate, ScreenEnd, reg OnScreen, wire Hsync, Vsync,
    reg[10:0] CurrX, CurrY
    );
    initial begin
        CurrX = 0;
        CurrY = 0;
    end
    wire [10:0] Hcounter, Vcounter;
    wire Hzero, Vzero, HPend, VPend;
    //Variableish Declarations
    localparam HA_START = 143; //Horizontal active pixel start
    localparam HA_END = 783;   //Horizontal active pixel end
    localparam VA_START = 30;  //Vertical active pixel start
    localparam VA_END = 509;   //Vertical active pixel end
    localparam LINE = 800;     //Complete Line (pixels)
    localparam SCREEN = 525;   //Complete Screen (lines)
    
    Timers T0(clk100MHz, clk25MHz); //Initialize the 25MHz clock
    //Horizontal Sync Pulse generation
    HorizontalCounter HC0(clk25MHz, Hcounter); //Start a counter for the Horizontal pixels
    ZeroDetect Z0(Hcounter, Hzero);  //Looks for when the Horizontal Counter rolls over
    PulseWidth PH0(clk25MHz, Hzero, 20'd96, HPend); //Sends a pulse out after 3.84 uSec
    SRLatch SR0(clk25MHz, Hzero, HPend, Hsync); // This is the HS out to VGA Port (3.84 uSecs in length)
    //Vertical Sync Pulse generation
    VerticalCounter VC0(Hsync, Vcounter); //Use the Hsync inorder to clock only once per horizontal line
    ZeroDetect Z1(Vcounter, Vzero); //Looks for when the Vertical counter rolls over
    PulseWidth PV0(clk25MHz, Vzero, 20'd1600, VPend); //Sends a pulse out after 64 uSec
    SRLatch SR1(clk25MHz, Vzero, VPend, Vsync); //This is the VS out to VGA Port (64 uSecs in length)
    
    //Assign Statements
    //high for one tick at the very end of the screen
    assign ScreenEnd = ((Vcounter == SCREEN - 1) & (Hcounter == LINE)); 
    //high for one tick at the end of the writeable area
    assign Animate = ((Vcounter == VA_END-1) & (Hcounter == LINE));
    
    //Converts the counter values into a 480x640 cordinates system; 10'b1000000000 is dead pixel indecator
    always @(posedge clk25MHz)//changed from 100MHz
    begin
        //high when pixels can be written to the screen
        OnScreen <= ((Hcounter > HA_START) & (Hcounter < HA_END) & (Vcounter > VA_START) & (Vcounter < VA_END))?1:0;
        //-1 and +1 are the adjustments to turn this into <= or => statements.
        CurrX <= ((Hcounter > HA_START-1) & (Hcounter < HA_END + 1)) ? (Hcounter - HA_START-1) : 10'b10_0000_0000;
        CurrY <= ((Vcounter > VA_START-1) & (Vcounter < VA_END + 1)) ? (Vcounter - VA_START-1) : 10'b10_0000_0000;
    end
endmodule          

module PulseWidth(
    input clk25MHz, zero, wire[19:0] cmp,
    output reg Pend
    );
    
    reg [19:0] cnt; //large enough for any delay 0 to 534378
    
    initial
    begin
         Pend <= 0; //Pulse End
         cnt <= 0; //Counter
    end
        
    always @(posedge clk25MHz)
    begin
        //add 1 every clock signal
        cnt <= cnt + 1;
        if(zero) //Reset the counter to zero
            cnt <= 0;
        //If the counter is equal to the comparison value
        if(cnt[19:0] == cmp[19:0])
            Pend <= 1; //End the pulse (toggles the R on SRlatch)
        else
            Pend <= 0;
        //Send the Pulse end(Pend) signal out
    end
endmodule

/* ZeroDetect
 * Looks for when the signal (sig) goes to zero and sets a flag high
 * Runs Asyncronusly and toggles the zero (in PulseWidth typically)
*/

module ZeroDetect(
    input wire[10:0] sig,
    output reg zero
    );
    initial
    begin
        zero <= 0;
    end
    //always is used without edge detection to allow for even and odd numbers 
    //to update the values
    always @(sig)
        if(sig[10:0] == 10'h0)
            zero <= 1;
        else
            zero <= 0;
endmodule

module HorizontalCounter(
    input clk25MHz,
    output reg[10:0] Hcounter 
    );
    initial
    begin
        Hcounter <= 10'd0;
        //$monitor($time,"\tHcounter:%d",Hcounter);
    end
            
    always @(posedge clk25MHz)
    begin
        Hcounter = Hcounter + 1;//add 1 to the counter
        if(Hcounter == 10'd800) //Counter will be forced to rollover at 800
            Hcounter = 10'd0;       //total number of pixels including deadspace)
    end
endmodule

module VerticalCounter(
    input Hsync, 
    output reg[10:0] Vcounter  
    );
    initial
    begin
        Vcounter <= 10'd0;
    end
            
    always @(posedge Hsync)
    begin
        Vcounter = Vcounter + 1;//adds 1 to Vcounter
        if(Vcounter == 10'd525) //VGA standard says 521 lines, however the extra dead
            Vcounter = 10'd0;       //space is needed for timing issues rolls at 525 pixels   
    end
endmodule

module SRLatch(
    input clk25MHz, set, reset,
    output reg q
    );
    //This method avoids the issues with race-conditions
    //It also solved an issue with the latch setting via inductance within the chip
    //This is why it has been synced using the 25MHz clock
    always @(posedge clk25MHz)
    begin
        case({set,reset})
            2'b00 : ; //don't care
            2'b01 : q <= 0; //standard SR Latch truth table
            2'b10 : q <= 1;
            2'b11 : ; //don't care
        endcase
    end
endmodule

module Timers(
    input clk100MHz,
    output reg clk25MHz
    );
    reg  [26:0] clkDiv; // A 27 bit counter to divide down the 100 MHz
    initial
    begin
        clkDiv <= 0;
    end
    
 // Use the counter to divide down the 100 MHz clock
    always @(posedge clk100MHz) 
        clkDiv <= clkDiv + 1;

    // Select the clock speed to use for the CPU, based on the three lower switches.
    // When all switches are off, select the pushbutton switch.
    always @(posedge clkDiv)
        clk25MHz = clkDiv[1]; //devides the clock by 2 because it was only on posedge
                              //results in 25MHz clock
endmodule


/*   !!!!!IT IS VERY IMPORTANT TO USE ASCII HEX VALUES!!!!!
 * This module creates an array of characters, in Ascii Hex, that 
 * can be displayed it is important to note the size of this array 
 * is quite large at 30*80*8 = 19200 bits or 18.75 Kb!!!!!!!!!!!!!!!!
 * The Basys3 has only 1899Kb included on the board
 *
 * Module returns the entire rows worth of bits in one shot
 */
module ScreenText(
    input clock100MHz,
    input clockDataIn,
    input WriteEnable,
    input [7:0]AsciiHex,
    input [4:0]RRowSel,WRowSel,
    input [7:0]RColSel,WColSel,
    output [7:0]HexOut
    );
    reg [11:0] Waddr, Raddr;
    //decode Write selection
    //30 ROW 80 COL
    always @(WRowSel, WColSel)
    begin
        Waddr = WRowSel * 80 + WColSel;
    end
    //decode Read selection
    //30 ROW 80 COL
    always @(RRowSel, RColSel)
    begin
        Raddr = RRowSel * 80 + RColSel;
    end
    
    Screen_Array_BRAM SAB0(clockDataIn, WriteEnable, Waddr, AsciiHex, 
                           clock100MHz, Raddr, HexOut);
endmodule

/*   !!!!!IT IS VERY IMPORTANT TO USE ASCII HEX VALUES!!!!!
 *        IF YOU USE THE WRONG VALUE A 'null' will be outputed
 * Biggest module that we have, its function is to decode
 * the ascii standard hex into characters that can be displayed
 * it is important to note the size of this array is quite large
 * at 69*16*8 = 8832 bits or 8.625 Kb!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 * The Basys3 has only 1899Kb included on the board
 * Font is encoded in a 8x16 format with each row being 8 bits
 * in lenght eg.
 */
 
module AsciiDecode(
    input clk100MHz,
    input [7:0]AsciiHex,
    input [3:0]RowSel,
    output [7:0]DataOut
    );
    reg [7:0]TableLookup;
    reg [10:0]AddrSel;
    //Decode the hex into a value that works for the array
    always @(AsciiHex, RowSel)
    begin
        case (AsciiHex)
            //For values h20:h5f
            8'h20 : TableLookup = AsciiHex - 8'h20;
            8'h21 : TableLookup = AsciiHex - 8'h20;
            8'h22 : TableLookup = AsciiHex - 8'h20;
            8'h23 : TableLookup = AsciiHex - 8'h20;
            8'h24 : TableLookup = AsciiHex - 8'h20;
            8'h25 : TableLookup = AsciiHex - 8'h20;
            8'h26 : TableLookup = AsciiHex - 8'h20;
            8'h27 : TableLookup = AsciiHex - 8'h20;
            8'h28 : TableLookup = AsciiHex - 8'h20;
            8'h29 : TableLookup = AsciiHex - 8'h20;
            8'h2a : TableLookup = AsciiHex - 8'h20;
            8'h2b : TableLookup = AsciiHex - 8'h20;
            8'h2c : TableLookup = AsciiHex - 8'h20;
            8'h2d : TableLookup = AsciiHex - 8'h20;
            8'h2e : TableLookup = AsciiHex - 8'h20;
            8'h2f : TableLookup = AsciiHex - 8'h20;
            8'h30 : TableLookup = AsciiHex - 8'h20;
            8'h31 : TableLookup = AsciiHex - 8'h20;
            8'h32 : TableLookup = AsciiHex - 8'h20;
            8'h33 : TableLookup = AsciiHex - 8'h20;
            8'h34 : TableLookup = AsciiHex - 8'h20;
            8'h35 : TableLookup = AsciiHex - 8'h20;
            8'h36 : TableLookup = AsciiHex - 8'h20;
            8'h37 : TableLookup = AsciiHex - 8'h20;
            8'h38 : TableLookup = AsciiHex - 8'h20;
            8'h39 : TableLookup = AsciiHex - 8'h20;
            8'h3a : TableLookup = AsciiHex - 8'h20;
            8'h3b : TableLookup = AsciiHex - 8'h20;
            8'h3c : TableLookup = AsciiHex - 8'h20;
            8'h3d : TableLookup = AsciiHex - 8'h20;
            8'h3e : TableLookup = AsciiHex - 8'h20;
            8'h3f : TableLookup = AsciiHex - 8'h20;
            8'h40 : TableLookup = AsciiHex - 8'h20;
            8'h41 : TableLookup = AsciiHex - 8'h20;
            8'h42 : TableLookup = AsciiHex - 8'h20;
            8'h43 : TableLookup = AsciiHex - 8'h20;
            8'h44 : TableLookup = AsciiHex - 8'h20;
            8'h45 : TableLookup = AsciiHex - 8'h20;
            8'h46 : TableLookup = AsciiHex - 8'h20;
            8'h47 : TableLookup = AsciiHex - 8'h20;
            8'h48 : TableLookup = AsciiHex - 8'h20;
            8'h49 : TableLookup = AsciiHex - 8'h20;
            8'h4a : TableLookup = AsciiHex - 8'h20;
            8'h4b : TableLookup = AsciiHex - 8'h20;
            8'h4c : TableLookup = AsciiHex - 8'h20;
            8'h4d : TableLookup = AsciiHex - 8'h20;
            8'h4e : TableLookup = AsciiHex - 8'h20;
            8'h4f : TableLookup = AsciiHex - 8'h20;
            8'h50 : TableLookup = AsciiHex - 8'h20;
            8'h51 : TableLookup = AsciiHex - 8'h20;
            8'h52 : TableLookup = AsciiHex - 8'h20;
            8'h53 : TableLookup = AsciiHex - 8'h20;
            8'h54 : TableLookup = AsciiHex - 8'h20;
            8'h55 : TableLookup = AsciiHex - 8'h20;
            8'h56 : TableLookup = AsciiHex - 8'h20;
            8'h57 : TableLookup = AsciiHex - 8'h20;
            8'h58 : TableLookup = AsciiHex - 8'h20;
            8'h59 : TableLookup = AsciiHex - 8'h20;
            8'h5a : TableLookup = AsciiHex - 8'h20;
            8'h5b : TableLookup = AsciiHex - 8'h20;
            8'h5c : TableLookup = AsciiHex - 8'h20;
            8'h5d : TableLookup = AsciiHex - 8'h20;
            8'h5e : TableLookup = AsciiHex - 8'h20;
            8'h5f : TableLookup = AsciiHex - 8'h20; //END OF lowercase
            
            8'h61 : TableLookup = AsciiHex - 8'h40;
            8'h62 : TableLookup = AsciiHex - 8'h40;
            8'h63 : TableLookup = AsciiHex - 8'h40;
            8'h64 : TableLookup = AsciiHex - 8'h40;
            8'h65 : TableLookup = AsciiHex - 8'h40;
            8'h66 : TableLookup = AsciiHex - 8'h40;
            8'h67 : TableLookup = AsciiHex - 8'h40;
            8'h68 : TableLookup = AsciiHex - 8'h40;
            8'h69 : TableLookup = AsciiHex - 8'h40;
            8'h6a : TableLookup = AsciiHex - 8'h40;
            8'h6b : TableLookup = AsciiHex - 8'h40;
            8'h6c : TableLookup = AsciiHex - 8'h40;
            8'h6d : TableLookup = AsciiHex - 8'h40;
            8'h6e : TableLookup = AsciiHex - 8'h40;
            8'h6f : TableLookup = AsciiHex - 8'h40;
            8'h70 : TableLookup = AsciiHex - 8'h40;
            8'h71 : TableLookup = AsciiHex - 8'h40;
            8'h72 : TableLookup = AsciiHex - 8'h40;
            8'h73 : TableLookup = AsciiHex - 8'h40;
            8'h74 : TableLookup = AsciiHex - 8'h40;
            8'h75 : TableLookup = AsciiHex - 8'h40;
            8'h76 : TableLookup = AsciiHex - 8'h40;
            8'h77 : TableLookup = AsciiHex - 8'h40;
            8'h78 : TableLookup = AsciiHex - 8'h40;
            8'h79 : TableLookup = AsciiHex - 8'h40;
            8'h7a : TableLookup = AsciiHex - 8'h40; //END OF UPPERCASE
            8'h7b : TableLookup = AsciiHex - 8'h3b;
            8'h7c : TableLookup = AsciiHex - 8'h3b;
            8'h7d : TableLookup = AsciiHex - 8'h3b;
            8'h7e : TableLookup = AsciiHex - 8'h3b;
            default: TableLookup = 8'd68; // ERROR CHARACTER
        endcase
        //TableLookup is a offset from zero that acts like a row select
        //RowSel selects the particular Column selecter
        AddrSel = TableLookup * 16 + RowSel; //contains offset from zero by 16 per 1
    end
    //BRAM that is preloaded with the entire Ascii Array
    Ascii_Text_BROM ATB0(clk100MHz,AddrSel,DataOut);
    
endmodule
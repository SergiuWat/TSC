/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns; // pentru "#" sa seteam unitatile de timp


  parameter write_order = 1;  //0-incremental 1- decremental 2 - random
  parameter read_order = 1;
  parameter WR_NR = 7;
  parameter RD_NR = 7;
  parameter CASE_NAME = "test";
  parameter SEED_VAL = 555;
 
  int seed = SEED_VAL;
  int tests = 0;
  int fail_counter = 0;
  int passed_counter = 0;
  instruction_t iw_reg_test [0:31];
  


  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  DON'T NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    foreach (iw_reg_test[i]) begin
      iw_reg_test[i] = '{opc: ZERO, default: 0};
    end
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)



    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    //repeat (3) begin modificat de sergiu
    repeat(WR_NR) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
      save_test_data;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<=RD_NR; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      case(read_order)
            0: read_pointer <= i;
            1: read_pointer <= 31 - (i%32);
            2: read_pointer <= $unsigned($random)%32;
      endcase
      //@(posedge clk) read_pointer = i;
      @(negedge clk) print_results;
      check_result;
      // de facut functia check_result() nu cea pe care o am deja alta noua
    end
    final_report;
    write_regression_status;
    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  DON'T NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction; // genereaza operand_a si operand_b
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp_incremental = 0;
    static int temp_decremental = 31;
    operand_a     <= $random(seed)%16;                 // between -15 and 15
    operand_b     <= $unsigned($random)%16;            // between 0 and 15
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    //write_pointer <= temp++;
    case(write_order)
      0: write_pointer <= temp_incremental++;
      1: write_pointer <= temp_incremental--;
      2: write_pointer <= $unsigned($random)%32;
    endcase
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d\n", instruction_word.op_b);
    $display("  rezulat = %0d\n", instruction_word.rezultat);
  endfunction: print_results

  function void save_test_data;
   operand_d expected_result;
    case(opcode)
    PASSA: expected_result = operand_a;
    PASSB: expected_result = operand_b;
    ADD: expected_result = operand_a + operand_b;
    SUB: expected_result = operand_a - operand_b;
    MOD:
       if(operand_b == 'b0)begin
          expected_result = 'b0;
        end 
        else begin
           expected_result = operand_a % operand_b;
        end  
    MULT: expected_result = operand_a * operand_b;
    DIV:
        if(operand_b == 'b0)begin
          expected_result = 'b0;
        end 
        else begin
           expected_result = operand_a / operand_b;
        end
    ZERO: expected_result = 'b0;
  endcase
  iw_reg_test[write_pointer] = '{opcode, operand_a , operand_b, expected_result};

  endfunction: save_test_data
  function void final_report;
    $display("\n Failed test: %0d", fail_counter);
    $display("\n Passed test: %0d", passed_counter);
    $display("\n Passed test %0d out of %0d", passed_counter, tests);
  endfunction
  function void check_result;
        if(iw_reg_test[read_pointer].rezultat !== instruction_word.rezultat)begin
          fail_counter++;
          $display("\n Iteration = %0d \n: opcode = %0d (%s)  \noperand_a = %0d \n operand_b = %0d \n expected result = %0d  \n actual result = %0d \n Failed \n",read_pointer , iw_reg_test[read_pointer].opc, iw_reg_test[read_pointer].opc.name, iw_reg_test[read_pointer].op_a, iw_reg_test[read_pointer].op_b, iw_reg_test[read_pointer].rezultat,instruction_word.rezultat);
        end 
        else begin
          $display("\n Iteration = %0d \n: opcode = %0d (%s)  \noperand_a = %0d \n operand_b = %0d \n expected result = %0d  \n actual result = %0d \n Passed \n",read_pointer , iw_reg_test[read_pointer].opc, iw_reg_test[read_pointer].opc.name, iw_reg_test[read_pointer].op_a, iw_reg_test[read_pointer].op_b, iw_reg_test[read_pointer].rezultat,instruction_word.rezultat);
          passed_counter++;
        end
        tests++;
  endfunction: check_result
  function void write_regression_status;
      int fd;

      fd = $fopen("../reports/regression_transcript/regression_status.txt", "a");
      if(fd) $display("File openned successfully");
      else $display("File failed to open");
      if(fail_counter !=0) $fdisplay(fd, "%s : failed", CASE_NAME);
      else $fdisplay(fd, "%s : passed", CASE_NAME);
  endfunction
endmodule: instr_register_test

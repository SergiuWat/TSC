/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter:
 * User-defined type definitions
 **********************************************************************/
package instr_register_pkg;
  timeunit 1ns/1ns;

  typedef enum logic [3:0] {
  	ZERO,
    PASSA, // valoarea operanD A
    PASSB, // valoarea operand B
    ADD,
    SUB,
    MULT,
    DIV,
    MOD  // MODULO Daca am nr negativ il fac pozitiv
  } opcode_t;

  typedef logic signed [31:0] operand_t;
  
  typedef logic [4:0] address_t;
  
  typedef struct { // de adaugat o noua variabila pentru data viitoare pentru rezultat
    opcode_t  opc;
    operand_t op_a;
    operand_t op_b;
  } instruction_t;

endpackage: instr_register_pkg

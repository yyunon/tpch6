----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2020 02:15:37 PM
-- Design Name: 
-- Module Name: SumOp - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

--library ieee_proposed;
--use ieee_proposed.fixed_pkg.all;

library work;
use work.Stream_pkg.all;
use work.Forecast_pkg.all;


entity SumOp is
  generic (

    -- Width of the stream data vector.
    FIXED_LEFT_INDEX            : INTEGER;
    FIXED_RIGHT_INDEX           : INTEGER;
    DATA_WIDTH                  : natural;
    DATA_TYPE                   : string :="" 

  );
  port (

    -- Rising-edge sensitive clock.
    clk                          : in  std_logic;

    -- Active-high synchronous reset.
    reset                        : in  std_logic;

    --OP1 Input stream.
    op1_valid                    : in  std_logic;
    op1_dvalid                   : in  std_logic := '1';
    op1_ready                    : out std_logic;
    op1_data                     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    
    --OP2 Input stream.
    op2_valid                    : in  std_logic;
    op2_dvalid                   : in  std_logic := '1';
    op2_ready                    : out std_logic;
    op2_data                     : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output stream.
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out_dvalid                   : out std_logic
  );
end SumOp;

architecture Behavioral of SumOp is

  --subtype float64 is float(11 downto -52);
  signal temp_buffer              : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal ops_valid                : std_logic;
  signal ops_ready                : std_logic;
  
  signal result                   : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

 
 -- Synchronize the operand streams.
 op_in_sync: StreamSync
    generic map (
      NUM_INPUTS                => 2,
      NUM_OUTPUTS               => 1
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid(0)               => op1_valid,
      in_valid(1)               => op2_valid,
      in_ready(0)               => op1_ready,
      in_ready(1)               => op2_ready,

      out_valid(0)              => ops_valid,
      out_ready(0)              => ops_ready
    );   

  float_comb_process:
  if DATA_TYPE="FLOAT64" generate
    process(op1_data, op2_data) is 
      variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_buffer_2: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_res: sfixed(FIXED_LEFT_INDEX+1 downto FIXED_RIGHT_INDEX);
    begin
      temp_buffer_1 := to_sfixed(op1_data,temp_buffer_1'high,temp_buffer_1'low);
      temp_buffer_2 := to_sfixed(op2_data,temp_buffer_2'high,temp_buffer_2'low);
      temp_res := temp_buffer_1 + temp_buffer_2;
      result <= to_slv(resize( arg => temp_res,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
    end process;
  end generate;
    
  int_comb_process:
  if DATA_TYPE="INT64" generate
    process (op1_data, op2_data) is
    begin
      result <= std_logic_vector(signed(op1_data) + signed(op2_data));
    end process;
  end generate;
  
  out_data <= std_logic_vector(result);
  out_valid <= ops_valid;
  out_dvalid <= op1_dvalid and op2_dvalid;
  ops_ready <= out_ready;

end Behavioral;

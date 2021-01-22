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

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.Stream_pkg.all;
use work.Forecast_pkg.all;
--use work.fixed_generic_pkg_mod.all;


entity MergeOp is
  generic (

    -- Width of the stream data vector.
    FIXED_LEFT_INDEX            : INTEGER;
    FIXED_RIGHT_INDEX           : INTEGER;
    DATA_WIDTH                  : natural;
    MIN_DEPTH                   : natural;
    DATA_TYPE                   : string :="" 

  );
  port (

    -- Rising-edge sensitive clock.
    clk                          : in  std_logic;

    -- Active-high synchronous reset.
    reset                        : in  std_logic;

    --OP1 Input stream.
    op1_valid                    : in  std_logic;
    op1_last                     : in  std_logic;
    op1_dvalid                   : in  std_logic := '1';
    op1_data                     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    op1_ready                    : out  std_logic;
    
    --OP2 Input stream.
    op2_valid                    : in  std_logic;
    op2_last                     : in  std_logic;
    op2_dvalid                   : in  std_logic := '1';
    op2_ready                    : out std_logic;
    op2_data                     : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output stream.
    out_valid                    : out std_logic;
    out_last                     : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out_dvalid                   : out std_logic
  );
end MergeOp;

architecture Behavioral of MergeOp is

  --subtype float64 is float(11 downto -52);

  signal out_s_valid                : std_logic;
  signal out_s_dvalid               : std_logic;
  signal out_s_last                 : std_logic;
  signal out_s_ready                : std_logic;
  signal out_s_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal ops_valid                : std_logic;
  signal ops_dvalid               : std_logic;
  signal ops_last                 : std_logic;
  signal ops_ready                : std_logic;
  signal ops_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  -- Emulate sync bbehaviour with only one stream
  signal done                     : std_logic;
  signal accepted                 : std_logic;
  signal ready                    : std_logic;
  signal valid                    : std_logic;

  signal op2_d_valid                : std_logic;
  signal op2_d_dvalid               : std_logic;
  signal op2_d_last                 : std_logic;
  signal op2_d_ready                : std_logic;
  signal op2_d_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  --signal temp1                 : std_logic_vector(63 downto 0);
  --signal temp2                 : std_logic_vector(63 downto 0);
  --signal temp3                 : std_logic_vector(127 downto 0);

begin

  --in_buf: StreamBuffer
    --generic map (
    -- DATA_WIDTH                => DATA_WIDTH + 2,
    -- MIN_DEPTH                 => MIN_DEPTH
    --)
    --port map (
    --  clk                               => clk,
    --  reset                             => reset,
    --  in_valid                          => op2_valid,
    --  in_ready                          => op2_ready,
    --  in_data(65)                       => op2_last,
    --  in_data(64)                       => op2_dvalid,
    --  in_data(63 downto 0)              => op2_data,
    --  out_valid                         => op2_d_valid,
    --  out_ready                         => op2_d_ready,
    --  out_data(65)                      => op2_d_last,
    --  out_data(64)                      => op2_d_dvalid,
    --  out_data(63 downto 0)             => op2_d_data
    --);

  out_buf: StreamBuffer
    generic map (
     DATA_WIDTH                => DATA_WIDTH + 2,
     MIN_DEPTH                 => MIN_DEPTH
    )
    port map (
      clk                               => clk,
      reset                             => reset,
      in_valid                          => out_s_valid,
      in_ready                          => out_s_ready,
      in_data(65)                       => ops_last,
      in_data(64)                       => ops_dvalid,
      in_data(63 downto 0)              => ops_data,
      out_valid                         => out_valid,
      out_ready                         => out_ready,
      out_data(65)                      => out_last,
      out_data(64)                      => out_dvalid,
      out_data(63 downto 0)             => out_data
    );
  discount_sync: StreamSync
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

  ops_last <= op1_last and op2_last;
  ops_dvalid <= op1_dvalid and op2_dvalid;
  
  --mult_process:
  --process(op1_data, op2_data,ops_valid,out_s_ready) is 
  --  variable temp_float_1: float(11 downto -52);
  --  variable temp_float_2: float(11 downto -52);
  --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  --  variable temp_buffer_2: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  --  variable temp_res     : sfixed(2*FIXED_LEFT_INDEX + 1 downto 2*FIXED_RIGHT_INDEX);
  --begin
  --end process;

  seq_process:
  process (clk) is
    --variable temp_float_1: float(11 downto -52);
    --variable temp_float_2: float(11 downto -52);
    variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    variable temp_buffer_2: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    variable temp_res     : sfixed(2*FIXED_LEFT_INDEX + 1 downto 2*FIXED_RIGHT_INDEX);
  begin
    if falling_edge(clk) then
      out_s_valid <= '0';
      ops_ready <= '0';
      if ops_valid = '1' and out_s_ready = '1' then 
        out_s_valid <= '1'; 
        ops_ready <= '1';
        --temp_float_1 := float(op1_data);
        --temp_float_2 := float(op2_data);
        temp_buffer_1 := to_sfixed(op1_data,temp_buffer_1'high,temp_buffer_1'low);
        temp_buffer_2 := to_sfixed(op2_data,temp_buffer_2'high,temp_buffer_2'low);
        temp_res := temp_buffer_1 * temp_buffer_2;
        ops_data <= to_slv(resize( arg => temp_res,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      end if;
    end if;
  end process;

end Behavioral;

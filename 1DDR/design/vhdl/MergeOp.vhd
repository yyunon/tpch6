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
use work.ParallelPatterns_pkg.all; 
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

  constant COUNT_MAX : integer := 6;

-- Define the actual counter signal

  constant dn: positive := 6;
  signal delay: std_ulogic_vector(0 to dn - 1);

  signal initial_count : integer range 0 to COUNT_MAX-1 := 0;
  signal i_count : integer range 0 to COUNT_MAX-1 := 0;
  signal start_count: std_logic;

  signal out_s_valid                : std_logic;
  signal out_s_dvalid               : std_logic;
  signal out_s_last                 : std_logic;
  signal out_s_ready                : std_logic;
  signal out_s_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal ops_valid                : std_logic;
  signal ops_dvalid               : std_logic;
  signal ops_last                 : std_logic := '0';
  signal ops_ready                : std_logic;
  signal ops_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal ops_last_s                 : std_logic;
  -- Emulate sync bbehaviour with only one stream
  signal conv_op1_valid                : std_logic;
  signal conv_op1_dvalid               : std_logic;
  signal conv_op1_last                 : std_logic;
  signal conv_op1_ready                : std_logic;
  signal conv_op1_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal conv_op2_valid                : std_logic;
  signal conv_op2_dvalid               : std_logic;
  signal conv_op2_last                 : std_logic;
  signal conv_op2_ready                : std_logic;
  signal conv_op2_data                 : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal rd_en_d1                : std_logic;
  signal rd_en_d2                : std_logic;
  signal rd_en_d3                : std_logic;
  signal rd_en_d4                : std_logic;
  signal rd_en_d5                : std_logic;
  signal rd_en_d6                : std_logic;

  COMPONENT floating_point_0
    PORT (
      aclk : IN STD_LOGIC;
      s_axis_a_tvalid : IN STD_LOGIC;
      s_axis_a_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_a_tlast : IN STD_LOGIC;
      m_axis_result_tvalid : OUT STD_LOGIC;
      m_axis_result_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axis_result_tlast : OUT STD_LOGIC
    );
  END COMPONENT;

begin


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

      in_valid(0)               => conv_op1_valid,
      in_valid(1)               => conv_op2_valid,
      in_ready(0)               => op1_ready,
      in_ready(1)               => op2_ready,


      out_valid(0)              => ops_valid,
      out_ready(0)              => ops_ready
    );


   inp1_converter: floating_point_0
    PORT MAP (
      aclk => clk,
      s_axis_a_tvalid => op1_valid,
      s_axis_a_tdata => op1_data,
      s_axis_a_tlast => op1_last,
      m_axis_result_tvalid => conv_op1_valid,
      m_axis_result_tdata => conv_op1_data,
      m_axis_result_tlast => conv_op1_last
    );

   inp2_converter: floating_point_0
    PORT MAP (
      aclk => clk,
      s_axis_a_tvalid => op2_valid,
      s_axis_a_tdata => op2_data,
      s_axis_a_tlast => op2_last,
      m_axis_result_tvalid => conv_op2_valid,
      m_axis_result_tdata => conv_op2_data,
      m_axis_result_tlast => conv_op2_last
    );

  mult_process:
  process(conv_op1_data, conv_op2_data,ops_valid,out_s_ready) is 
    variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    variable temp_buffer_2: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    variable temp_res     : sfixed(2*FIXED_LEFT_INDEX + 1 downto 2*FIXED_RIGHT_INDEX);
  begin
    out_s_valid <= '0';
    ops_ready <= '0';
    ops_dvalid <= '0';
    --ops_last_s <= '0';
    if ops_valid = '1' and out_s_ready = '1' then 
      ops_dvalid <= op1_dvalid and op2_dvalid;
      out_s_valid <= '1'; 
      ops_ready <= '1';
      temp_buffer_1 := to_sfixed(conv_op1_data,temp_buffer_1'high,temp_buffer_1'low);
      temp_buffer_2 := to_sfixed(conv_op2_data,temp_buffer_2'high,temp_buffer_2'low);
      temp_res := temp_buffer_1 * temp_buffer_2;
      ops_data <= to_slv(resize( arg => temp_res,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
    end if;
  end process;
  ops_last <= conv_op1_last and conv_op2_last;
  --ops_last <= ops_last_s;
  -- There exists a 6 clk cycles difference between converted data and normal stream. The last signal sohuld be lagged for that amount. Add 6 flip flops. 
  --process (clk)
  --begin
  --  if rising_edge(clk) then
  --    delay <= ops_last_s & delay(0 to dn - 2);
  --  end if;
  --end process;
  --ops_last <= delay(dn-1);

end Behavioral;

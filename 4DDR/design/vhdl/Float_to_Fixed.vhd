-- This code is directly taken from vhlib but async read is implemented
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all; 
use work.Forecast_pkg.all;


entity Float_to_Fixed is 
  generic (

    DATA_WIDTH                  : natural;
    MIN_DEPTH                   : natural

  );
  port (
    clk                         : in  std_logic;
    reset                       : in  std_logic;

    in_valid                    : in  std_logic;
    in_dvalid                   : in  std_logic := '1';
    in_ready                    : out std_logic;
    in_last                     : in  std_logic;
    in_data                     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

    out_valid                   : out  std_logic;
    out_dvalid                  : out  std_logic := '1';
    out_ready                   : in std_logic;
    out_last                    : out  std_logic;
    out_data                    : out  std_logic_vector(DATA_WIDTH - 1 downto 0)

  );
end Float_to_Fixed;

architecture Behavioral of Float_to_Fixed is 

  COMPONENT floating_point_0
    PORT (
      aclk : IN STD_LOGIC;
      s_axis_a_tvalid : IN STD_LOGIC;
      s_axis_a_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_a_tuser : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axis_a_tlast : IN STD_LOGIC;
      m_axis_result_tvalid : OUT STD_LOGIC;
      m_axis_result_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axis_result_tuser : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axis_result_tlast : OUT STD_LOGIC
    );
  END COMPONENT;

  signal conv_data_valid        : std_logic :='0';
  signal conv_data_dum          : std_logic :='0';
  signal conv_data_dvalid       : std_logic :='0';
  signal conv_data_last         : std_logic :='0';
  signal conv_data              : std_logic_vector(63 downto 0) := (others => '0');

  signal ops_valid              : std_logic;
  signal ops_dvalid              : std_logic;
  signal ops_ready              : std_logic;
  signal ops_last               : std_logic;
  signal ops_data               : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin 

   -- Synchronize the operand stream
   op_in_sync: StreamSlice
    generic map (
        DATA_WIDTH => DATA_WIDTH + 2
        --MIN_DEPTH => 1
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid                  => in_valid,
      in_ready                  => in_ready,
      in_data(65)               => in_last,
      in_data(64)               => in_dvalid,
      in_data(63 downto 0)      => in_data,

      out_valid                 => ops_valid,
      out_ready                 => ops_ready,
      out_data(65)              => ops_last,
      out_data(64)              => ops_dvalid,
      out_data(63 downto 0)     => ops_data
    );   

   data_converter: floating_point_0
    PORT MAP (
      aclk => clk,
      s_axis_a_tvalid => ops_valid,
      s_axis_a_tdata => ops_data,
      s_axis_a_tuser(1) => ops_dvalid,
      s_axis_a_tuser(0) => '0',
      s_axis_a_tlast => ops_last,
      m_axis_result_tvalid => conv_data_valid,
      m_axis_result_tdata => conv_data,
      m_axis_result_tuser(1) => conv_data_dvalid,
      m_axis_result_tuser(0) => conv_data_dum,
      m_axis_result_tlast => conv_data_last
    );

  out_buf: StreamBuffer
    generic map (
     DATA_WIDTH                => DATA_WIDTH + 2,
     MIN_DEPTH                 => MIN_DEPTH
    )
    port map (
      clk                               => clk,
      reset                             => reset,
      in_valid                          => conv_data_valid,
      in_ready                          => ops_ready,
      in_data(65)                       => conv_data_last,
      in_data(64)                       => conv_data_dvalid,
      in_data(63 downto 0)              => conv_data,

      out_valid                         => out_valid,
      out_ready                         => out_ready,
      out_data(65)                      => out_last,
      out_data(64)                      => out_dvalid,
      out_data(63 downto 0)             => out_data
    );

end Behavioral;

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
    INPUT_MIN_DEPTH             : natural;
    OUTPUT_MIN_DEPTH            : natural;
    CONVERTER_TYPE              : string -- := "flopoco" := "xilinx_ip";

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
  -- Enumeration type for our state machine.
  -- There is this hw delay of 7 for flopoco
  -- and 9/2 for xilinx floating ip. Even though
  -- the convention is not good, we should code a
  -- state machine which will iterate those cycle counts
  -- and control the converter datapath/ input-output streams.
  -- TODO: Is there a better way though?
  type state_t is (start, 
                   busy_1, 
                   busy_2, 
                   busy_3, 
                   busy_4,
                   busy_5,
                   busy_6,
                   busy_7,
                   busy_8,
                   busy_9,
                   done,
                   idle);
                   
  signal state_slv                  : std_logic_vector(4 downto 0);
  signal state, state_next          : state_t;

  -- Floating  point IP used by xilinx
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
  --
  -- Flopoco functions 
  component InputIEEE_11_52_to_11_52 is
    port ( clk, rst : in std_logic;
            X : in  std_logic_vector(63 downto 0);
            R : out  std_logic_vector(10+53+2 downto 0)   );
  end component;

  component FP2Fix_11_52M_18_45_S_NT_F400_uid3 is
    port ( clk, rst : in std_logic;
            I : in  std_logic_vector(10+53+2 downto 0);
            O : out  std_logic_vector(63 downto 0)   );
  end component;
  --

  signal conv_data_valid        : std_logic :='0';
  signal conv_data_ready        : std_logic :='0';
  signal conv_data_dum          : std_logic :='0';
  signal conv_data_dvalid       : std_logic :='0';
  signal conv_data_last         : std_logic :='0';
  signal conv_data              : std_logic_vector(63 downto 0) := (others => '0');

  signal ops_valid              : std_logic;
  signal ops_dvalid             : std_logic;
  signal ops_ready              : std_logic;
  signal ops_last               : std_logic;
  signal ops_data               : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal flopoco_data           : std_logic_vector(DATA_WIDTH + 1 downto 0);
  signal flopoco_input          : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal result_valid           : std_logic;
  signal result_dvalid          : std_logic;
  signal result_last            : std_logic;
  signal result_data            : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin 
  with state select state_slv <= 
               "00000" when start,
               "00001" when busy_1,
               "00010" when busy_2,
               "00011" when busy_3,
               "00100" when busy_4,
               "00101" when busy_5,
               "00110" when busy_6,
               "00111" when busy_7,
               "01000" when busy_8,
               "01001" when busy_9,
               "01010" when done,
               "01011" when idle,
               "10000" when others;

   op_in_sync: StreamBuffer
    generic map (
        DATA_WIDTH => DATA_WIDTH + 2,
        MIN_DEPTH => INPUT_MIN_DEPTH
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

xilinx_converter:
if CONVERTER_TYPE = "xilinx_ip" generate
   data_converter: floating_point_0
    PORT MAP (
      aclk => clk,
      s_axis_a_tvalid => ops_valid,
      s_axis_a_tdata => ops_data,
      s_axis_a_tuser(1) => ops_dvalid,
      s_axis_a_tuser(0) => '0',
      s_axis_a_tlast => ops_last,
      m_axis_result_tvalid => result_valid,
      m_axis_result_tdata => conv_data,
      m_axis_result_tuser(1) => result_dvalid,
      m_axis_result_tuser(0) => conv_data_dum,
      m_axis_result_tlast => result_last
    );
    -- Xilinx ip clk cycles depends heavily on the configuration:
    -- The current one uses sth around 2 clk cycles, not pipelined.
    fsm_process:
    process(state,
            conv_data_ready,

            result_data,
            result_valid,

            ops_data,
            ops_last,
            ops_valid
            )
    begin
      state_next <= state;

      ops_ready <= '0';

      conv_data_dvalid <= '0';
      conv_data_valid <= '0';
      conv_data_last <= '0';

      case state is
        when idle =>
          if (conv_data_ready = '1') and (ops_valid = '1') then
            state_next <= start;
          end if;
        when start =>
          state_next <= busy_1;
        when busy_1 =>
          state_next <= busy_2;
        when busy_2 =>
          state_next <= busy_3;
        when busy_3 =>
          state_next <= busy_4;
        when busy_4 =>
          state_next <= busy_5;
        when busy_5 =>
          state_next <= busy_6;
        when busy_6 =>
          state_next <= done;
        when done =>
          ops_ready <= '1';
          conv_data_last <= ops_last; -- This propag. the last
          conv_data_dvalid <= '1';
          conv_data_valid <= result_valid;
          state_next <= idle;
        when others =>
          state_next <= idle;
      end case;
    end process;
  end generate;

  flopoco_converter:
  if CONVERTER_TYPE = "flopoco" generate
    -- Flopoco has its own type, which is simply IEEE.
    -- Yet, it uses flags for normalization etc. 
    -- First, convert it to flopoco then to fixed point in this 
    -- part. 
    -- NT => Non truncated.
    -- [45,-18]
    ieee_to_flopoco: InputIEEE_11_52_to_11_52
      port map ( 
         clk                      => clk,
         rst                      => reset,
         X                        => ops_data,
         R                        => flopoco_data
      );

    flopoco_to_fixed: FP2Fix_11_52M_18_45_S_NT_F400_uid3
      port map ( 
         clk                      => clk,
         rst                      => reset,
         I                        => flopoco_data,
         O                        => conv_data 
      );
    -- Flopoco converter utilizes 5 clk cycles to finish.
    fsm_process:
    process(state,
            conv_data_ready,

            result_data,
            result_valid,

            ops_data,
            ops_last,
            ops_valid
            )
    begin
      state_next <= state;

      ops_ready <= '0';

      conv_data_dvalid <= '0';
      conv_data_valid <= '0';
      conv_data_last <= '0';

      case state is
        when idle =>
          if (conv_data_ready = '1') and (ops_valid = '1') then
            state_next <= start;
          end if;
        when start =>
          state_next <= busy_1;
        when busy_1 =>
          state_next <= busy_2;
        when busy_2 =>
          state_next <= busy_3;
        when busy_3 =>
          state_next <= busy_4;
        when busy_4 =>
          state_next <= busy_5;
        when busy_5 =>
          state_next <= done;
        when done =>
          ops_ready <= '1';
          conv_data_last <= ops_last; -- This propag. the last
          conv_data_dvalid <= '1';
          conv_data_valid <= result_valid;
          state_next <= idle;
        when others =>
          state_next <= idle;
      end case;
    end process;
  end generate;

  out_buf: StreamBuffer
    generic map (
     DATA_WIDTH                => DATA_WIDTH + 2,
     MIN_DEPTH                 => OUTPUT_MIN_DEPTH
    )
    port map (
      clk                               => clk,
      reset                             => reset,
      in_valid                          => conv_data_valid,
      in_ready                          => conv_data_ready,
      in_data(65)                       => conv_data_last,
      in_data(64)                       => conv_data_dvalid,
      in_data(63 downto 0)              => conv_data,

      out_valid                         => out_valid,
      out_ready                         => out_ready,
      out_data(65)                      => out_last,
      out_data(64)                      => out_dvalid,
      out_data(63 downto 0)             => out_data
    );
   

  clk_process: 
  process(clk)
  begin
    if clk'event and clk = '1' then
      state <= state_next;
      if reset = '1' then
        state <= idle;
      end if;
    end if;
  end process;
end Behavioral;

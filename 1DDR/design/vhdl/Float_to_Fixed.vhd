-- This code is directly taken from vhlib but async read is implemented
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;
ENTITY Float_to_Fixed IS
  GENERIC (

    DATA_WIDTH : NATURAL;
    INPUT_MIN_DEPTH : NATURAL;
    OUTPUT_MIN_DEPTH : NATURAL;
    CONVERTER_TYPE : STRING -- := "flopoco" := "xilinx_ip";

  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    in_valid : IN STD_LOGIC;
    in_dvalid : IN STD_LOGIC := '1';
    in_ready : OUT STD_LOGIC;
    in_last : IN STD_LOGIC;
    in_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    out_valid : OUT STD_LOGIC;
    out_dvalid : OUT STD_LOGIC := '1';
    out_ready : IN STD_LOGIC;
    out_last : OUT STD_LOGIC;
    out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)

  );
END Float_to_Fixed;

ARCHITECTURE Behavioral OF Float_to_Fixed IS
  -- Enumeration type for our state machine.
  -- There is this hw delay of 7 for flopoco
  -- and 9/2 for xilinx floating ip. Even though
  -- the convention is not good, we should code a
  -- state machine which will iterate those cycle counts
  -- and control the converter datapath/ input-output streams.
  -- TODO: Is there a better way though?
  TYPE state_t IS (start,
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

  SIGNAL state_slv : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL state, state_next : state_t;

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
  COMPONENT InputIEEE_11_52_to_11_52 IS
    PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      R : OUT STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0));
  END COMPONENT;
  COMPONENT FP2Fix_11_52M_18_45_S_T_F400_uid2 IS
    PORT (
      clk : IN STD_LOGIC;
      I : IN STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
      O : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
  END COMPONENT;
  --

  SIGNAL conv_data_valid : STD_LOGIC := '0';
  SIGNAL conv_data_ready : STD_LOGIC := '0';
  SIGNAL conv_data_dum : STD_LOGIC := '0';
  SIGNAL conv_data_dvalid : STD_LOGIC := '0';
  SIGNAL conv_data_last : STD_LOGIC := '0';
  SIGNAL conv_data : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_dvalid : STD_LOGIC;
  SIGNAL ops_ready : STD_LOGIC;
  SIGNAL ops_last : STD_LOGIC;
  SIGNAL ops_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL flopoco_data : STD_LOGIC_VECTOR(DATA_WIDTH + 1 DOWNTO 0);
  SIGNAL flopoco_input : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL result_valid : STD_LOGIC;
  SIGNAL result_dvalid : STD_LOGIC;
  SIGNAL result_last : STD_LOGIC;
  SIGNAL result_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

BEGIN
  WITH state SELECT state_slv <=
    "00000" WHEN start,
    "00001" WHEN busy_1,
    "00010" WHEN busy_2,
    "00011" WHEN busy_3,
    "00100" WHEN busy_4,
    "00101" WHEN busy_5,
    "00110" WHEN busy_6,
    "00111" WHEN busy_7,
    "01000" WHEN busy_8,
    "01001" WHEN busy_9,
    "01010" WHEN done,
    "01011" WHEN idle,
    "10000" WHEN OTHERS;

  op_in_sync : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => in_valid,
    in_ready => in_ready,
    in_data(65) => in_last,
    in_data(64) => in_dvalid,
    in_data(63 DOWNTO 0) => in_data,

    out_valid => ops_valid,
    out_ready => ops_ready,
    out_data(65) => ops_last,
    out_data(64) => ops_dvalid,
    out_data(63 DOWNTO 0) => ops_data
  );

  none_converter :
  IF CONVERTER_TYPE = "none" GENERATE
    conv_data <= ops_data;
    conv_data_last <= ops_last;
    conv_data_dvalid <= ops_dvalid;
    conv_data_valid <= ops_valid;
    ops_ready <= conv_data_ready;
  END GENERATE;

  xilinx_converter :
  IF CONVERTER_TYPE = "xilinx_ip" GENERATE
    data_converter : floating_point_0
    PORT MAP(
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
    fsm_process :
    PROCESS (state,
      conv_data_ready,

      result_data,
      result_valid,

      ops_data,
      ops_last,
      ops_valid
      )
    BEGIN
      state_next <= state;

      ops_ready <= '0';

      conv_data_dvalid <= '0';
      conv_data_valid <= '0';
      conv_data_last <= '0';

      CASE state IS
        WHEN idle =>
          IF (conv_data_ready = '1') AND (ops_valid = '1') THEN
            state_next <= start;
          END IF;
        WHEN start =>
          state_next <= busy_1;
        WHEN busy_1 =>
          state_next <= busy_2;
        WHEN busy_2 =>
          state_next <= busy_3;
        WHEN busy_3 =>
          state_next <= busy_4;
        WHEN busy_4 =>
          state_next <= busy_5;
        WHEN busy_5 =>
          state_next <= busy_6;
        WHEN busy_6 =>
          state_next <= done;
        WHEN done =>
          ops_ready <= '1';
          conv_data_last <= ops_last; -- This propag. the last
          conv_data_dvalid <= '1';
          conv_data_valid <= result_valid;
          state_next <= idle;
        WHEN OTHERS =>
          state_next <= idle;
      END CASE;
    END PROCESS;
    clk_process :
    PROCESS (clk)
    BEGIN
      IF clk'event AND clk = '1' THEN
        state <= state_next;
        IF reset = '1' THEN
          state <= idle;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  flopoco_converter :
  IF CONVERTER_TYPE = "flopoco_big_numbers" GENERATE
    -- Flopoco has its own type, which is simply IEEE.
    -- Yet, it uses flags for normalization etc. 
    -- First, convert it to flopoco then to fixed point in this 
    -- part. 
    -- NT => Non truncated.
    -- [45,-18]
    ieee_to_flopoco : InputIEEE_11_52_to_11_52
    PORT MAP(
      clk => clk,
      rst => reset,
      X => ops_data,
      R => flopoco_data
    );

    flopoco_to_fixed : FP2Fix_11_52M_18_45_S_T_F400_uid2
    PORT MAP(
      clk => clk,
      I => flopoco_data,
      O => conv_data
    );
    -- Flopoco converter utilizes 5 clk cycles to finish.
    fsm_process :
    PROCESS (state,
      conv_data_ready,

      result_data,
      result_valid,

      ops_data,
      ops_last,
      ops_valid
      )
    BEGIN
      state_next <= state;

      ops_ready <= '0';

      conv_data_dvalid <= '0';
      conv_data_valid <= '0';
      conv_data_last <= '0';

      CASE state IS
        WHEN idle =>
          IF (conv_data_ready = '1') AND (ops_valid = '1') THEN
            state_next <= start;
          END IF;
        WHEN start =>
          state_next <= busy_1;
        WHEN busy_1 =>
          state_next <= busy_2;
        WHEN busy_2 =>
          state_next <= busy_3;
        WHEN busy_3 =>
          state_next <= busy_4;
        WHEN busy_4 =>
          state_next <= busy_5;
        WHEN busy_5 =>
          state_next <= busy_6;
        WHEN busy_6 =>
          state_next <= done;
        WHEN done =>
          ops_ready <= '1';
          conv_data_last <= ops_last; -- This propag. the last
          conv_data_dvalid <= '1';
          conv_data_valid <= result_valid;
          state_next <= idle;
        WHEN OTHERS =>
          state_next <= idle;
      END CASE;
    END PROCESS;
    clk_process :
    PROCESS (clk)
    BEGIN
      IF clk'event AND clk = '1' THEN
        state <= state_next;
        IF reset = '1' THEN
          state <= idle;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  out_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => OUTPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => conv_data_valid,
    in_ready => conv_data_ready,
    in_data(65) => conv_data_last,
    in_data(64) => conv_data_dvalid,
    in_data(63 DOWNTO 0) => conv_data,

    out_valid => out_valid,
    out_ready => out_ready,
    out_data(65) => out_last,
    out_data(64) => out_dvalid,
    out_data(63 DOWNTO 0) => out_data
  );
END Behavioral;
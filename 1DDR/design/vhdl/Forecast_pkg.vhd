----------------------------------------------------------------------------------
-- Author: Yuksel Yonsel
-- Forecast implementation
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

PACKAGE Forecast_pkg IS

  COMPONENT ReduceMultiEpc IS
    GENERIC (

      -- Width of a data word.
      EPC : NATURAL;
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      DATA_WIDTH : NATURAL

    );
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;

      in_valid : IN STD_LOGIC;
      in_ready : OUT STD_LOGIC;
      in_data : IN STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

      out_valid : OUT STD_LOGIC;
      out_ready : IN STD_LOGIC;
      out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)

    );
  END COMPONENT;

  COMPONENT PU IS
    GENERIC (
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      DATA_WIDTH : NATURAL;
      INDEX_WIDTH : INTEGER;
      CONVERTERS : STRING := "";
      ILA : STRING := ""

    );
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;

      l_quantity_valid : IN STD_LOGIC;
      l_quantity_ready : OUT STD_LOGIC;
      l_quantity_dvalid : IN STD_LOGIC;
      l_quantity_last : IN STD_LOGIC;
      l_quantity : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      l_extendedprice_valid : IN STD_LOGIC;
      l_extendedprice_ready : OUT STD_LOGIC;
      l_extendedprice_dvalid : IN STD_LOGIC;
      l_extendedprice_last : IN STD_LOGIC;
      l_extendedprice : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      l_discount_valid : IN STD_LOGIC;
      l_discount_ready : OUT STD_LOGIC;
      l_discount_dvalid : IN STD_LOGIC;
      l_discount_last : IN STD_LOGIC;
      l_discount : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      l_shipdate_valid : IN STD_LOGIC;
      l_shipdate_ready : OUT STD_LOGIC;
      l_shipdate_dvalid : IN STD_LOGIC;
      l_shipdate_last : IN STD_LOGIC;
      l_shipdate : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      sum_out_valid : OUT STD_LOGIC;
      sum_out_ready : IN STD_LOGIC;
      sum_out_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
  END COMPONENT;
  COMPONENT Float_to_Fixed IS
    GENERIC (

      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
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
  END COMPONENT;

  COMPONENT FILTER IS
    GENERIC (

      -- Width of a data word.
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      DATA_WIDTH : NATURAL;
      INPUT_MIN_DEPTH : INTEGER;
      OUTPUT_MIN_DEPTH : INTEGER;
      FILTERTYPE : STRING := ""

    );
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;

      in_valid : IN STD_LOGIC;
      in_dvalid : IN STD_LOGIC := '1';
      in_ready : OUT STD_LOGIC;
      in_last : IN STD_LOGIC;
      in_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

      out_valid : OUT STD_LOGIC;
      out_ready : IN STD_LOGIC;
      out_data : OUT STD_LOGIC

    );
  END COMPONENT;

  COMPONENT MergeOp IS
    GENERIC (

      -- Width of the stream data vector.
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      DATA_WIDTH : NATURAL;
      INPUT_MIN_DEPTH : NATURAL;
      OUTPUT_MIN_DEPTH : NATURAL;
      OPERATOR : STRING := ""
    );
    PORT (

      -- Rising-edge sensitive clock.
      clk : IN STD_LOGIC;

      -- Active-high synchronous reset.
      reset : IN STD_LOGIC;

      --OP1 Input stream.
      op1_valid : IN STD_LOGIC;
      op1_last : IN STD_LOGIC;
      op1_dvalid : IN STD_LOGIC := '1';
      op1_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
      op1_ready : OUT STD_LOGIC;

      --OP2 Input stream.
      op2_valid : IN STD_LOGIC;
      op2_last : IN STD_LOGIC;
      op2_dvalid : IN STD_LOGIC := '1';
      op2_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
      op2_ready : OUT STD_LOGIC;

      -- Output stream.
      out_valid : OUT STD_LOGIC;
      out_last : OUT STD_LOGIC;
      out_ready : IN STD_LOGIC;
      out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
      out_dvalid : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT SumOp IS
    GENERIC (

      -- Width of the stream data vector.
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      DATA_WIDTH : NATURAL;
      DATA_TYPE : STRING := ""
    );
    PORT (

      -- Rising-edge sensitive clock.
      clk : IN STD_LOGIC;

      -- Active-high synchronous reset.
      reset : IN STD_LOGIC;

      --OP1 Input stream.
      op1_valid : IN STD_LOGIC;
      op1_dvalid : IN STD_LOGIC := '1';
      op1_ready : OUT STD_LOGIC;
      op1_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      --OP2 Input stream.
      op2_valid : IN STD_LOGIC;
      op2_dvalid : IN STD_LOGIC := '1';
      op2_ready : OUT STD_LOGIC;
      op2_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

      -- Output stream.
      out_valid : OUT STD_LOGIC;
      out_ready : IN STD_LOGIC;
      out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
      out_dvalid : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT ReduceStage IS
    GENERIC (
      FIXED_LEFT_INDEX : INTEGER;
      FIXED_RIGHT_INDEX : INTEGER;
      INDEX_WIDTH : INTEGER := 32;
      TAG_WIDTH : INTEGER := 1
    );
    PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;

      in_valid : IN STD_LOGIC;
      in_dvalid : IN STD_LOGIC := '1';
      in_ready : OUT STD_LOGIC;
      in_last : IN STD_LOGIC;
      in_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

      out_valid : OUT STD_LOGIC;
      out_ready : IN STD_LOGIC;
      out_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)

    );
  END COMPONENT;

END Forecast_pkg;
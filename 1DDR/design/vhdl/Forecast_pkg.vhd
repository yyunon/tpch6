----------------------------------------------------------------------------------
-- Author: Yuksel Yonsel
-- Forecast implementation
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

package Forecast_pkg is 
  
  component ALU is
    generic (

      -- Width of a data word.
      FIXED_LEFT_INDEX            : INTEGER;
      FIXED_RIGHT_INDEX           : INTEGER;
      DATA_WIDTH                       : natural;

      ALUTYPE                        : string := ""

    );
    port (
      clk                       : in  std_logic;
      reset                     : in  std_logic;

      in_valid                     : in  std_logic;
      in_dvalid                    : in  std_logic := '1';
      in_ready                     : out std_logic;
      in_last                      : in  std_logic;
      in_data                      : in  std_logic_vector(63 downto 0);
      
      out_valid                    : out std_logic;
      out_ready                    : in  std_logic;
      out_data                     : out std_logic_vector(63 downto 0)

    );
  end component;
  
 component MergeOp is
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
    op2_data                     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    op2_ready                    : out  std_logic;

    -- Output stream.
    out_valid                    : out std_logic;
    out_last                     : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out_dvalid                   : out std_logic
  );
end component;

 component SumOp is
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
end component;
  
  component ReduceStage is
  generic (
    FIXED_LEFT_INDEX            : INTEGER;
    FIXED_RIGHT_INDEX           : INTEGER;
    INDEX_WIDTH : integer := 32;
    TAG_WIDTH   : integer := 1
  );
  port (
    clk                          : in  std_logic;
    reset                        : in  std_logic;
    
    in_valid                     : in  std_logic;
    in_dvalid                    : in  std_logic  := '1';
    in_ready                     : out std_logic;
    in_last                      : in  std_logic;
    in_data                      : in  std_logic_vector(63 downto 0);
    
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(63 downto 0)
    
  );
end component;

end Forecast_pkg;

----------------------------------------------------------------------------------
-- Author: Yuksel Yonsel
-- Forecast implementation
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.fixed_pkg.all;

--library ieee_proposed;
--use ieee_proposed.fixed_pkg.all;


package Forecast_pkg is 
  

  -- These are adapted from float_pkg.
  type float is array (INTEGER range <>) of STD_LOGIC;  -- main type
  constant float_check_error : BOOLEAN    := true;  -- Turn on NAN and overflow processing
  constant float_denormalize : BOOLEAN    := true;  -- Use IEEE extended floating
                                        -- point (Denormalized numbers)
  constant NAFP               : float (0 downto 1)            := (others => '0');
    -- purpose: Checks for a valid floating point number
  type valid_fpstate is (nan,           -- Signaling NaN (C FP_NAN)
                         quiet_nan,     -- Quiet NaN (C FP_NAN)
                         neg_inf,       -- Negative infinity (C FP_INFINITE)
                         neg_normal,    -- negative normalized nonzero
                         neg_denormal,  -- negative denormalized (FP_SUBNORMAL)
                         neg_zero,      -- -0 (C FP_ZERO)
                         pos_zero,      -- +0 (C FP_ZERO)
                         pos_denormal,  -- Positive denormalized (FP_SUBNORMAL)
                         pos_normal,    -- positive normalized nonzero
                         pos_inf,       -- positive infinity
                         isx);          -- at least one input is unknown

  function minx (l, r : INTEGER)
    return INTEGER;
  function to_01 (
    arg  : float;                       -- floating point input
    XMAP : STD_LOGIC := '0')
    return float;
  function Class (
    x           : float;                -- floating point input
    check_error : BOOLEAN := float_check_error)   -- check for errors
    return valid_fpstate;
  function float_to_sfixed (
    arg                     : float;    -- fp input
    constant left_index     : INTEGER;  -- integer part
    constant right_index    : INTEGER;  -- fraction part
    constant check_error    : BOOLEAN := float_check_error;  -- check for errors
    constant denormalize    : BOOLEAN := float_denormalize)
    return sfixed;
    
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

package body Forecast_pkg is 

    -- purpose: Removes meta-logical values from FP string
  -- purpose: Removes meta-logical values from FP string
  function to_01 (
    arg  : float;                       -- floating point input
    XMAP : STD_LOGIC := '0')
    return float is
    variable BAD_ELEMENT : BOOLEAN := false;
    variable RESULT      : float (arg'range);
  begin  -- function to_01
    if (arg'length < 1) then
      assert NO_WARNING
        report "FLOAT_GENERIC_PKG.TO_01: null detected, returning NAFP"
        severity warning;
      return NAFP;
    end if;
    for I in RESULT'range loop
      case arg(I) is
        when '0' | 'L' => RESULT(I)   := '0';
        when '1' | 'H' => RESULT(I)   := '1';
        when others    => BAD_ELEMENT := true;
      end case;
    end loop;
    if BAD_ELEMENT then
      RESULT := (others => XMAP);
    end if;
    return RESULT;
  end function to_01;

  -- Returns the class which X falls into
  function Class (
    x           : float;                -- floating point input
    check_error : BOOLEAN := float_check_error)   -- check for errors
    return valid_fpstate is
    constant fraction_width : INTEGER := -minx(x'low, x'low);  -- length of FP output fraction
    constant exponent_width : INTEGER := x'high;  -- length of FP output exponent
    variable arg            : float (exponent_width downto -fraction_width);
  begin  -- class
    if (arg'length < 1 or fraction_width < 3 or exponent_width < 3
        or x'left < x'right) then
      report "FLOAT_GENERIC_PKG.CLASS: " &
        "Floating point number detected with a bad range"
        severity error;
      return isx;
    end if;
    -- Check for "X".
    arg := to_01 (x, 'X');
    if (arg(0) = 'X') then
      return isx;                       -- If there is an X in the number
      -- Special cases, check for illegal number
    elsif check_error and
      and_reduce (STD_LOGIC_VECTOR (arg (exponent_width-1 downto 0)))
       = '1' then                       -- Exponent is all "1".
      if or_reduce (STD_LOGIC_VECTOR (arg (-1 downto -fraction_width)))
         /= '0' then  -- Fraction must be all "0" or this is not a number.
        if (arg(-1) = '1') then         -- From "W. Khan - IEEE standard
          return nan;            -- 754 binary FP Signaling nan (Not a number)
        else
          return quiet_nan;
        end if;
        -- Check for infinity
      elsif arg(exponent_width) = '0' then
        return pos_inf;                 -- Positive infinity
      else
        return neg_inf;                 -- Negative infinity
      end if;
      -- check for "0"
    elsif or_reduce (STD_LOGIC_VECTOR (arg (exponent_width-1 downto 0)))
       = '0' then                       -- Exponent is all "0"
      if or_reduce (STD_LOGIC_VECTOR (arg(-1 downto -fraction_width)))
         = '0' then                     -- Fraction is all "0"
        if arg(exponent_width) = '0' then
          return pos_zero;              -- Zero
        else
          return neg_zero;
        end if;
      else
        if arg(exponent_width) = '0' then
          return pos_denormal;          -- Denormal number (ieee extended fp)
        else
          return neg_denormal;
        end if;
      end if;
    else
      if arg(exponent_width) = '0' then
        return pos_normal;              -- Normal FP number
      else
        return neg_normal;
      end if;
    end if;
  end function Class;

  -- purpose: Converts a float to sfixed
  function float_to_sfixed (
    arg                     : float;    -- fp input
    constant left_index     : INTEGER;  -- integer part
    constant right_index    : INTEGER;  -- fraction part
    constant check_error    : BOOLEAN := float_check_error;  -- check for errors
    constant denormalize    : BOOLEAN := float_denormalize)
    return sfixed is
    constant fraction_width : INTEGER                                := -minx(arg'low, arg'low);  -- length of FP output fraction
    constant exponent_width : INTEGER                                := arg'high;  -- length of FP output exponent
    constant size           : INTEGER                                := left_index - right_index + 4;  -- unsigned size
    variable expon_base     : INTEGER;  -- exponent offset
    variable validfp        : valid_fpstate;     -- Valid FP state
    variable exp            : INTEGER;  -- Exponent
    variable sign           : BOOLEAN;  -- true if negative
    variable expon          : UNSIGNED (exponent_width-1 downto 0);  -- Vectorized exponent
    -- Base to divide fraction by
    variable frac           : UNSIGNED (size-2 downto 0)             := (others => '0');  -- Fraction
    variable frac_shift     : UNSIGNED (size-2 downto 0);    -- Fraction shifted
    variable shift          : INTEGER;
    variable rsigned        : SIGNED (size-1 downto 0);  -- signed version of result
    variable result_big     : sfixed (left_index downto right_index-3);
    variable result         : sfixed (left_index downto right_index) := (others => '0');  -- result
  begin  -- function to_ufixed
    validfp := class (arg, check_error);
    classcase : case validfp is
      when isx | nan | quiet_nan =>
        result := (others => 'X');
      when pos_zero | neg_zero =>
        result := (others => '0');      -- return 0
      when neg_inf =>
        result (left_index) := '1';     -- return smallest negative number
      when pos_inf =>
        result              := (others => '1');  -- return largest number
        result (left_index) := '0';
      when others =>
        expon_base := 2**(exponent_width-1) -1;  -- exponent offset
        if arg(exponent_width) = '0' then
          sign := false;
        else
          sign := true;
        end if;
        -- Figure out the fraction
        if (validfp = pos_denormal or validfp = neg_denormal)
          and denormalize then
          exp              := -expon_base +1;
          frac (frac'high) := '0';      -- Add the "1.0".
        else
          -- exponent /= '0', normal floating point
          expon                   := UNSIGNED(arg (exponent_width-1 downto 0));
          expon(exponent_width-1) := not expon(exponent_width-1);
          exp                     := to_integer (SIGNED(expon)) +1;
          frac (frac'high)        := '1';        -- Add the "1.0".
        end if;
        shift := (frac'high - 3 + right_index) - exp;
        if fraction_width > frac'high then       -- Can only use size-2 bits
          frac (frac'high-1 downto 0) := UNSIGNED (STD_LOGIC_VECTOR (arg(-1 downto
                                                               -frac'high)));
        else                            -- can use all bits
          frac (frac'high-1 downto frac'high-fraction_width) :=
            UNSIGNED (STD_LOGIC_VECTOR (arg(-1 downto -fraction_width)));
        end if;
        frac_shift := frac srl shift;
        if shift < 0 then               -- Overflow
          frac := (others => '1');
        else
          frac := frac_shift;
        end if;
        if not sign then
          rsigned := SIGNED("0" & frac);
        else
          rsigned := -(SIGNED("0" & frac));
        end if;
        result_big := to_sfixed (arg         => STD_LOGIC_VECTOR(rsigned),
                                 left_index  => left_index,
                                 right_index => (right_index-3));
        result := resize (arg            => result_big,
                          left_index     => left_index,
                          right_index    => right_index,
                          round_style    => fixed_round_style,
                          overflow_style => fixed_overflow_style);
    end case classcase;
    return result;
  end function float_to_sfixed;

  -- Special version of "minimum" to do some boundary checking
  function minx (l, r : INTEGER)
    return INTEGER is
  begin  -- function minimum
    if (L = INTEGER'low or R = INTEGER'low) then
      report "FLOAT_GENERIC_PKG: Unbounded number passed, was a literal used?"
        severity error;
      return 0;
    end if;
    if L > R then return R;
    else return L;
    end if;
  end function minx;
end;

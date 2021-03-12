-- This file is adapted from floating point package.
library IEEE;
use IEEE.MATH_REAL.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_MISC.all;
use IEEE.fixed_float_types.all;

--library ieee_proposed;
--use ieee_proposed.fixed_pkg.all;
use work.fixed_generic_pkg_mod.all;

package float_pkg_mod is

-- generic (
  -- Defaults for sizing routines, when you do a "to_float" this will be
  -- the default size.  Example float32 would be 8 and 23 (8 downto -23)
  constant float_exponent_width : NATURAL    := 11;
  constant float_fraction_width : NATURAL    := 52;
  -- Rounding algorithm, "round_nearest" is default, other valid values
  -- are "round_zero" (truncation), "round_inf" (round up), and
  -- "round_neginf" (round down)
  constant float_round_style    : round_type := round_nearest;
  -- Denormal numbers (very small numbers near zero) true or false
  constant float_denormalize    : BOOLEAN    := true;
  -- Turns on NAN processing (invalid numbers and overflow) true of false
  constant float_check_error    : BOOLEAN    := true;
  -- Guard bits are added to the bottom of every operation for rounding.
  -- any natural number (including 0) are valid.
  constant float_guard_bits     : NATURAL    := 3;
  -- If TRUE, then turn off warnings on "X" propagation
  constant no_warning : BOOLEAN := (false
                                                 );
  -- IEEE 754 double precision
  -- the package which calls this one.
  type UNRESOLVED_float is array (INTEGER range <>) of STD_ULOGIC;  -- main type
  subtype U_float is UNRESOLVED_float;

  subtype float is UNRESOLVED_float;

  subtype UNRESOLVED_float64 is UNRESOLVED_float (11 downto -52);
  alias U_float64 is UNRESOLVED_float64;
  subtype float64 is float (11 downto -52);

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

--------------------
  --function minx (l, r : INTEGER)
  --  return INTEGER;
--------------------

  --function to_01 (
  --  arg  : UNRESOLVED_float;                       -- floating point input
  --  XMAP : STD_LOGIC := '0')
  --  return UNRESOLVED_float;

--------------------
  function Class (
    x           : float;                -- floating point input
    check_error : BOOLEAN := float_check_error)   -- check for errors
    return valid_fpstate;
--------------------

  function float_to_sfixed (
    arg                     : float;    -- fp input
    constant left_index     : INTEGER;  -- integer part
    constant right_index    : INTEGER;  -- fraction part
    constant check_error    : BOOLEAN := float_check_error;  -- check for errors
    constant denormalize    : BOOLEAN := float_denormalize)
    return sfixed;

end float_pkg_mod;

------------------------------------------------------------------------
------------------------------PACKAGE BODY------------------------------
------------------------------------------------------------------------
package body float_pkg_mod is
-------------------------------------------------------------------------------------
  -- Special version of "minimum" to do some boundary checking
  --function minx (l, r : INTEGER)
  --  return INTEGER is
  --begin  -- function minimum
  --  if (L = INTEGER'low or R = INTEGER'low) then
  --    -- pragma translate_off
  --    report "FLOAT_GENERIC_PKG: Unbounded number passed, was a literal used?"
  --      severity error;
  --    -- pragma translate_on
  --    return 0;
  --  end if;
  --  if L > R then return R;
  --  else return L;
  --  end if;
  --end function minx;
  -- purpose: Removes meta-logical values from FP string
  --function to_01 (
  --  arg  : UNRESOLVED_float;                       -- floating point input
  --  XMAP : STD_LOGIC := '0')
  --  return float is
  --  variable BAD_ELEMENT : BOOLEAN := false;
  --  variable result      : float (arg'range);
  --begin  -- function to_01
  --  if (arg'length < 1) then
  --    -- pragma translate_off
  --    assert NO_WARNING
  --      report "FLOAT_GENERIC_PKG.TO_01: null detected, returning NAFP"
  --      severity warning;
  --    -- pragma translate_on
  --    return NAFP;
  --  end if;
  --  result :=  UNRESOLVED_float(std_logic_vector(to_01(unsigned(std_logic_vector(arg)))));
  --  return result;
  --end function to_01;
-------------------------------------------------------------------------------------

  -- Returns the class which X falls into
  function Class (
    x           : float;                -- floating point input
    check_error : BOOLEAN := float_check_error)   -- check for errors
    return valid_fpstate is
    constant fraction_width : INTEGER := -x'low;  -- length of FP output fraction
    constant exponent_width : INTEGER := x'high;  -- length of FP output exponent
    variable arg            : float (exponent_width downto -fraction_width);
  begin  -- class
    if (arg'length < 1 or fraction_width < 3 or exponent_width < 3
        or x'left < x'right) then
      -- pragma translate_off
      report "FLOAT_GENERIC_PKG.CLASS: " &
        "Floating point number detected with a bad range"
        severity error;
      -- pragma translate_on
      return isx;
    end if;
    -- Check for "X".
    --arg := to_01 (x, 'X');
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
-------------------------------------------------------------------------------------
  -- purpose: Converts a float to sfixed
  function float_to_sfixed (
    arg                     : float;    -- fp input
    constant left_index     : INTEGER;  -- integer part
    constant right_index    : INTEGER;  -- fraction part
    constant check_error    : BOOLEAN := float_check_error;  -- check for errors
    constant denormalize    : BOOLEAN := float_denormalize)
    return sfixed is
    constant fraction_width : INTEGER                                := -arg'low;  -- length of FP output fraction
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

end package body float_pkg_mod;


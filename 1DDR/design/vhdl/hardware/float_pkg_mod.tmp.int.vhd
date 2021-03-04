-- This file is adapted from floating point package.
library IEEE;
use IEEE.MATH_REAL.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_MISC.all;
use IEEE.fixed_float_types.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
--use work.fixed_generic_pkg_mod.all;

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
function float_to_sfixed(fp : std_logic_vector; N : integer; F : integer) return sfixed;

end float_pkg_mod;

------------------------------------------------------------------------
------------------------------PACKAGE BODY------------------------------
------------------------------------------------------------------------
package body float_pkg_mod is
-------------------------------------------------------------------------------------
  --Convert a number in std 32-bit flt pt format to a signed binary integer with F bits.
--NOTE that F must be large enough for the entire truncated result as a signed integer
--If the number is positive, the result can be typecast into unsigned if desired.
  function float_to_sfixed(fp : std_logic_vector; N : integer; F : integer) return sfixed is
    variable num    : unsigned(65 downto 0);
    variable result : signed(65 downto 0);   --returned number
    variable exp    : integer range -8192 to 8191;
    variable m      : unsigned(53 downto 0);
  begin
    m   := "01" & unsigned(fp(51 downto 0));  --restore the mantissa leading 1 
    exp := TO_INTEGER(unsigned(fp(62 downto 52))) - 1023;  --unbias the exponent
    if exp < 0 then                     --number less than 1 truncated to 0
      num := (others => '0');
    elsif exp >= 64 then
      num := (others => '1');           --num greater than 2**F saturates
    else
      num(exp+1 downto 0)   := m(53 downto 52-exp);  --effectively multiply m by 2**exp,
      num(65 downto exp+2) := (others => '0');  --  and pad with leading 0's.
    end if;
    if fp(63) = '1' then
      result := -signed(num);
    else
      result := signed(num);
    end if;
    return to_sfixed(result(63 downto 0), N, F);
  end function float_to_sfixed;
-------------------------------------------------------------------------------------

end package body float_pkg_mod;


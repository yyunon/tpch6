--------------------------------------------------------------------------------
--                     LeftShifter53_by_max_67_F400_uid4
-- VHDL generated for VirtexUltrascalePlus @ 400MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca (2008-2011), Florent de Dinechin (2008-2019)
--------------------------------------------------------------------------------
-- Pipeline depth: 2 cycles
-- Clock period (ns): 2.5
-- Target frequency (MHz): 400
-- Input signals: X S
-- Output signals: R

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity LeftShifter53_by_max_67_F400_uid4 is
    port (clk : in std_logic;
          X : in  std_logic_vector(52 downto 0);
          S : in  std_logic_vector(6 downto 0);
          R : out  std_logic_vector(119 downto 0)   );
end entity;

architecture arch of LeftShifter53_by_max_67_F400_uid4 is
signal ps, ps_d1, ps_d2 :  std_logic_vector(6 downto 0);
signal level0 :  std_logic_vector(52 downto 0);
signal level1 :  std_logic_vector(53 downto 0);
signal level2 :  std_logic_vector(55 downto 0);
signal level3, level3_d1 :  std_logic_vector(59 downto 0);
signal level4 :  std_logic_vector(67 downto 0);
signal level5, level5_d1 :  std_logic_vector(83 downto 0);
signal level6 :  std_logic_vector(115 downto 0);
signal level7 :  std_logic_vector(179 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            ps_d1 <=  ps;
            ps_d2 <=  ps_d1;
            level3_d1 <=  level3;
            level5_d1 <=  level5;
         end if;
      end process;
   ps<= S;
   level0<= X;
   level1<= level0 & (0 downto 0 => '0') when ps(0)= '1' else     (0 downto 0 => '0') & level0;
   R <= level7(119 downto 0);
   level2<= level1 & (1 downto 0 => '0') when ps(1)= '1' else     (1 downto 0 => '0') & level1;
   R <= level7(119 downto 0);
   level3<= level2 & (3 downto 0 => '0') when ps(2)= '1' else     (3 downto 0 => '0') & level2;
   R <= level7(119 downto 0);
   level4<= level3_d1 & (7 downto 0 => '0') when ps_d1(3)= '1' else     (7 downto 0 => '0') & level3_d1;
   R <= level7(119 downto 0);
   level5<= level4 & (15 downto 0 => '0') when ps_d1(4)= '1' else     (15 downto 0 => '0') & level4;
   R <= level7(119 downto 0);
   level6<= level5_d1 & (31 downto 0 => '0') when ps_d2(5)= '1' else     (31 downto 0 => '0') & level5_d1;
   R <= level7(119 downto 0);
   level7<= level6 & (63 downto 0 => '0') when ps_d2(6)= '1' else     (63 downto 0 => '0') & level6;
   R <= level7(119 downto 0);
end architecture;

--------------------------------------------------------------------------------
--                     FP2Fix_11_52M_18_46_S_T_F400_uid2
-- VHDL generated for VirtexUltrascalePlus @ 400MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Fabrizio Ferrandi (2012)
--------------------------------------------------------------------------------
-- Pipeline depth: 2 cycles
-- Clock period (ns): 2.5
-- Target frequency (MHz): 400
-- Input signals: I
-- Output signals: O

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity FP2Fix_11_52M_18_46_S_T_F400_uid2 is
    port (clk : in std_logic;
          I : in  std_logic_vector(11+52+2 downto 0);
          O : out  std_logic_vector(64 downto 0)   );
end entity;

architecture arch of FP2Fix_11_52M_18_46_S_T_F400_uid2 is
   component LeftShifter53_by_max_67_F400_uid4 is
      port ( clk : in std_logic;
             X : in  std_logic_vector(52 downto 0);
             S : in  std_logic_vector(6 downto 0);
             R : out  std_logic_vector(119 downto 0)   );
   end component;

signal eA0 :  std_logic_vector(10 downto 0);
signal fA0 :  std_logic_vector(52 downto 0);
signal eA1 :  std_logic_vector(10 downto 0);
signal shiftedby :  std_logic_vector(6 downto 0);
signal fA1 :  std_logic_vector(119 downto 0);
signal fA2 :  std_logic_vector(64 downto 0);
signal fA4 :  std_logic_vector(64 downto 0);
signal overFl0, overFl0_d1, overFl0_d2 :  std_logic;
signal notZeroTest :  std_logic;
signal overFl1 :  std_logic;
signal eTest :  std_logic;
signal I_d1, I_d2 :  std_logic_vector(11+52+2 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            overFl0_d1 <=  overFl0;
            overFl0_d2 <=  overFl0_d1;
            I_d1 <=  I;
            I_d2 <=  I_d1;
         end if;
      end process;
   eA0 <= I(62 downto 52);
   fA0 <= "1" & I(51 downto 0);
   eA1 <= eA0 - conv_std_logic_vector(1022, 11);
   shiftedby <= eA1(6 downto 0) when eA1(10) = '0' else (6 downto 0 => '0');
   FXP_shifter: LeftShifter53_by_max_67_F400_uid4
      port map ( clk  => clk,
                 S => shiftedby,
                 X => fA0,
                 R => fA1);
   fA2<= fA1(99 downto 35);
   fA4<= fA2 when I_d2(63) = '0' else -signed(fA2);
   overFl0<= '1' when I(62 downto 52) > conv_std_logic_vector(1069,11) else I(65);
   notZeroTest <= '1' when fA4 /= conv_std_logic_vector(0,65) else '0';
   overFl1 <= (fA4(64) xor I_d2(63)) and notZeroTest;
   eTest <= (overFl0_d2 or overFl1);
   O <= fA4 when eTest = '0' else
      I_d2(63) & (63 downto 0 => not I_d2(63));
end architecture;


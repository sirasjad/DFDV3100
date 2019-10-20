library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.numeric_std.ALL;

entity generic_register is
  port (
    data_input: in std_logic_vector(7 downto 0);
    set, clock, increment, decrement, reset: in std_logic;
    output: out std_logic_vector(7 downto 0)
  );
end generic_register;

architecture sync of generic_register is
  signal value: unsigned(7 downto 0);
begin
  process(set, clock, reset)
  begin
    if reset = '1' then
      value <= x"00";
    elsif rising_edge(clock) then
      if set = '1' then
        value <= unsigned(data_input);
      elsif increment = '1' then
        value <= value + 1;
      elsif decrement = '1' then
        value <= value - 1;
      end if;
    end if;
  end process;

  output <= std_logic_vector(value);
end sync;

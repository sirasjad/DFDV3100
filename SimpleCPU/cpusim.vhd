library IEEE;
use IEEE.STD_LOGIC_1164.all;

library toplevel;

entity cpusim is
--  Port ( );
end cpusim;

architecture Behavioral of cpusim is
  signal clock, reset: std_logic;

  constant clockPeriod: time := 10ns;
begin
  cpu: entity toplevel.cpu(cpu) port map (
    clock => clock,
    reset => reset
  );

  clockProcess: process
  begin
    clock <= '0';
    wait for clockPeriod / 2;
    clock <= '1';
    wait for clockPeriod / 2;
  end process;

  process
  begin
    reset <= '1';
    wait for clockPeriod;
    reset <= '0';

    wait;
  end process;
end Behavioral;

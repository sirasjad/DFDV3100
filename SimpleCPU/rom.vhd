library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rom is
  port (
    address: in std_logic_vector(7 downto 0);
    output: out std_logic_vector(7 downto 0)
  );
end rom;

-- The ROM used while simulating the cpu
architecture test of rom is

begin
  with address select output <=
    x"00" when x"00", -- ldr 1
    x"01" when x"01",
    x"01" when x"02", -- decr
    x"02" when x"03", -- jnrz $F0
    x"F0" when x"04",
    x"00" when x"05", -- ldr 1
    x"01" when x"06",
    x"07" when x"07", -- PUP
    x"03" when x"08", -- MF $1F
    x"FF" when x"09",
    x"08" when x"0a", -- PDOWN
    x"02" when x"0b", -- jnrz $F1
    x"F1" when x"0c",
    x"FF" when x"F0", -- halt
    x"FF" when x"F1", -- halt
    "00000000" when others;
end test;

-- A ROM to use when running the actual circuit
-- This one was generated using a custom assembler, with the source code being put in the comments
architecture generated of rom is
begin
  with address select output <=
    x"08" when x"00",-- pdown
    x"00" when x"01",-- ldr $a
    x"0a" when x"02",
    x"05" when x"03",-- ml $ff
    x"ff" when x"04",
    x"05" when x"05",-- ml $ff
    x"ff" when x"06",
    x"03" when x"07",-- mf $ff
    x"ff" when x"08",
    x"07" when x"09",-- pup
    x"04" when x"0a",-- mb $ff
    x"ff" when x"0b",
    x"08" when x"0c",-- pdown
    x"01" when x"0d",-- decr
    x"02" when x"0e",-- jnrz spokeloop
    x"03" when x"0f",
    x"07" when x"10",-- pup
    x"04" when x"11",-- mb $ff
    x"ff" when x"12",
    x"04" when x"13",-- mb $ff
    x"ff" when x"14",
    x"06" when x"15",-- mr $ff
    x"ff" when x"16",
    x"06" when x"17",-- mr $ff
    x"ff" when x"18",
    x"06" when x"19",-- mr $ff
    x"ff" when x"1a",
    x"06" when x"1b",-- mr $ff
    x"ff" when x"1c",
    x"ff" when x"1d",-- halt

    x"ff" when others;
end generated;
